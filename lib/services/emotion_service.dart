import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emotion_log.dart';
import '../models/activity.dart';

/// Recommended activity data for a given emotion
class RecommendedActivity {
  final String title;
  final String description;
  final String activityType;
  final String emoji;
  final int durationMinutes;

  const RecommendedActivity({
    required this.title,
    required this.description,
    required this.activityType,
    required this.emoji,
    required this.durationMinutes,
  });
}

class EmotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Collection references ───
  CollectionReference<Map<String, dynamic>> _emotionLogsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('emotion_logs');

  CollectionReference<Map<String, dynamic>> _activitiesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('activities');

  // ─── Log an emotion to Firestore (NF5, NF6) ───
  Future<EmotionLog> logEmotion(EmotionLog log) async {
    final docRef = _emotionLogsRef(log.userID).doc(log.logID);
    await docRef.set(log.toMap());
    return log;
  }

  // ─── Check if the user already logged today (NF1) ───
  Future<bool> hasLoggedToday(String userId) async {
    final todayStart = _startOfDay(DateTime.now());
    final todayEnd = _endOfDay(DateTime.now());

    final snapshot = await _emotionLogsRef(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ─── Get today's log if it exists ───
  Future<EmotionLog?> getTodaysLog(String userId) async {
    final todayStart = _startOfDay(DateTime.now());
    final todayEnd = _endOfDay(DateTime.now());

    final snapshot = await _emotionLogsRef(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return EmotionLog.fromMap(doc.data(), doc.id);
  }

  // ─── Stream logs for a given month (real-time updates) ───
  Stream<List<EmotionLog>> streamLogsForMonth(String userId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _emotionLogsRef(userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EmotionLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─── Get recent logs for trend analysis (NF7) ───
  Future<List<EmotionLog>> getRecentLogs(String userId, {int days = 7}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _emotionLogsRef(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => EmotionLog.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── Get the current logging streak ───
  Future<int> getStreak(String userId) async {
    // Look back far enough to detect long streaks (e.g. 100-day badge).
    final logs = await getRecentLogs(userId, days: 366);
    if (logs.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = _startOfDay(DateTime.now());

    // Build a set of dates with logs
    final loggedDates = <String>{};
    for (final log in logs) {
      loggedDates.add(_dateKey(log.timestamp));
    }

    // Count consecutive days backwards from today
    while (loggedDates.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ─── Get total log count for a period ───
  Future<int> getLogCount(String userId, {int days = 30}) async {
    final logs = await getRecentLogs(userId, days: days);
    return logs.length;
  }

  // ─── Detect negative mood trend (NF7, AF4) ───
  /// Returns true if 3+ of the last 5 entries are negative (Sad, Anxious, Angry)
  bool detectNegativeTrend(List<EmotionLog> recentLogs) {
    if (recentLogs.length < 3) return false;
    final lastFive = recentLogs.take(5).toList();
    final negativeCount =
        lastFive.where((log) => log.isEffectivelyNegative).length;
    return negativeCount >= 3;
  }

  // ─── Get recommended activity based on emotion (NF8) ───
  RecommendedActivity getRecommendedActivity(String emotionType) {
    switch (emotionType) {
      case 'Sad':
        return const RecommendedActivity(
          title: 'Guided Journaling',
          description:
              'Write about 3 things you\'re grateful for today. Reflecting on positives can shift your perspective and brighten your mood.',
          activityType: 'journaling',
          emoji: '📝',
          durationMinutes: 10,
        );
      case 'Anxious':
        return const RecommendedActivity(
          title: 'Box Breathing',
          description:
              'A calming breathing technique: Inhale for 4 seconds, hold for 4, exhale for 4, hold for 4. Repeat to calm your nervous system.',
          activityType: 'breathing',
          emoji: '🌬️',
          durationMinutes: 5,
        );
      case 'Angry':
        return const RecommendedActivity(
          title: 'Progressive Muscle Relaxation',
          description:
              'Tense and release each muscle group to let go of physical tension. Start from your toes and work up to your head.',
          activityType: 'relaxation',
          emoji: '💆',
          durationMinutes: 8,
        );
      case 'Calm':
        return const RecommendedActivity(
          title: 'Gratitude Reflection',
          description:
              'You\'re in a wonderful state of calm. Take a moment to appreciate this feeling and note what contributed to it.',
          activityType: 'gratitude',
          emoji: '🙏',
          durationMinutes: 5,
        );
      case 'Happy':
        return const RecommendedActivity(
          title: 'Positive Affirmations',
          description:
              'Reinforce your good mood! Read through uplifting affirmations and internalize the positive energy.',
          activityType: 'affirmations',
          emoji: '✨',
          durationMinutes: 3,
        );
      default:
        return const RecommendedActivity(
          title: 'Mindful Breathing',
          description:
              'Take a few minutes to focus on your breath. Inhale deeply, exhale slowly.',
          activityType: 'breathing',
          emoji: '🌬️',
          durationMinutes: 5,
        );
    }
  }

  // ─── Log a completed activity to Firestore (NF10) ───
  Future<void> logActivity(Activity activity) async {
    final docRef = _activitiesRef(activity.userID).doc(activity.activityID);
    await docRef.set(activity.toMap());
  }

  // ─── Has the user genuinely completed this activity type today? ───
  // Only 'completed' docs count, so an 'ended_early' attempt never blocks a
  // later genuine completion. Two equality filters need no composite index;
  // the today filter is applied client-side.
  Future<bool> hasCompletedActivityToday(
      String userId, String activityType) async {
    final snapshot = await _activitiesRef(userId)
        .where('activityType', isEqualTo: activityType)
        .where('activityStatus', isEqualTo: 'completed')
        .get();
    final today = _startOfDay(DateTime.now());
    return snapshot.docs.any((d) {
      final ts = (d.data()['completionTime'] as Timestamp?)?.toDate();
      return ts != null && !ts.isBefore(today);
    });
  }

  // ─── Count completed activities (de-farmed) ───
  // Counts distinct (activityType, day) pairs among 'completed' docs so repeat
  // completions of the same activity on the same day can't inflate the count.
  // Monotonic and non-farmable — feeds activity milestones and badge displays.
  Future<int> getCompletedActivityCount(String userId) async {
    final snapshot = await _activitiesRef(userId)
        .where('activityStatus', isEqualTo: 'completed')
        .get();
    return _distinctTypeDays(snapshot.docs).length;
  }

  // ─── Count breathing sessions (de-farmed, distinct days) ───
  Future<int> getBreathingSessionCount(String userId) async {
    final snapshot = await _activitiesRef(userId)
        .where('activityType', isEqualTo: 'breathing')
        .where('activityStatus', isEqualTo: 'completed')
        .get();
    return _distinctTypeDays(snapshot.docs).length;
  }

  // Distinct "<type>@<day>" keys for completed activity docs.
  Set<String> _distinctTypeDays(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final keys = <String>{};
    for (final doc in docs) {
      final data = doc.data();
      final type = data['activityType'] as String? ?? 'unknown';
      final ts = (data['completionTime'] as Timestamp?)?.toDate();
      if (ts != null) keys.add('$type@${_dateKey(ts)}');
    }
    return keys;
  }

  // ─── Delete an emotion log ───
  Future<void> deleteEmotionLog(String userId, String logId) async {
    await _emotionLogsRef(userId).doc(logId).delete();
  }

  // ─── Helper: start of day ───
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // ─── Helper: end of day ───
  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  // ─── Helper: date key for streak ───
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
