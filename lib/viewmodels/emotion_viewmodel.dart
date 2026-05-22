import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/emotion_log.dart';
import '../models/activity.dart';
import '../services/emotion_service.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';

class EmotionViewModel extends ChangeNotifier {
  final EmotionService _emotionService = EmotionService();
  final GamificationService _gamificationService = GamificationService();

  // ─── State ───
  bool _hasLoggedToday = false;
  bool _checkedToday = false;
  bool _isSubmitting = false;
  bool _showChatbotPrompt = false;
  String? _errorMessage;
  EmotionLog? _todaysLog;
  List<EmotionLog> _recentLogs = [];
  RecommendedActivity? _recommendedActivity;
  int _streak = 0;
  int _logCount = 0;
  int _completedActivityCount = 0;
  int _breathingSessionCount = 0;

  // ─── Getters ───
  bool get hasLoggedToday => _hasLoggedToday;
  bool get checkedToday => _checkedToday;
  bool get isSubmitting => _isSubmitting;
  bool get showChatbotPrompt => _showChatbotPrompt;
  String? get errorMessage => _errorMessage;
  EmotionLog? get todaysLog => _todaysLog;
  List<EmotionLog> get recentLogs => _recentLogs;
  RecommendedActivity? get recommendedActivity => _recommendedActivity;
  int get streak => _streak;
  int get logCount => _logCount;
  int get completedActivityCount => _completedActivityCount;
  int get breathingSessionCount => _breathingSessionCount;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ─── Check if today's emotion is logged (NF1) ───
  Future<void> checkTodaysLog() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      _todaysLog = await _emotionService.getTodaysLog(userId);
      _hasLoggedToday = _todaysLog != null;
      _checkedToday = true;

      // Also load supporting data
      _recentLogs = await _emotionService.getRecentLogs(userId);
      _streak = await _emotionService.getStreak(userId);
      _logCount = await _emotionService.getLogCount(userId, days: 30);
      _completedActivityCount = await _emotionService.getCompletedActivityCount(userId);
      _breathingSessionCount = await _emotionService.getBreathingSessionCount(userId);

