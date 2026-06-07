import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import '../models/gamification_history.dart';
import '../models/badge_catalog.dart';

class GamificationViewModel extends ChangeNotifier {
  final GamificationService _gamificationService = GamificationService();
  final NotificationService _notificationService = NotificationService();

  int _totalPoints = 0;
  final List<GamificationHistory> _achievements = [];
  List<GamificationHistory> _history = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = false;

  int get totalPoints => _totalPoints;
  List<GamificationHistory> get achievements => _achievements;
  List<GamificationHistory> get history => _history;
  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Writes a notification-center entry when a badge is unlocked. Non-critical —
  /// failures are logged and swallowed so they never block the award flow.
  Future<void> _notifyBadge(String userId, GamificationHistory badge) async {
    try {
      await _notificationService.createNotification(
        userID: userId,
        title: '🏆 Badge Unlocked: ${badge.achievement}',
        message:
            'You earned the ${badge.achievement} badge (+${badge.pointsEarned} pts). Keep it up!',
        type: 'milestone',
      );
    } catch (e) {
      developer.log('Badge notification failed (non-critical): $e',
          name: 'GamificationVM');
    }
  }

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

  /// Fetch recent gamification history (last 20 entries) for the Home feed
  Future<void> fetchHistory() async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      _history = await _gamificationService.getRecentHistory(userId, limit: 20);
      notifyListeners();
    } catch (e) {
      developer.log('Failed to fetch history: $e', name: 'GamificationVM');
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
  Future<List<GamificationHistory>> checkStreakMilestones(int currentStreak) =>
      _awardCatalogTiers(BadgeCategory.streak, currentStreak);

  /// Award every badge in [category] whose threshold has been reached and isn't
  /// yet earned. Definitions come from the single [kBadgeCatalog] source of
  /// truth. `>=` (not `==`) so accounts already past a tier still get it; the
  /// idempotent [GamificationService.recordAchievementOnce] keeps each to once.
  Future<List<GamificationHistory>> _awardCatalogTiers(
      BadgeCategory category, int count) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final awarded = <GamificationHistory>[];
    try {
      for (final def in kBadgeCatalog.where((d) => d.category == category)) {
        if (count < def.threshold) continue;
        final achievement = await _gamificationService.recordAchievementOnce(
          userID: userId,
          achievement: def.title,
          points: def.points,
          metadata: {'type': 'milestone', 'badge': def.title},
        );
        if (achievement != null) {
          _totalPoints += def.points;
          await _notifyBadge(userId, achievement);
          awarded.add(achievement);
        }
      }
      if (awarded.isNotEmpty) notifyListeners();
    } catch (e) {
      developer.log('Failed to award ${category.name} badges: $e', name: 'GamificationVM');
    }
    return awarded;
  }

  /// Award every mood-log badge reached and not yet earned.
  Future<List<GamificationHistory>> checkLogMilestones(int logCount) =>
      _awardCatalogTiers(BadgeCategory.logs, logCount);

  /// Award every activity badge reached and not yet earned.
  Future<List<GamificationHistory>> checkActivityMilestones(int actCount) =>
      _awardCatalogTiers(BadgeCategory.activity, actCount);

  /// Award the breathing badge(s) (Zen Master at 5 sessions) reached and not yet earned.
  Future<List<GamificationHistory>> checkBreathingMilestones(int breathingCount) =>
      _awardCatalogTiers(BadgeCategory.breathing, breathingCount);

  /// One-time catch-up: award any badge the user has already earned by current
  /// counts (points + notifications), without surfacing toasts. Idempotent, so
  /// it's safe to call on every app load. Used to backfill existing accounts
  /// whose counts were already past thresholds before the `>=` fix.
  Future<void> syncEarnedBadges({
    required int streak,
    required int totalLogCount,
    required int activityCount,
    required int breathingCount,
  }) async {
    await checkStreakMilestones(streak);
    await checkLogMilestones(totalLogCount);
    await checkActivityMilestones(activityCount);
    await checkBreathingMilestones(breathingCount);
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
