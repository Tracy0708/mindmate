const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getAuth } = require('firebase-admin/auth');

initializeApp();

const NEGATIVE_EMOTIONS = new Set([
  'sad',
  'down',
  'depressed',
  'anxious',
  'anxiety',
  'stressed',
  'stress',
  'angry',
  'lonely',
  'hopeless',
  'overwhelmed',
  'tired',
  'fearful',
  'worried',
]);

const MALAYSIA_TIME_ZONE = 'Asia/Kuala_Lumpur';

function emotionValue(data) {
  return String(data?.emotionType ?? data?.emotion ?? data?.mood ?? '')
    .trim()
    .toLowerCase();
}

function isNegativeEmotion(data) {
  return NEGATIVE_EMOTIONS.has(emotionValue(data));
}

function parseLogDate(data) {
  const raw = data?.emotionLogTimestamp ?? data?.timestamp ?? data?.createdAt ?? data?.date;
  if (!raw) return null;
  if (typeof raw.toDate === 'function') return raw.toDate();
  if (raw instanceof Date) return raw;
  if (typeof raw === 'string') {
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof raw === 'number') {
    return new Date(raw > 9999999999 ? raw : raw * 1000);
  }
  return null;
}

function dateKey(date) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: MALAYSIA_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);

  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function previousDate(date, days) {
  return new Date(date.getTime() - days * 24 * 60 * 60 * 1000);
}

async function createNotificationForEnabledAdmins({
  type,
  prefKey,
  defaultEnabled = false,
  title,
  message,
  sourceUserID,
  dedupeKey,
}) {
  const db = getFirestore();
  const adminSnapshot = await db
    .collection('users')
    .where('role', '==', 'admin')
    .where('isDisabled', '==', false)
    .get();

  if (adminSnapshot.empty) return 0;

  const batch = db.batch();
  let writeCount = 0;

  adminSnapshot.docs.forEach((adminDoc) => {
    const prefs = adminDoc.data()?.settings?.adminNotificationPrefs || {};
    if ((prefs[prefKey] ?? defaultEnabled) !== true) return;

    const notificationRef = dedupeKey
      ? db.collection('notifications').doc(`${type}_${adminDoc.id}_${dedupeKey}`)
      : db.collection('notifications').doc();

    batch.set(
      notificationRef,
      {
        notificationID: notificationRef.id,
        userID: adminDoc.id,
        title,
        notificationMessage: message,
        notificationStatus: 'unread',
        notificationType: type,
        notificationTimestamp: new Date().toISOString(),
        sourceUserID,
        pushEnabled: true,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    writeCount += 1;
  });

  if (writeCount === 0) return 0;

  await batch.commit();
  return writeCount;
}

// Triggered whenever a new user profile document is created.
// Creates an unread admin notification immediately, so sign-up alerts are not
// delayed until an admin opens the dashboard.
exports.createAdminNotificationOnSignup = onDocumentCreated(
  'users/{userId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.role === 'admin') return null;

    const name = data.userName || data.name || 'A new user';
    await createNotificationForEnabledAdmins({
      type: 'new_signup',
      prefKey: 'newSignups',
      title: 'New Signup!',
      message: `${name} has joined MindMate.`,
      sourceUserID: event.params.userId,
    });

    return null;
  }
);

// Triggered whenever a user logs a new mood.
// Creates high-risk admin notifications as soon as the risk pattern appears.
exports.createHighRiskNotificationOnEmotionLog = onDocumentCreated(
  'users/{userId}/emotion_logs/{logId}',
  async (event) => {
    const logData = event.data?.data();
    const userId = event.params.userId;

    if (!logData || !isNegativeEmotion(logData)) return null;

    const triggerDate = parseLogDate(logData) ?? new Date();
    const triggerDateKey = dateKey(triggerDate);
    const requiredDates = new Set([
      triggerDateKey,
      dateKey(previousDate(triggerDate, 1)),
      dateKey(previousDate(triggerDate, 2)),
    ]);

    const db = getFirestore();
    const logsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('emotion_logs')
      .get();

    const negativeDates = new Set();
    logsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (!isNegativeEmotion(data)) return;

      const logDate = parseLogDate(data);
      if (!logDate) return;

      negativeDates.add(dateKey(logDate));
    });

    const hasThreeConsecutiveDays = [...requiredDates].every((key) =>
      negativeDates.has(key)
    );

    if (!hasThreeConsecutiveDays) return null;

    const userDoc = await db.collection('users').doc(userId).get();
    const name = userDoc.data()?.userName || userDoc.data()?.name || 'User';

    await createNotificationForEnabledAdmins({
      type: 'high_risk',
      prefKey: 'highRiskAlerts',
      defaultEnabled: true,
      title: 'High Risk Alert',
      message: `${name} has logged negative emotions for 3 consecutive days.`,
      sourceUserID: userId,
      dedupeKey: `${userId}_${triggerDateKey}`,
    });

    return null;
  }
);