      notifyListeners();
    } catch (e) {
      developer.log('Error checking today\'s log: $e', name: 'EmotionVM');
      _checkedToday = true;
      notifyListeners();
    }
  }

  // ─── Submit emotion log (NF3-NF8) ───
  /// Returns true if save was successful
  Future<bool> submitEmotion({
    required String emotionType,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // NF5: Create the emotion log
      final log = EmotionLog(
        logID: DateTime.now().millisecondsSinceEpoch.toString(),
        userID: userId,
        emotionType: emotionType,
        intensityScore: EmotionLog.emotionToScore(emotionType),
        notes: notes,
        timestamp: DateTime.now(),
      );

      // NF6: Save to Firestore
      await _emotionService.logEmotion(log);
      _todaysLog = log;
      _hasLoggedToday = true;

      developer.log('Emotion saved: $emotionType', name: 'EmotionVM');

      // Award gamification points for mood log
      try {
        await _gamificationService.recordAchievement(
          userID: userId,
          achievement: 'Mood Logged',
          points: 10,
          metadata: {'type': 'mood_log', 'emotion': emotionType},
        );
      } catch (e) {
        developer.log('Gamification award failed (non-critical): $e', name: 'EmotionVM');
      }

      // NF7: Check for recent mood trend
      _recentLogs = await _emotionService.getRecentLogs(userId);
      _showChatbotPrompt = _emotionService.detectNegativeTrend(_recentLogs);

      // NF8: Get personalized activity recommendation
      _recommendedActivity =
          _emotionService.getRecommendedActivity(emotionType);

      // Update streak and check streak milestones
      _streak = await _emotionService.getStreak(userId);
      _logCount = await _emotionService.getLogCount(userId, days: 30);

      // Check streak-based gamification achievements
      try {
        await _gamificationService.checkAndAwardStreaks(userId, _streak);
      } catch (e) {
        developer.log('Streak milestone check failed (non-critical): $e', name: 'EmotionVM');
      }

      // Write user notifications for mood log and milestones
      try {
        final notifService = NotificationService();
        await notifService.createNotification(
          userID: userId,
          title: '${_moodEmoji(emotionType)} Mood Logged',
          message: 'You tracked your mood as $emotionType today. Keep it up!',
          type: 'mood_log',
        );
        if (_streak == 7) {
          await notifService.createNotification(
            userID: userId,
            title: '🔥 7-Day Streak!',
            message: 'Amazing! You\'ve logged your mood 7 days in a row.',
            type: 'milestone',
          );
        } else if (_streak == 30) {
          await notifService.createNotification(
            userID: userId,
            title: '🔥 30-Day Streak!',
            message: 'Incredible! 30 consecutive days of mood tracking.',
            type: 'milestone',
          );
        }
        final totalLogs = await _emotionService.getLogCount(userId, days: 365);
        if (totalLogs == 1) {
          await notifService.createNotification(
            userID: userId,
            title: '🎉 First Step!',
            message: 'You\'ve logged your very first emotion. Welcome to MindMate!',
            type: 'milestone',
          );
        } else if (totalLogs == 10) {
          await notifService.createNotification(
            userID: userId,
            title: '🎯 Goal Setter',
            message: 'You\'ve logged 10 emotions. You\'re building a great habit!',
            type: 'milestone',
          );
        } else if (totalLogs == 30) {
          await notifService.createNotification(
            userID: userId,
            title: '📊 Routine Builder',
            message: '30 mood logs! You\'re a dedicated tracker.',
            type: 'milestone',
          );
        }
      } catch (e) {
        developer.log('User notification write failed (non-critical): $e', name: 'EmotionVM');
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      // EF1: Handle save failure
      developer.log('Error saving emotion: $e', name: 'EmotionVM');
      _errorMessage =
          'Failed to save mood log. Please check your connection and try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Log a completed activity (NF9, NF10) ───
  Future<bool> logCompletedActivity({
    required String title,
    required String activityType,
    required Duration duration,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final activity = Activity(
        activityID: DateTime.now().millisecondsSinceEpoch.toString(),
        userID: userId,
        linkedEmotionLogID: _todaysLog?.logID,
        title: title,
        activityType: activityType,
        activityStatus: 'completed',
        activityNotes: notes ?? '',
        completionTime: DateTime.now(),
        duration: duration,
      );

      await _emotionService.logActivity(activity);
      developer.log('Activity logged: $title', name: 'EmotionVM');

      // Award gamification points for activity completion
      try {
        await _gamificationService.recordAchievement(
          userID: userId,
          achievement: 'Activity Completed',
          points: 25,
          metadata: {'type': 'activity', 'activity': title},
        );
      } catch (e) {
        developer.log('Gamification award failed (non-critical): $e', name: 'EmotionVM');
      }

      // Update local counts so Home tab reflects immediately
      _completedActivityCount++;
      if (activityType == 'breathing') _breathingSessionCount++;
      notifyListeners();

      return true;
    } catch (e) {
      developer.log('Error logging activity: $e', name: 'EmotionVM');
      return false;
    }
  }

  // ─── Dismiss the daily check-in prompt (AF1) ───
  void dismissDailyPrompt() {
    _checkedToday = true;
    _hasLoggedToday = true; // Treat as "handled" so it won't prompt again
    notifyListeners();
  }

  // ─── Dismiss chatbot prompt (AF4.3) ───
  void dismissChatbotPrompt() {
    _showChatbotPrompt = false;
    notifyListeners();
  }

  // ─── Clear recommendation (for navigating away) ───
  void clearRecommendation() {
    _recommendedActivity = null;
    _showChatbotPrompt = false;
    notifyListeners();
  }

  String _moodEmoji(String emotion) {
    const map = {
      'Happy': '😊', 'Sad': '😢', 'Anxious': '😰',
      'Angry': '😠', 'Calm': '😌', 'Tired': '😴',
    };
    return map[emotion] ?? '💙';
  }

  // ─── Reset for fresh state ───
  void reset() {
    _hasLoggedToday = false;
    _checkedToday = false;
    _isSubmitting = false;
    _showChatbotPrompt = false;
    _errorMessage = null;
    _todaysLog = null;
    _recentLogs = [];
    _recommendedActivity = null;
    _streak = 0;
    _logCount = 0;
    _completedActivityCount = 0;
    _breathingSessionCount = 0;
    notifyListeners();
  }
}
