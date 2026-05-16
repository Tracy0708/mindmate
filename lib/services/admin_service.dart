import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();

      users.sort((a, b) {
        final aTime = a.lastLogin ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastLogin ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return users;
    });
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      developer.log('getUserById failed: $e', name: 'AdminService', level: 900);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserUsageStats(String userId) async {
    // Emotion logs live at users/{userId}/emotion_logs — NOT a root collection
    final emotionSnapshot = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('emotion_logs')
        .get();

    // Activities live at users/{userId}/activities
    final activitySnapshot = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('activities')
        .where('activityStatus', isEqualTo: 'completed')
        .get();

    // Derive lastActive from the most recent emotion log timestamp
    DateTime? lastActive;
    for (final doc in emotionSnapshot.docs) {
      final raw = doc.data()['timestamp'];
      DateTime? ts;
      if (raw is Timestamp) ts = raw.toDate();
      if (ts != null && (lastActive == null || ts.isAfter(lastActive))) {
        lastActive = ts;
      }
    }

    // Fallback to lastLogin from user doc if no logs exist
    if (lastActive == null) {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      final userData = userDoc.data();
      if (userData != null) {
        final model = UserModel.fromJson({...userData, 'id': userDoc.id});
        lastActive = model.lastLogin;
      }
    }

    return {
      'moodLogs': emotionSnapshot.docs.length,
      'completedActivities': activitySnapshot.docs.length,
      'lastActive': lastActive,
    };
  }

  Future<List<Map<String, dynamic>>> getMoodRiskUsers({
    int lookbackDays = 21,
    int limit = 12,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: lookbackDays));
      final usersSnapshot = await _firestore.collection(_usersCollection).get();
      final emotionsSnapshot = await _firestore.collection('emotions').get();

      final usersById = <String, UserModel>{
        for (final doc in usersSnapshot.docs)
          doc.id: UserModel.fromJson({...doc.data(), 'id': doc.id})
      };

      final byUser = <String, _MoodRiskAccumulator>{};

      for (final doc in emotionsSnapshot.docs) {
        final data = doc.data();
        final userId =
            ((data['userID'] ?? data['userId'] ?? data['uid']) as String?)
                    ?.trim() ??
                '';
        if (userId.isEmpty) continue;

        final timestamp = _parseEmotionTimestamp(data);
        if (timestamp == null || timestamp.isBefore(since)) continue;

        final emotion = ((data['emotionType'] ??
                    data['emotion'] ??
                    data['mood']) as String?)
                ?.trim()
                .toLowerCase() ??
            'unknown';

        final entry = byUser.putIfAbsent(userId, _MoodRiskAccumulator.new);
        entry.totalLogs += 1;
        entry.lastMoodAt =
            entry.lastMoodAt == null || timestamp.isAfter(entry.lastMoodAt!)
                ? timestamp
                : entry.lastMoodAt;

        if (_isNegativeEmotion(emotion)) {
          entry.negativeLogs += 1;
          entry.negativeByType[emotion] =
              (entry.negativeByType[emotion] ?? 0) + 1;

          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          if (timestamp.isAfter(sevenDaysAgo)) {
            entry.recentNegativeLogs += 1;
          }
        } else if (_isPositiveEmotion(emotion)) {
          entry.positiveLogs += 1;
        }
      }

      final results = <Map<String, dynamic>>[];

      byUser.forEach((userId, value) {
        if (value.totalLogs < 3) return;

        final user = usersById[userId];
        if (user == null) return;
        if (user.role == 'admin') return;

        final negativeRatio = value.negativeLogs / value.totalLogs;
        final recentNegativeRatio = value.negativeLogs == 0
            ? 0.0
            : value.recentNegativeLogs / value.negativeLogs;
        final volumeFactor = math.min(value.totalLogs / 20.0, 1.0);

        final riskScore = ((negativeRatio * 0.58) +
                (recentNegativeRatio * 0.25) +
                (volumeFactor * 0.10) +
                ((value.lastMoodAt != null &&
                        DateTime.now().difference(value.lastMoodAt!).inDays <=
                            3)
                    ? 0.07
                    : 0.0)) *
            100;

        final dominantNegativeMood = value.negativeByType.entries.isEmpty
            ? 'mixed'
            : (value.negativeByType.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;

        results.add({
          'userId': user.userID,
          'name': user.userName,
          'email': user.userEmail,
          'isDisabled': user.isDisabled,
          'lastLogin': user.lastLogin,
          'lastMoodAt': value.lastMoodAt,
          'totalLogs': value.totalLogs,
          'negativeLogs': value.negativeLogs,
          'positiveLogs': value.positiveLogs,
          'negativeRatio': negativeRatio,
          'dominantNegativeMood': dominantNegativeMood,
          'riskScore': riskScore.clamp(0, 100),
        });
      });

      results.sort(
          (a, b) => (b['riskScore'] as num).compareTo(a['riskScore'] as num));
      return results.take(limit).toList(growable: false);
    } catch (e) {
      developer.log('getMoodRiskUsers failed: $e',
          name: 'AdminService', level: 900);
      rethrow;
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'role': role,
    });
  }

  Future<void> setUserDisabled(String userId, bool isDisabled) async {
    await _firestore.collection(_usersCollection).doc(userId).set({
      'isDisabled': isDisabled,
    }, SetOptions(merge: true));
  }

  /// Create a new user account (admin action).
  /// Uses a secondary Firebase app so the admin's primary auth session
  /// is never interrupted — avoiding the permission-denied Firestore error.
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    // Create a temporary secondary Firebase app instance
    final secondaryApp = await Firebase.initializeApp(
      name: 'adminCreateUser_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      // Use secondary auth — does NOT affect the admin's primary session
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Sign out of secondary app immediately — we only needed it for auth creation
      await secondaryAuth.signOut();

      // Write Firestore document using PRIMARY instance (admin still signed in)
      final doc = <String, dynamic>{
        'userID': uid,
        'userName': name.trim(),
        'userEmail': email.trim(),
        'role': 'user',
        'isDisabled': false,
        'lastLogin': Timestamp.now(),
      };
      if (age != null) doc['age'] = age;
      if (gender != null) doc['gender'] = gender;

      await _firestore.collection(_usersCollection).doc(uid).set(doc);

      developer.log('Admin created user: $email (uid: $uid)', name: 'AdminService');
    } finally {
      // Always clean up the secondary app
      await secondaryApp.delete();
    }
  }

  /// Update name, age and/or gender for a user in Firestore.
  Future<void> updateUserProfile(
    String userId, {
    String? name,
    int? age,
    String? gender,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['userName'] = name.trim();
      updates['name'] = name.trim();
    }
    if (age != null) updates['age'] = age;
    if (gender != null) updates['gender'] = gender;
    if (updates.isEmpty) return;
    await _firestore.collection(_usersCollection).doc(userId).update(updates);
  }

  Future<void> resetPasswordForEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // Delete user (requires appropriate admin rules)
  Future<void> deleteUser(String userId) async {
    // You would typically handle Authentication deletion in Cloud Functions
    await _firestore.collection(_usersCollection).doc(userId).delete();
  }

  // Generate usage report
  Future<Map<String, dynamic>> generateUsageReport() async {
    // Collect aggregated data
    final usersSnapshot = await _firestore.collection(_usersCollection).get();
    final emotionsSnapshot = await _firestore.collectionGroup('emotion_logs').get();

    final users = usersSnapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    final activeUsers = users.where((u) => !u.isDisabled).length;
    final disabledUsers = users.where((u) => u.isDisabled).length;
    final adminUsers = users.where((u) => u.role == 'admin').length;

    int logsToday = 0;
    int logsThisWeek = 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));

    for (var doc in emotionsSnapshot.docs) {
      final date = _parseEmotionTimestamp(doc.data());
      if (date != null) {
        if (date.isAfter(todayStart)) {
          logsToday++;
        }
        if (date.isAfter(weekStart)) {
          logsThisWeek++;
        }
      }
    }

    int activeUsersThisWeek = 0;
    for (var user in users) {
      if (user.lastLogin != null && user.lastLogin!.isAfter(weekStart)) {
        activeUsersThisWeek++;
      }
    }

    return {
      'totalUsers': usersSnapshot.docs.length,
      'activeUsers': activeUsers,
      'disabledUsers': disabledUsers,
      'adminUsers': adminUsers,
      'totalLogs': emotionsSnapshot.docs.length,
      'logsToday': logsToday,
      'logsThisWeek': logsThisWeek,
      'activeUsersThisWeek': activeUsersThisWeek,
      'avgLogsPerUser': users.isEmpty
          ? 0.0
          : (emotionsSnapshot.docs.length / users.length).toStringAsFixed(1),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  DateTime? _parseEmotionTimestamp(Map<String, dynamic> data) {
    final raw = data['emotionLogTimestamp'] ??
        data['timestamp'] ??
        data['createdAt'] ??
        data['date'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) {
      if (raw > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return null;
  }

  bool _isNegativeEmotion(String emotion) {
    const negative = {
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
    };
    return negative.contains(emotion);
  }

  bool _isPositiveEmotion(String emotion) {
    const positive = {
      'happy',
      'calm',
      'grateful',
      'excited',
      'joyful',
      'relaxed',
      'hopeful',
    };
    return positive.contains(emotion);
  }
}

class _MoodRiskAccumulator {
  int totalLogs = 0;
  int negativeLogs = 0;
  int positiveLogs = 0;
  int recentNegativeLogs = 0;
  DateTime? lastMoodAt;
  final Map<String, int> negativeByType = {};
}
