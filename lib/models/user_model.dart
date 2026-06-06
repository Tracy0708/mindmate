import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userID;
  final String? displayId;
  final String userName;
  final String userEmail;
  final String role;
  final bool isDisabled;
  final DateTime? lastLogin;
  final int? age;
  final String? gender;
  final Map<String, dynamic> settings;

  UserModel({
    required this.userID,
    this.displayId,
    required this.userName,
    required this.userEmail,
    this.role = 'user',
    this.isDisabled = false,
    this.lastLogin,
    this.age,
    this.gender,
    Map<String, dynamic>? settings,
  }) : settings = settings ??
            {
              'darkMode': false,
              'language': 'en',
              'notificationPrefs': <String, bool>{},
              'equippedAvatar': 'default',
              'unlockedAvatars': ['default'],
            };

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'displayId': displayId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role,
      'isDisabled': isDisabled,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
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
      userID: json['userID'] ?? json['id'] ?? '',
      displayId: json['displayId'] as String?,
      userName: resolvedName,
      userEmail: json['userEmail'] ?? json['email'] ?? '',
      role: (json['role'] as String?) ?? 'user',
      isDisabled: (json['isDisabled'] as bool?) ?? false,
      lastLogin: _parseDateTime(json['lastLogin']),
      age: json['age'],
      gender: json['gender'],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : {
              'darkMode': false,
              'language': 'en',
              'notificationPrefs': <String, bool>{},
              'equippedAvatar': 'default',
              'unlockedAvatars': ['default'],
            },
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
