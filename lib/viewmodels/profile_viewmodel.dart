import 'package:flutter/material.dart';
import '../models/user_settings.dart';

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
      // Simulate fetching from Firestore since missing full implementation
      await Future.delayed(const Duration(seconds: 1));
      
      _settings = UserSettings(
        settingsId: 'mock_settings_id',
        darkMode: false,
        language: 'en',
        notificationEnabled: true,
        userId: userId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    if (_settings == null) return;
    
    _settings = _settings!.copyWith(darkMode: isDark);
    notifyListeners();
    
    // In actual implementation, update Firestore here.
  }

  Future<void> toggleNotifications(bool enable) async {
    if (_settings == null) return;
    
    _settings = _settings!.copyWith(notificationEnabled: enable);
    notifyListeners();
    
    // In actual implementation, update Firestore here.
  }
}
