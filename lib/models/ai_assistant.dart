class AIAssistant {
  final String assistantID;
  final DateTime createdTimestamp;
  final String description;
  final bool isActive;

  AIAssistant({
    required this.assistantID,
    required this.description,
    required this.isActive,
    DateTime? createdTimestamp,
  }) : createdTimestamp = createdTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'assistantID': assistantID,
      'createdTimestamp': createdTimestamp.toIso8601String(),
      'description': description,
      'isActive': isActive,
    };
  }

  factory AIAssistant.fromJson(Map<String, dynamic> json) {
    return AIAssistant(
      assistantID: json['assistantID'],
      createdTimestamp: DateTime.parse(json['createdTimestamp']),
      description: json['description'],
      isActive: json['isActive'],
    );
  }
}
