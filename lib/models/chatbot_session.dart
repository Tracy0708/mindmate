class ChatbotSession {
  final String sessionID;
  final DateTime startTime;
  final DateTime? endTime;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> emotionLogRefs;
  final String assistantID;

  ChatbotSession({
    required this.sessionID,
    required this.startTime,
    this.endTime,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? emotionLogRefs,
    required this.assistantID,
  })  : messages = messages ?? [],
        emotionLogRefs = emotionLogRefs ?? [];

  Map<String, dynamic> toJson() {
    return {
      'sessionID': sessionID,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'messages': messages,
      'emotionLogRefs': emotionLogRefs,
      'assistantID': assistantID,
    };
  }

  factory ChatbotSession.fromJson(Map<String, dynamic> json) {
    return ChatbotSession(
      sessionID: json['sessionID'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      emotionLogRefs:
          List<Map<String, dynamic>>.from(json['emotionLogRefs'] ?? []),
      assistantID: json['assistantID'],
    );
  }
}
