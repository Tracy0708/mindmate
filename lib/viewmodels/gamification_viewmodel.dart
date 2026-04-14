import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class GamificationViewModel extends ChangeNotifier {
  final GamificationService _gamificationService = GamificationService();

  int _totalPoints = 0;
  Map<String, dynamic>? _userStats;
  bool _isLoading = false;

  int get totalPoints => _totalPoints;
  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;

  Future<void> fetchUserStats(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _totalPoints = await _gamificationService.getUserTotalPoints(userId);
      _userStats = await _gamificationService.getUserStats(userId);
    } catch (e) {
      print("Failed to fetch gamification stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
