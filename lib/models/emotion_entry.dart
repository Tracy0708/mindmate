class EmotionLog {
  final String emotionLogID;
  final String sessionID;
  final String emotionType;
  final int intensity;
  final String? emotionLogNotes;
  final DateTime emotionLogTimestamp;

  EmotionLog({
    required this.emotionLogID,
    required this.sessionID,
    required this.emotionType,
    required this.intensity,
    this.emotionLogNotes,
    DateTime? emotionLogTimestamp,
  }) : emotionLogTimestamp = emotionLogTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'emotionLogID': emotionLogID,
      'sessionID': sessionID,
      'emotionType': emotionType,
      'intensity': intensity,
      'emotionLogNotes': emotionLogNotes,
      'emotionLogTimestamp': emotionLogTimestamp.toIso8601String(),
    };
  }

  factory EmotionLog.fromJson(Map<String, dynamic> json) {
    return EmotionLog(
      emotionLogID: json['emotionLogID'],
      sessionID: json['sessionID'],
      emotionType: json['emotionType'],
      intensity: json['intensity'],
      emotionLogNotes: json['emotionLogNotes'],
      emotionLogTimestamp: DateTime.parse(json['emotionLogTimestamp']),
    );
  }
}
