import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      await _saveToken();
      return;
    }

    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      await _saveToken();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen(_saveTokenValue);

      _foregroundMessageSub =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        if (n != null) {
          LocalNotificationService().showAdminRealtimeAlert(
            id: n.hashCode,
            title: n.title ?? '',
            body: n.body ?? '',
          );
        }
      });
      _isInitialized = true;
    } catch (e) {
      developer.log(
        'FCM initialization skipped: $e',
        name: 'FCMService',
        level: 900,
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundMessageSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub = null;
    _isInitialized = false;
  }

  Future<void> clearTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final currentToken = await _fcm.getToken();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final savedToken = userDoc.data()?['fcmToken'];

      if (currentToken == null || savedToken == currentToken) {
        await userRef.update({'fcmToken': FieldValue.delete()});
      }

      await dispose();
    } catch (e) {
      developer.log(
        'FCM token clear skipped: $e',
        name: 'FCMService',
        level: 900,
      );
    }
  }

  Future<void> _saveToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveTokenValue(token);
    } catch (e) {
      developer.log(
        'FCM token save skipped: $e',
        name: 'FCMService',
        level: 900,
      );
    }
  }

  Future<void> _saveTokenValue(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'FCM token write skipped: $e',
        name: 'FCMService',
        level: 900,
      );
    }
  }
}
