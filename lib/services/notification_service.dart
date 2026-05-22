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
