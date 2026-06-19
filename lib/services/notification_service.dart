import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Create a new notification
  Future<NotificationModel> createNotification({
    required String userID,
    required String title,
    required String message,
    required String type,
    String? status,
    bool pushEnabled = false,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    final notification = NotificationModel(
      notificationID: docRef.id,
      userID: userID,
      title: title,
      notificationMessage: message,
      notificationType: type,
      notificationStatus: status,
    );

    await docRef.set({...notification.toJson(), 'pushEnabled': pushEnabled});
    return notification;
  }

  Future<void> syncPreferenceReminderNotifications({
    required String userID,
    required Map<String, bool> prefs,
    required String reminderTime,
  }) async {
    final reminderDefinitions = {
      'dailyMoodReminder': (
        type: 'daily_mood_reminder',
        title: '😊 How are you feeling?',
        message: 'Take a moment to log your mood today.',
      ),
      'breathingReminder': (
        type: 'breathing_reminder',
        title: '🌿 Time to breathe',
        message: 'A short breathing exercise can help reduce stress.',
      ),
      'weeklySummary': (
        type: 'weekly_summary',
        title: '📊 Your Weekly Summary',
        message: 'Check out your mood trends from this week.',
      ),
      'motivationalQuotes': (
        type: 'motivational_quote',
        title: '💛 Daily Inspiration',
        message: 'A small reminder to be kind to yourself today.',
      ),
    };

    final batch = _firestore.batch();

    for (final entry in reminderDefinitions.entries) {
      final def = entry.value;
      final docRef =
          _firestore.collection(_collection).doc('${def.type}_$userID');

      if (prefs[entry.key] == true) {
        final existing = await docRef.get();
        final existingStatus = existing.data()?['notificationStatus'];

        final data = <String, dynamic>{
          'notificationID': docRef.id,
          'userID': userID,
          'title': def.title,
          'notificationMessage': def.message,
          'notificationStatus': existingStatus ?? 'unread',
          'notificationType': def.type,
          'reminderTime': reminderTime,
          'pushEnabled': false,
        };
        // Only set the timestamp when creating the record for the first time.
        // Overwriting it on every settings load would make all notifications
        // appear as "just now" in the notification center whenever the screen opens.
        if (!existing.exists) {
          data['notificationTimestamp'] = DateTime.now().toIso8601String();
        }

        batch.set(
          docRef,
          data,
          SetOptions(merge: true),
        );
      } else {
        batch.delete(docRef);
      }
    }

    await batch.commit();
  }

  // Delete the four stable-ID placeholder documents that older app versions
  // wrote into the notifications collection for preference reminders.
  Future<void> deletePreferenceReminderPlaceholders(String userID) async {
    const types = [
      'daily_mood_reminder',
      'breathing_reminder',
      'weekly_summary',
      'motivational_quote',
    ];
    final batch = _firestore.batch();
    for (final type in types) {
      batch.delete(_firestore.collection(_collection).doc('${type}_$userID'));
    }
    await batch.commit();
  }

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userID) {
    return _firestore
        .collection(_collection)
        .where('userID', isEqualTo: userID)
        .orderBy('notificationTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
      list.sort(
          (a, b) => b.notificationTimestamp.compareTo(a.notificationTimestamp));
      return list;
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationID) async {
    await _firestore.collection(_collection).doc(notificationID).update({
      'notificationStatus': 'read',
    });
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationID) async {
    await _firestore.collection(_collection).doc(notificationID).delete();
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userID) {
    return _firestore
        .collection(_collection)
        .where('userID', isEqualTo: userID)
        .where('notificationStatus', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userID) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userID', isEqualTo: userID)
        .where('notificationStatus', isEqualTo: 'unread')
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'notificationStatus': 'read'});
    }
    await batch.commit();
  }

  // Create a scheduled notification
  Future<NotificationModel> scheduleNotification({
    required String userID,
    required String title,
    required String message,
    required String type,
    required DateTime scheduledTime,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    final notification = NotificationModel(
      notificationID: docRef.id,
      userID: userID,
      title: title,
      notificationMessage: message,
      notificationType: type,
      notificationStatus: 'scheduled',
    );

    await docRef.set({
      ...notification.toJson(),
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    return notification;
  }

  // Get scheduled notifications
  Stream<List<NotificationModel>> getScheduledNotifications() {
    return _firestore
        .collection(_collection)
        .where('notificationStatus', isEqualTo: 'scheduled')
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    });
  }
}
