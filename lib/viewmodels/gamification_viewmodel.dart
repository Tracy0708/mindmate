import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../services/gamification_service.dart';
import '../models/gamification_history.dart';

class GamificationViewModel extends ChangeNotifier {
  final GamificationService _gamificationService = GamificationService();

  int _totalPoints = 0;
  List<GamificationHistory> _achievements = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = false;

  int get totalPoints => _totalPoints;
  List<GamificationHistory> get achievements => _achievements;
  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Fetch the user's gamification stats from Firestore
  Future<void> fetchUserStats() async {
    final userId = _currentUserId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _totalPoints = await _gamificationService.getUserTotalPoints(userId);
      _userStats = await _gamificationService.getUserStats(userId);
    } catch (e) {
      developer.log('Failed to fetch gamification stats: $e', name: 'GamificationVM');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Award points for logging a mood
  Future<void> awardMoodLogPoints() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _gamificationService.recordAchievement(
        userID: userId,
        achievement: 'Mood Logged',
        points: 10,
        metadata: {'type': 'mood_log'},
      );
      _totalPoints += 10;
      notifyListeners();
    } catch (e) {
      developer.log('Failed to award mood log points: $e', name: 'GamificationVM');
    }
  }

  /// Award points for completing an activity
  Future<void> awardActivityPoints(String activityTitle) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _gamificationService.recordAchievement(
        userID: userId,
        achievement: 'Activity Completed: $activityTitle',
        points: 25,
        metadata: {'type': 'activity', 'activity': activityTitle},
      );
      _totalPoints += 25;
      notifyListeners();
    } catch (e) {
      developer.log('Failed to award activity points: $e', name: 'GamificationVM');
    }
  }

  /// Check and award streak milestones
  Future<void> checkStreakMilestones(int currentStreak) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final awarded = await _gamificationService.checkAndAwardStreaks(userId, currentStreak);
      if (awarded.isNotEmpty) {
        for (var a in awarded) {
          _totalPoints += a.pointsEarned;
        }
        notifyListeners();
      }
    } catch (e) {
      developer.log('Failed to check streak milestones: $e', name: 'GamificationVM');
    }
  }
}
