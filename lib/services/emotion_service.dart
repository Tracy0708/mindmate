import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emotion_entry.dart';
import '../models/emotion_insight.dart';

class EmotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'emotions';

  // Create a new emotion log
  Future<EmotionLog> createEmotionLog({
    required String sessionID,
    required String emotionType,
    required int intensity,
    String? notes,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    final emotionLog = EmotionLog(
      emotionLogID: docRef.id,
      sessionID: sessionID,
      emotionType: emotionType,
      intensity: intensity,
      emotionLogNotes: notes,
    );

    await docRef.set(emotionLog.toJson());
    return emotionLog;
  }

  // Get emotion logs for a specific session
  Stream<List<EmotionLog>> getEmotionLogsForSession(String sessionID) {
    return _firestore
        .collection(_collection)
        .where('sessionID', isEqualTo: sessionID)
        .orderBy('emotionLogTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmotionLog.fromJson(doc.data()))
          .toList();
    });
  }

  // Get emotion logs for a date range
  Stream<List<EmotionLog>> getEmotionLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where('emotionLogTimestamp',
            isGreaterThanOrEqualTo: startDate, isLessThan: endDate)
        .orderBy('emotionLogTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmotionLog.fromJson(doc.data()))
          .toList();
    });
  }

  // Get emotion summary for a time period
  Future<EmotionInsight> getEmotionSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('emotionLogTimestamp',
            isGreaterThanOrEqualTo: startDate.toIso8601String(), isLessThan: endDate.toIso8601String())
        .get();

    final emotions = querySnapshot.docs
        .map((doc) => EmotionLog.fromJson(doc.data()))
        .toList();

    if (emotions.isEmpty) {
      return EmotionInsight(mostFrequentEmotion: 'None', emotionFrequencies: {}, averageIntensity: 0.0, trendSummary: 'No data to show.');
    }

    final freq = <String, int>{};
    double totalIntensity = 0;
    String mostFrequent = '';
    int maxCount = 0;

    for (var emotion in emotions) {
      freq[emotion.emotionType] = (freq[emotion.emotionType] ?? 0) + 1;
      totalIntensity += emotion.intensity;
      
      if (freq[emotion.emotionType]! > maxCount) {
        maxCount = freq[emotion.emotionType]!;
        mostFrequent = emotion.emotionType;
      }
    }

    return EmotionInsight(
      mostFrequentEmotion: mostFrequent,
      emotionFrequencies: freq,
      averageIntensity: totalIntensity / emotions.length,
      trendSummary: 'Your mood has mostly been $mostFrequent recently. Keep up the tracking!',
    );
  }

  // Update an emotion log
  Future<void> updateEmotionLog(EmotionLog emotionLog) async {
    await _firestore
        .collection(_collection)
        .doc(emotionLog.emotionLogID)
        .update(emotionLog.toJson());
  }

  // Delete an emotion log
  Future<void> deleteEmotionLog(String emotionLogID) async {
    await _firestore.collection(_collection).doc(emotionLogID).delete();
  }
}
