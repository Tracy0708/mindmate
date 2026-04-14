class UserSettings {
  final String settingsId;
  final bool darkMode;
  final String language;
  final bool notificationEnabled;
  final String userId;

  UserSettings({
    required this.settingsId,
    required this.darkMode,
    required this.language,
    required this.notificationEnabled,
    required this.userId,
  });

  factory UserSettings.fromMap(Map<String, dynamic> data, String documentId) {
    return UserSettings(
      settingsId: documentId,
      darkMode: data['darkMode'] ?? false,
      language: data['language'] ?? 'en',
      notificationEnabled: data['notificationEnabled'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'language': language,
      'notificationEnabled': notificationEnabled,
      'userId': userId,
    };
  }

  UserSettings copyWith({
    String? settingsId,
    bool? darkMode,
    String? language,
    bool? notificationEnabled,
    String? userId,
  }) {
    return UserSettings(
      settingsId: settingsId ?? this.settingsId,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      userId: userId ?? this.userId,
    );
  }
}
