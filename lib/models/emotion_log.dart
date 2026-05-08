import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionLog {
  final String logID;
  final String userID;
  final String emotionType;
  final int intensityScore;
  final String? notes;
  final DateTime timestamp;

  EmotionLog({
    required this.logID,
    required this.userID,
    required this.emotionType,
    required this.intensityScore,
    this.notes,
    required this.timestamp,
  });

  /// Whether this emotion is considered negative for trend detection
  bool get isNegative =>
      emotionType == 'Sad' ||
      emotionType == 'Anxious' ||
      emotionType == 'Angry';

  Map<String, dynamic> toMap() {
    return {
      'logID': logID,
      'userID': userID,
      'emotionType': emotionType,
      'intensityScore': intensityScore,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory EmotionLog.fromMap(Map<String, dynamic> map, String id) {
    return EmotionLog(
      logID: id,
      userID: map['userID'] ?? '',
      emotionType: map['emotionType'] ?? 'Unknown',
      intensityScore: map['intensityScore']?.toInt() ?? 3,
      notes: map['notes'],
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] != null
              ? DateTime.parse(map['timestamp'])
              : DateTime.now()),
    );
  }

  /// Map emotion label to a numeric score (1 = worst, 5 = best)
  static int emotionToScore(String emotion) {
    switch (emotion) {
      case 'Happy':
        return 5;
      case 'Calm':
        return 4;
      case 'Tired':
        return 2;
      case 'Anxious':
        return 2;
      case 'Sad':
        return 1;
      case 'Angry':
        return 1;
      default:
        return 3;
    }
  }
}
