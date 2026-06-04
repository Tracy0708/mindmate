import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/gamification_history.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'gamification_history';

  // Record a new achievement
  Future<GamificationHistory> recordAchievement({
    required String userID,
    required String achievement,
    required int points,
    Map<String, dynamic>? metadata,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    final record = GamificationHistory(
      gamificationHistoryID: docRef.id,
      pointsEarned: points,
      achievement: achievement,
      metadata: {
        'userID': userID,
        ...?metadata,
      },
    );

    await docRef.set(record.toJson());
    return record;
  }

  // Get user's achievements
  Stream<List<GamificationHistory>> getUserAchievements(String userID) {
    return _firestore
        .collection(_collection)
        .where('metadata.userID', isEqualTo: userID)
        .orderBy('achievementTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GamificationHistory.fromJson(doc.data()))
          .toList();
    });
  }

  // Get user's total points
  Future<int> getUserTotalPoints(String userID) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('metadata.userID', isEqualTo: userID)
        .get();

    return querySnapshot.docs.fold<int>(
      0,
      (acc, doc) => acc + (doc.data()['pointsEarned'] as int),
    );
  }

  // Get user's achievement stats
  Future<Map<String, dynamic>> getUserStats(String userID) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('metadata.userID', isEqualTo: userID)
        .get();

    final achievements = querySnapshot.docs
        .map((doc) => GamificationHistory.fromJson(doc.data()))
        .toList();
    
    // Sort by timestamp descending so recentAchievements are actually recent
    achievements.sort((a, b) => b.achievementTimestamp.compareTo(a.achievementTimestamp));

    final stats = {
      'totalPoints': 0,
      'achievementsCount': achievements.length,
      'achievementsByType': <String, int>{},
      'recentAchievements': achievements
          .where((a) => !a.achievement.contains('Mood Logged') && 
                        !a.achievement.contains('Activity Completed') && 
                        !a.achievement.contains('Unlocked Avatar'))
          .take(5)
          .map((a) => {
                'achievement': a.achievement,
                'points': a.pointsEarned,
                'timestamp': a.achievementTimestamp.toIso8601String(),
              })
          .toList(),
    };

    for (var achievement in achievements) {
      stats['totalPoints'] =
          (stats['totalPoints'] as int) + achievement.pointsEarned;

      // Safely access and update achievementsByType
      final achievementsByType =
          stats['achievementsByType'] as Map<String, int>;
      achievementsByType[achievement.achievement] =
          (achievementsByType[achievement.achievement] ?? 0) + 1;
    }

    return stats;
  }

  // Get recent gamification history for the Home tab feed
  // NOTE: No .orderBy() here — avoids needing a composite Firestore index
  // on the nested metadata.userID field. Sorting is done client-side.
  Future<List<GamificationHistory>> getRecentHistory(String userID, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('metadata.userID', isEqualTo: userID)
          .get();

      final items = querySnapshot.docs
          .map((doc) => GamificationHistory.fromJson(doc.data()))
          .toList();

      // Sort newest first in Dart (no composite index needed)
      items.sort((a, b) => b.achievementTimestamp.compareTo(a.achievementTimestamp));

      developer.log('getRecentHistory: fetched ${items.length} records for $userID', name: 'GamificationService');
      return items.take(limit).toList();
    } catch (e) {
      developer.log('getRecentHistory error: $e', name: 'GamificationService');
      return [];
    }
  }

  // Check and award streak achievements

  Future<List<GamificationHistory>> checkAndAwardStreaks(
    String userID,
    int currentStreak,
  ) async {
    final streakAchievements = <GamificationHistory>[];
    final streakMilestones = {
      3: 'Getting Started',
      7: 'Streak Master',
      14: 'Two Weeks Strong',
      30: 'Dedicated',
      100: 'Centurion',
      365: 'Yearly Champion',
    };

    for (var milestone in streakMilestones.entries) {
      if (currentStreak == milestone.key) {
        final achievement = await recordAchievement(
          userID: userID,
          achievement: milestone.value,
          points: milestone.key * 10,
          metadata: {
            'type': 'streak',
            'streakDays': milestone.key,
          },
        );
        streakAchievements.add(achievement);
      }
    }

    return streakAchievements;
  }
}
