class UserSettings {
  final String settingsId;
  final bool notificationEnabled;
  final String userId;

  UserSettings({
    required this.settingsId,
    required this.notificationEnabled,
    required this.userId,
  });

  factory UserSettings.fromMap(Map<String, dynamic> data, String documentId) {
    return UserSettings(
      settingsId: documentId,
      notificationEnabled: data['notificationEnabled'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationEnabled': notificationEnabled,
      'userId': userId,
    };
  }

  UserSettings copyWith({
    String? settingsId,
    bool? notificationEnabled,
    String? userId,
  }) {
    return UserSettings(
      settingsId: settingsId ?? this.settingsId,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      userId: userId ?? this.userId,
    );
  }
}
