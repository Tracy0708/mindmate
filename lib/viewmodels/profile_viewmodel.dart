import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/auth_service.dart';

class ProfileViewModel extends ChangeNotifier {
  UserSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await AuthService().getUserProfile();
      if (profile != null) {
        final prefs =
            profile.settings['notificationPrefs'] as Map<String, dynamic>? ??
                {};
        final enabled =
            prefs.isEmpty || prefs.values.any((v) => v == true);
        _settings = UserSettings(
          settingsId: profile.userID,
          notificationEnabled: enabled,
          userId: profile.userID,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool enable) async {
    if (_settings == null) return;

    _settings = _settings!.copyWith(notificationEnabled: enable);
    notifyListeners();

    await AuthService().updateNotificationPrefs({
      'dailyMoodReminder': enable,
      'breathingReminder': enable,
      'weeklySummary': enable,
      'motivationalQuotes': enable,
    });
  }
}
