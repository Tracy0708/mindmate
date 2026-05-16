import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_notification_service.dart';
import 'auth_service.dart';
import 'dart:developer' as developer;

class AdminRealtimeNotificationService {
  static final AdminRealtimeNotificationService _instance = AdminRealtimeNotificationService._internal();
  factory AdminRealtimeNotificationService() => _instance;
  AdminRealtimeNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  StreamSubscription<QuerySnapshot>? _usersSub;
  StreamSubscription<QuerySnapshot>? _emotionsSub;

  bool _isFirstUsersSnapshot = true;
  bool _isFirstEmotionsSnapshot = true;

  // Track recent logs for Abnormal Behavior detection (User ID -> List of Timestamps)
  final Map<String, List<DateTime>> _recentUserLogs = {};

  // Track if we already alerted for high risk today to prevent spam
  final Set<String> _alertedUsersToday = {};

  bool _isRunning = false;

  Future<void> startListening() async {
    if (_isRunning) return;

    final profile = await _authService.getUserProfile();
    if (profile == null || profile.role != 'admin') return;

    final prefs = profile.settings['adminNotificationPrefs'] as Map<String, dynamic>? ?? {};
    final masterEnabled = profile.settings['notificationPrefs']?['masterToggle'] ?? true; // fallback
    
    // Check if master toggle is off in admin prefs? No, we used master toggle directly in savePreferences.
    // Wait, the UI saved them as 'newSignups', 'highRiskAlerts', etc.
    final bool newSignupsEnabled = prefs['newSignups'] ?? false;
    final bool highRiskEnabled = prefs['highRiskAlerts'] ?? true;
    final bool abnormalEnabled = prefs['abnormalBehavior'] ?? true;

    if (!newSignupsEnabled && !highRiskEnabled && !abnormalEnabled) return;

    _isRunning = true;
    _isFirstUsersSnapshot = true;
    _isFirstEmotionsSnapshot = true;
    _alertedUsersToday.clear();

    developer.log('Starting Admin Real-time Notification Listeners...', name: 'AdminNotifications');

    // 1. Listen for New Signups
    if (newSignupsEnabled) {
      _usersSub = _firestore.collection('users').snapshots().listen((snapshot) {
        if (_isFirstUsersSnapshot) {
          _isFirstUsersSnapshot = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;
            
            // Only alert for actual 'user' role, not other admins
            if (data['role'] == 'admin') continue;

            final name = data['userName'] ?? data['name'] ?? 'A new user';
            LocalNotificationService().showAdminRealtimeAlert(
              id: LocalNotificationService.adminNewSignupId,
              title: 'New Signup! 🎉',
              body: '$name has joined MindMate.',
            );
          }
        }
      });
    }

    // 2. Listen for Emotions (High Risk & Abnormal Behavior)
    if (highRiskEnabled || abnormalEnabled) {
      _emotionsSub = _firestore.collection('emotions').snapshots().listen((snapshot) async {
        if (_isFirstEmotionsSnapshot) {
          _isFirstEmotionsSnapshot = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            final userId = (data['userID'] ?? data['userId'] ?? data['uid'])?.toString();
            if (userId == null || userId.isEmpty) continue;

            final emotion = (data['emotionType'] ?? data['emotion'] ?? data['mood'] ?? '').toString().toLowerCase();

            // A. Abnormal Behavior Check
            if (abnormalEnabled) {
              _checkAbnormalBehavior(userId);
            }

            // B. High Risk Check (Consecutive Negative Moods)
            if (highRiskEnabled && _isNegativeEmotion(emotion)) {
              await _checkHighRisk(userId);
            }
          }
        }
      });
    }
  }

  void stopListening() {
    _usersSub?.cancel();
    _emotionsSub?.cancel();
    _isRunning = false;
    developer.log('Stopped Admin Real-time Notification Listeners.', name: 'AdminNotifications');
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
      });
    }
  }

  // ─── High Risk Detection (3 Consecutive Days of Negative Mood) ───
  Future<void> _checkHighRisk(String userId) async {
    final todayStr = _dateKey(DateTime.now());
    if (_alertedUsersToday.contains('$userId-$todayStr')) {
      return; // Already alerted for this user today
    }

    try {
      // Get all emotions for this user to check consecutive days
      final snapshot = await _firestore.collection('emotions').where('userID', isEqualTo: userId).get();
      
      final List<Map<String, dynamic>> logs = snapshot.docs.map((d) => d.data()).toList();
      
      // Parse timestamps
      final List<DateTime> negativeDates = [];
      for (var log in logs) {
        final emotion = (log['emotionType'] ?? log['emotion'] ?? log['mood'] ?? '').toString().toLowerCase();
        if (_isNegativeEmotion(emotion)) {
          final ts = _parseTimestamp(log);
          if (ts != null) {
            negativeDates.add(ts);
          }
        }
      }

      // Group by distinct days
      final Set<String> distinctNegativeDays = negativeDates.map((d) => _dateKey(d)).toSet();

      // Check if they have negative logs for Today, Yesterday, and the Day Before Yesterday
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final hasToday = distinctNegativeDays.contains(_dateKey(today));
      final hasYesterday = distinctNegativeDays.contains(_dateKey(yesterday));
      final hasDayBefore = distinctNegativeDays.contains(_dateKey(dayBefore));

      if (hasToday && hasYesterday && hasDayBefore) {
        _alertedUsersToday.add('$userId-$todayStr'); // Mark as alerted
        
        final name = await _getUserName(userId);
        LocalNotificationService().showAdminRealtimeAlert(
          id: LocalNotificationService.adminHighRiskId,
          title: '🚨 High Risk Alert',
          body: '$name has logged negative emotions for 3 consecutive days.',
        );
      }
    } catch (e) {
      developer.log('High Risk check failed: $e', name: 'AdminNotifications');
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

  DateTime? _parseTimestamp(Map<String, dynamic> data) {
    final raw = data['emotionLogTimestamp'] ?? data['timestamp'] ?? data['createdAt'] ?? data['date'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) {
      if (raw > 9999999999) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return null;
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isNegativeEmotion(String emotion) {
    const negative = {
      'sad', 'down', 'depressed', 'anxious', 'anxiety',
      'stressed', 'stress', 'angry', 'lonely', 'hopeless',
      'overwhelmed', 'tired', 'fearful', 'worried',
    };
    return negative.contains(emotion);
  }
}
