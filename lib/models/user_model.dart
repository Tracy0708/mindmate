class UserModel {
  final String userID;
  final String userName;
  final String userEmail;
  final int? age;
  final String? gender;
  final Map<String, dynamic> settings;

  UserModel({
    required this.userID,
    required this.userName,
    required this.userEmail,
    this.age,
    this.gender,
    Map<String, dynamic>? settings,
  }) : settings = settings ??
            {
              'darkMode': false,
              'language': 'en',
              'notificationPrefs': <String, bool>{},
            };

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'userName': userName,
      'userEmail': userEmail,
      'age': age,
      'gender': gender,
      'settings': settings,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final storedUserName = (json['userName'] as String?)?.trim();
    final storedName = (json['name'] as String?)?.trim();
    final resolvedName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : (storedUserName != null && storedUserName.isNotEmpty)
            ? storedUserName
            : 'User';

    return UserModel(
      userID: json['userID'] ?? '',
      userName: resolvedName,
      userEmail: json['userEmail'] ?? json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : {
              'darkMode': false,
              'language': 'en',
              'notificationPrefs': <String, bool>{},
            },
    );
  }
}