// Triggered whenever a new document is created in the `notifications` collection.
// Sends an FCM push to the target user's device if pushEnabled === true.
exports.sendPushOnNotification = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.pushEnabled !== true) return null;

    const userID = data.userID;
    if (!userID) return null;

    const userDoc = await getFirestore().collection('users').doc(userID).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log('No FCM token for user', userID);
      return null;
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: data.title,
          body: data.notificationMessage,
        },
        data: {
          type: data.notificationType ?? 'general',
          notificationId: event.params.notificationId,
        },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      console.log('FCM sent to user', userID);
    } catch (e) {
      console.error('FCM send failed for user', userID, ':', e);
    }
    return null;
  }
);

// Callable function to delete a user from both Firestore and Firebase Auth
exports.deleteUser = onCall(async (request) => {
  const uid = request.data?.uid;

  if (!uid || typeof uid !== 'string') {
    throw new Error('Invalid UID provided');
  }

  if (!request.auth) {
    throw new Error('Authentication required');
  }

  const db = getFirestore();
  const auth = getAuth();

  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('User not found in Firestore');
    }

    const userRole = userDoc.data()?.role;
    if (userRole === 'admin') {
      throw new Error('Cannot delete admin users');
    }

    await Promise.all([
      auth.deleteUser(uid),
      db.collection('users').doc(uid).delete(),
    ]);

    console.log(`User ${uid} deleted successfully from Auth and Firestore`);
    return { success: true, message: `User ${uid} deleted` };
  } catch (error) {
    console.error(`Failed to delete user ${uid}:`, error.message);
    throw new Error(`Failed to delete user: ${error.message}`);
  }
});

// Scheduled function to clean up orphaned Firestore documents
// Runs daily at 2 AM (UTC) to find and delete users that no longer exist in Firebase Auth
exports.cleanupOrphanedUsers = onSchedule('every day 02:00', async (context) => {
  const db = getFirestore();
  const auth = getAuth();

  try {
    const usersSnapshot = await db.collection('users').get();
    let deletedCount = 0;
    let errorCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;
      const userData = userDoc.data();

      // Skip if already marked as deleted
      if (userData.isDeleted === true) continue;

      try {
        // Try to get the user from Firebase Auth
        await auth.getUser(uid);
        // User exists in Auth, keep the Firestore document
      } catch (error) {
        // User doesn't exist in Auth, delete the Firestore document
        if (error.code === 'auth/user-not-found') {
          await db.collection('users').doc(uid).delete();
          deletedCount++;
          console.log(`Cleaned up orphaned user ${uid} (no longer in Firebase Auth)`);
        } else {
          // Some other error occurred
          errorCount++;
          console.error(`Error checking user ${uid}:`, error.message);
        }
      }
    }

    console.log(`Cleanup completed: deleted ${deletedCount} orphaned users, ${errorCount} errors`);
    return { success: true, deletedCount, errorCount };
  } catch (error) {
    console.error('Cleanup task failed:', error.message);
    throw error;
  }
});
