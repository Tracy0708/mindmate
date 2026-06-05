const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getAuth } = require('firebase-admin/auth');
const { GoogleGenerativeAI } = require('@google/generative-ai');

initializeApp();

const MINDMATE_SYSTEM_PROMPT = `You are MindMate AI, a compassionate mental health companion embedded in a wellbeing app used in Malaysia.
Guidelines:
- Listen with empathy and validate the user's feelings without judgment
- Offer practical, evidence-based coping strategies (breathing exercises, grounding techniques, journaling prompts)
- Keep replies concise: 2–3 sentences for most responses, more detail only when clearly needed
- Gently suggest professional help when the user expresses persistent or severe distress
- Never diagnose, prescribe medication, or claim to replace a licensed therapist or counselor
- Respond in a warm, supportive, conversational tone
- You may be given the user's recent mood trend. Reference it naturally and gently (e.g. acknowledge a rough week or celebrate an improvement); never recite the raw numbers back or sound clinical

CRISIS RESPONSE — if the user expresses thoughts of suicide, self-harm, or being in immediate danger:
- Respond with calm empathy and take it seriously
- Share ONLY these Malaysian crisis resources (never US, UK, or other countries' hotlines):
  • Befrienders KL: 03-7627 2929 (24/7 emotional support)
  • Talian Kasih (Ministry of Women): 15999
  • Mental Health Psychosocial Support (Ministry of Health): 1800-82-0066
  • For immediate emergencies, call 999
- Encourage them to reach out to one of these right away and remind them they are not alone
- Make clear you are an AI and cannot replace professional help`;

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

// ─── Mood-trend helpers (mirror lib/models/emotion_log.dart + insights_viewmodel.dart) ───

// Emotions that map intensity directly to wellbeing (vs. inverting it)
const POSITIVE_WELLBEING_EMOTIONS = new Set(['happy', 'calm']);
// Strict negative set used by EmotionLog.isNegative
const STRICT_NEGATIVE_EMOTIONS = new Set(['sad', 'anxious', 'angry']);

function noteSentiment(data) {
  const raw = data?.noteSentimentScore;
  if (raw === null || raw === undefined) return null;
  const num = Number(raw);
  return Number.isNaN(num) ? null : num;
}

function wellbeingScore(data) {
  const type = String(data?.emotionType ?? '').trim().toLowerCase();
  const intensity = Number(data?.intensityScore ?? 3);
  return POSITIVE_WELLBEING_EMOTIONS.has(type) ? intensity : 6 - intensity;
}

function resolvedScore(data) {
  const note = noteSentiment(data);
  const wb = wellbeingScore(data);
  return note !== null ? wb * 0.4 + note * 0.6 : wb;
}

function isEffectivelyNegativeLog(data) {
  const type = String(data?.emotionType ?? '').trim().toLowerCase();
  const note = noteSentiment(data);
  return STRICT_NEGATIVE_EMOTIONS.has(type) || (note !== null && resolvedScore(data) < 3.0);
}

