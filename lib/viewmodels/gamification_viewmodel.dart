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
  Future<List<GamificationHistory>> checkStreakMilestones(int currentStreak) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final awarded = await _gamificationService.checkAndAwardStreaks(userId, currentStreak);
      if (awarded.isNotEmpty) {
        for (var a in awarded) {
          _totalPoints += a.pointsEarned;
        }
        notifyListeners();
      }
      return awarded;
    } catch (e) {
      developer.log('Failed to check streak milestones: $e', name: 'GamificationVM');
      return [];
    }
  }

  /// Check and award first mood log milestone
  Future<GamificationHistory?> checkFirstLogMilestone(int logCount) async {
    if (logCount != 1) return null; // Only for the very first log
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final achievement = await _gamificationService.recordAchievement(
        userID: userId,
        achievement: 'First Step',
        points: 50,
        metadata: {'type': 'milestone', 'milestone': 'first_log'},
      );
      _totalPoints += 50;
      notifyListeners();
      return achievement;
    } catch (e) {
      developer.log('Failed to award first log milestone: $e', name: 'GamificationVM');
      return null;
    }
  }

  /// Spend points on an item
  Future<bool> spendPoints(String itemName, int cost) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    if (_totalPoints < cost) return false;

    try {
      await _gamificationService.recordAchievement(
        userID: userId,
        achievement: 'Unlocked Avatar: $itemName',
        points: -cost,
        metadata: {'type': 'purchase', 'item': itemName},
      );
      _totalPoints -= cost;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Failed to spend points: $e', name: 'GamificationVM');
      return false;
    }
  }
}
