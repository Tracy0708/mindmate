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

  Map<String, dynamic> toMap() {
    return {
      'logID': logID,
      'userID': userID,
      'emotionType': emotionType,
      'intensityScore': intensityScore,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmotionLog.fromMap(Map<String, dynamic> map, String id) {
    return EmotionLog(
      logID: id,
      userID: map['userID'] ?? '',
      emotionType: map['emotionType'] ?? 'Unknown',
      intensityScore: map['intensityScore']?.toInt() ?? 3,
      notes: map['notes'],
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}