// Build a compact, human-readable mood summary from recent logs (most-recent-first).
// Returns null when there is not enough data to say anything useful.
function buildMoodContext(logs) {
  if (!Array.isArray(logs) || logs.length === 0) return null;

  const withDates = logs
    .map((data) => ({ data, date: parseLogDate(data) }))
    .filter((entry) => entry.date !== null);
  if (withDates.length === 0) return null;

  // Most-recent-first
  withDates.sort((a, b) => b.date.getTime() - a.date.getTime());

  const now = new Date();
  const todayKey = dateKey(now);
  const lines = [];

  // Today's mood
  const todays = withDates.find((entry) => dateKey(entry.date) === todayKey);
  if (todays) {
    lines.push(`- Today they logged feeling "${todays.data.emotionType}" (intensity ${todays.data.intensityScore}/5).`);
  } else {
    lines.push("- They have not logged a mood yet today.");
  }

  // Dominant emotion over the window
  const freq = {};
  for (const { data } of withDates) {
    const type = String(data?.emotionType ?? 'Unknown');
    freq[type] = (freq[type] || 0) + 1;
  }
  const dominant = Object.entries(freq).sort((a, b) => b[1] - a[1])[0];
  if (dominant) {
    lines.push(`- Their most frequent mood over the last 2 weeks is "${dominant[0]}".`);
  }

  // Trend direction: first-half vs second-half average resolvedScore (chronological)
  if (withDates.length >= 4) {
    const chrono = [...withDates].reverse();
    const mid = Math.floor(chrono.length / 2);
    const avg = (arr) => arr.reduce((sum, e) => sum + resolvedScore(e.data), 0) / arr.length;
    const firstAvg = avg(chrono.slice(0, mid));
    const secondAvg = avg(chrono.slice(mid));
    const diff = secondAvg - firstAvg;
    if (diff > 0.3) {
      lines.push("- Their mood trend is improving compared to earlier this period.");
    } else if (diff < -0.3) {
      lines.push("- Their mood trend is declining compared to earlier this period.");
    } else {
      lines.push("- Their mood has been relatively stable this period.");
    }
  }

  // Negative-trend flag: 3+ of the last 5 effectively negative
  const lastFive = withDates.slice(0, 5);
  if (lastFive.length >= 3) {
    const negCount = lastFive.filter((e) => isEffectivelyNegativeLog(e.data)).length;
    if (negCount >= 3) {
      lines.push("- Several of their recent check-ins have been difficult — be especially gentle and supportive.");
    }
  }

  // Logging streak (consecutive days up to today)
  const keys = new Set(withDates.map((e) => dateKey(e.date)));
  let streak = 0;
  let cursor = new Date(now);
  while (keys.has(dateKey(cursor))) {
    streak += 1;
    cursor = previousDate(cursor, 1);
  }
  if (streak >= 2) {
    lines.push(`- They are on a ${streak}-day check-in streak.`);
  }

  return lines.join('\n');
}

// ─── Crisis detection (keyword-based, consistent with app's keyword sentiment) ───
const CRISIS_PATTERNS = [
  /\bkill(ing)? myself\b/,
  /\bsuicid/,
  /\bend (my|it all|my life)\b/,
  /\b(want|wanna|going) to die\b/,
  /\bself[-\s]?harm/,
  /\b(hurt|harm|cut|cutting|kill) myself\b/,
  /\bno (reason|point) (to|in) (live|living|life)\b/,
  /\bdon'?t want to (live|be here|be alive)\b/,
  /\bbetter off (without me|dead)\b/,
  /\boverdose\b/,
  /\btake my (own )?life\b/,
  /\bcan'?t (go on|do this anymore)\b/,
];

function detectCrisis(message) {
  const text = String(message || '').toLowerCase();
  return CRISIS_PATTERNS.some((re) => re.test(text));
}

