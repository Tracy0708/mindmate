import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_notification_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'dart:developer' as developer;

class AdminRealtimeNotificationService {
  static final AdminRealtimeNotificationService _instance = AdminRealtimeNotificationService._internal();
  factory AdminRealtimeNotificationService() => _instance;
  AdminRealtimeNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  StreamSubscription<QuerySnapshot>? _emotionsSub;

  bool _isFirstEmotionsSnapshot = true;

  // Track recent logs for Abnormal Behavior detection (User ID -> List of Timestamps)
  final Map<String, List<DateTime>> _recentUserLogs = {};

  bool _isRunning = false;

  Future<void> startListening() async {
    if (_isRunning) return;

    final profile = await _authService.getUserProfile();
    if (profile == null || profile.role != 'admin') return;

    final prefs =
        profile.settings['adminNotificationPrefs'] as Map<String, dynamic>? ??
            {};
    final bool abnormalEnabled = prefs['abnormalBehavior'] ?? true;
    final bool systemReports = prefs['systemReports'] ?? true;

    if (!abnormalEnabled && !systemReports) return;

    _isRunning = true;
    _isFirstEmotionsSnapshot = true;

    developer.log(
      'Starting Admin Real-time Notification Listeners...',
      name: 'AdminNotifications',
    );

    // Catch up on events that happened while admin was offline
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid != null) {
      if (systemReports) await _checkSystemReportNotification(adminUid);
    }

    // Listen for Emotions (Abnormal Behavior)
    if (abnormalEnabled) {
      _emotionsSub = _firestore
          .collectionGroup('emotion_logs')
          .snapshots()
          .listen((snapshot) async {
        if (_isFirstEmotionsSnapshot) {
          _isFirstEmotionsSnapshot = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            // Get userId from data field or from subcollection path (users/{uid}/emotion_logs)
            final userId =
                (data['userID'] ?? data['userId'] ?? data['uid'])?.toString() ??
                    change.doc.reference.parent.parent?.id;
            if (userId == null || userId.isEmpty) continue;

            _checkAbnormalBehavior(userId);
          }
        }
      });
    }
  }

  void stopListening() {
    _emotionsSub?.cancel();
    _isRunning = false;
    developer.log(
      'Stopped Admin Real-time Notification Listeners.',
      name: 'AdminNotifications',
    );
  }

  // ─── Daily System Report (fires once per login day) ───
  Future<void> _checkSystemReportNotification(String adminUid) async {
    try {
      final adminDoc = await _firestore.collection('users').doc(adminUid).get();
      final lastReportRaw = adminDoc.data()?['lastSystemReportAt'];
      final todayStr = _dateKey(DateTime.now());

      if (lastReportRaw is Timestamp && _dateKey(lastReportRaw.toDate()) == todayStr) {
        return; // Already sent a report today
      }

      final usersSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      final totalUsers = usersSnap.docs.length;

      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final newUsersToday = usersSnap.docs.where((d) {
        final raw = d.data()['createdAt'];
        return raw is Timestamp && raw.toDate().isAfter(todayStart);
      }).length;

      await NotificationService().createNotification(
        userID: adminUid,
        title: '📊 Daily System Report',
        message: 'Total users: $totalUsers. New sign-ups today: $newUsersToday.',
        type: 'system_report',
        pushEnabled: true,
      );

      await _firestore.collection('users').doc(adminUid).update({
        'lastSystemReportAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('System report notification failed: $e', name: 'AdminNotifications');
    }
  }

  // ─── Abnormal Behavior Detection ───
  void _checkAbnormalBehavior(String userId) {
    final now = DateTime.now();
    _recentUserLogs.putIfAbsent(userId, () => []);
    
    // Add current log
    _recentUserLogs[userId]!.add(now);

    // Remove logs older than 1 minute
    _recentUserLogs[userId]!.removeWhere((time) => now.difference(time).inSeconds > 60);

    // If more than 3 logs in the last 60 seconds (Wait, user said they can only log once!
    // So if it's > 1 in a short timeframe, it's abnormal! Let's say >= 2 logs in 1 minute is abnormal).
    if (_recentUserLogs[userId]!.length >= 2) {
      // Prevent spamming the same alert
      _recentUserLogs[userId]!.clear(); 
      
      _getUserName(userId).then((name) {
        LocalNotificationService().showAdminRealtimeAlert(
          id: LocalNotificationService.adminAbnormalBehaviorId,
          title: '⚠️ Abnormal Behavior Detected',
          body: '$name has bypassed limits and logged multiple times rapidly.',
        );
        final adminUid = FirebaseAuth.instance.currentUser?.uid;
        if (adminUid != null) {
          NotificationService().createNotification(
            userID: adminUid,
            title: '⚠️ Abnormal Behavior Detected',
            message: '$name has bypassed limits and logged multiple times rapidly.',
            type: 'abnormal',
            pushEnabled: true,
          );
        }
      });
    }
  }

  // ─── Helpers ───

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['userName'] ?? doc.data()!['name'] ?? 'User';
      }
    } catch (_) {}
    return 'User';
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

}
