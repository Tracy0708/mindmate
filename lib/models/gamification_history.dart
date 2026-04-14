class GamificationHistory {
  final String gamificationHistoryID;
  final int pointsEarned;
  final String achievement;
  final DateTime achievementTimestamp;
  final Map<String, dynamic> metadata;

  GamificationHistory({
    required this.gamificationHistoryID,
    required this.pointsEarned,
    required this.achievement,
    DateTime? achievementTimestamp,
    Map<String, dynamic>? metadata,
  })  : achievementTimestamp = achievementTimestamp ?? DateTime.now(),
        metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'gamificationHistoryID': gamificationHistoryID,
      'pointsEarned': pointsEarned,
      'achievement': achievement,
      'achievementTimestamp': achievementTimestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory GamificationHistory.fromJson(Map<String, dynamic> json) {
    return GamificationHistory(
      gamificationHistoryID: json['gamificationHistoryID'],
      pointsEarned: json['pointsEarned'],
      achievement: json['achievement'],
      achievementTimestamp: DateTime.parse(json['achievementTimestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