// Write a privacy-preserving crisis flag — NO message text or conversation content is stored.
// Deduped to one open flag per user per day so the admin queue stays clean.
async function recordCrisisFlag(uid) {
  try {
    const db = getFirestore();
    const flagRef = db.collection('crisis_flags').doc(`${uid}_${dateKey(new Date())}`);
    await flagRef.set(
      {
        userId: uid,
        severity: 'high',
        acknowledged: false,
        lastFlaggedAt: FieldValue.serverTimestamp(),
        count: FieldValue.increment(1),
      },
      { merge: true },
    );

    await createNotificationForEnabledAdmins({
      type: 'crisis_flag',
      prefKey: 'highRiskAlerts',
      defaultEnabled: true,
      title: '🚨 Crisis language detected',
      message: 'A user may be in crisis. Review the Crisis follow-up queue and reach out.',
      sourceUserID: uid,
      dedupeKey: dateKey(new Date()),
    });
  } catch (error) {
    // A flag failure must never break the user's chat response.
    console.error('Failed to record crisis flag:', error.message);
  }
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

// Callable function to get an AI response from Gemini for the chatbot
exports.getChatbotResponse = onCall(async (request) => {
  if (!request.auth) {
    throw new Error('Authentication required');
  }

  const { sessionId, message } = request.data;
  if (!sessionId || !message || typeof message !== 'string') {
    throw new Error('sessionId and message are required');
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'your_gemini_api_key_here') {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  const db = getFirestore();
  const sessionDoc = await db.collection('chatbot_sessions').doc(sessionId).get();
  if (!sessionDoc.exists) {
    throw new Error('Session not found');
  }

  const allMessages = sessionDoc.data()?.messages || [];
  // Exclude the current user message (last item — already saved before this call)
  // and keep at most 20 prior messages for context
  const historyMessages = allMessages.slice(0, -1).slice(-20);

  const history = historyMessages.map((msg) => ({
    role: msg.isUser ? 'user' : 'model',
    parts: [{ text: msg.content }],
  }));

  // Build a per-request system instruction enriched with the user's recent mood trend.
  // Derived from the authenticated user's own emotion logs; never persisted into the chat.
  let systemInstruction = MINDMATE_SYSTEM_PROMPT;
  try {
    const since = previousDate(new Date(), 14);
    const logsSnapshot = await db
      .collection('users')
      .doc(request.auth.uid)
      .collection('emotion_logs')
      .where('timestamp', '>=', since)
      .orderBy('timestamp', 'desc')
      .get();

    const moodContext = buildMoodContext(logsSnapshot.docs.map((d) => d.data()));
    if (moodContext) {
      systemInstruction = `${MINDMATE_SYSTEM_PROMPT}\n\nUSER MOOD CONTEXT (do not read this back verbatim; use it to tailor your empathy and suggestions):\n${moodContext}`;
    }
  } catch (error) {
    // Mood context is best-effort — fall back to the base prompt on any failure.
    console.error('Failed to build mood context:', error.message);
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction,
  });

  // Call Gemini with one automatic retry on transient overloads (503), degrading
  // gracefully so the user sees a calm in-chat message instead of an error screen.
  // Quota errors (429) are NOT retried — they won't recover and retrying would
  // waste the limited free-tier daily allowance.
  let responseText;
  let lastError = null;
  const maxAttempts = 2; // initial attempt + 1 retry for transient overloads
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const chat = model.startChat({ history });
      const result = await chat.sendMessage(message);
      responseText = result.response.text();
      lastError = null;
      break;
    } catch (err) {
      lastError = err;
      const detail = String(err?.message || err);
      const transient = /\b503\b|overloaded|unavailable/i.test(detail);
      if (transient && attempt < maxAttempts) {
        console.warn(`Gemini transient error (attempt ${attempt}); retrying:`, detail);
        await new Promise((resolve) => setTimeout(resolve, 1500));
        continue;
      }
      break;
    }
  }

  if (lastError) {
    const detail = String(lastError?.message || lastError);
    console.error('Gemini call failed:', detail);
    if (/\b429\b|quota|RESOURCE_EXHAUSTED|rate limit/i.test(detail)) {
      responseText =
        "I'm getting a lot of messages right now and need a short breather. " +
        "Please try again in a minute. 💛 If you need urgent support, the hotlines " +
        "in Help & Support are available any time.";
    } else if (/\b503\b|overloaded|unavailable/i.test(detail)) {
      responseText =
        "I'm having a brief connection hiccup on my end. Please try sending that again in a moment.";
    } else {
      responseText =
        "Sorry, I couldn't respond just now. Please try again shortly — I'm still here for you.";
    }
  }

  // Detect crisis language in the user's message and flag it for admin follow-up.
  // The flag stores no message content (see recordCrisisFlag) to preserve privacy.
  const crisisDetected = detectCrisis(message);
  if (crisisDetected) {
    await recordCrisisFlag(request.auth.uid);
  }

  return { response: responseText, crisisDetected };
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
