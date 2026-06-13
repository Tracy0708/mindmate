import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/emotion_insight.dart';
import '../models/emotion_log.dart';
import '../services/emotion_service.dart';

class InsightsViewModel extends ChangeNotifier {
  final EmotionService _emotionService = EmotionService();

  EmotionInsight? _currentInsight;
  List<EmotionLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRange = 'week'; // 'week', 'month', '3months'

  EmotionInsight? get currentInsight => _currentInsight;
  List<EmotionLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedRange => _selectedRange;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  int get _rangeDays {
    switch (_selectedRange) {
      case 'month':
        return 30;
      case '3months':
        return 90;
      default:
        return 7;
    }
  }

  /// Change date range filter and refetch (AF1)
  void setRange(String range) {
    if (_selectedRange == range) return;
    _selectedRange = range;
    notifyListeners();
    fetchInsights();
  }

  /// Main fetch — retrieves logs and builds full analysis (NF2, NF3)
  Future<void> fetchInsights() async {
    final userId = _currentUserId;
    if (userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _emotionService.getRecentLogs(userId, days: _rangeDays);

      if (_logs.isEmpty) {
        // EF1: No data
        _currentInsight = EmotionInsight(
          mostFrequentEmotion: 'None',
          emotionFrequencies: {},
          averageIntensity: 0.0,
          trendSummary: 'Start tracking your emotions to see insights.',
          trendDirection: 'stable',
        );
      } else {
        _currentInsight = _analyzeData(_logs);
      }
    } catch (e) {
      // EF2: Connectivity or data error
      developer.log('Error fetching insights: $e', name: 'InsightsVM');
      _errorMessage = 'Failed to load insights. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Build the full EmotionInsight from raw logs (NF3)
  EmotionInsight _analyzeData(List<EmotionLog> logs) {
    // ── Frequency map ──
    final freq = <String, int>{};
    double totalIntensity = 0;
    int positiveDays = 0;
    int negativeDays = 0;

    for (var log in logs) {
      freq[log.emotionType] = (freq[log.emotionType] ?? 0) + 1;
      totalIntensity += log.resolvedScore;
      if (log.isEffectivelyNegative) {
        negativeDays++;
      } else {
        positiveDays++;
      }
    }

    // ── Most frequent ──
    String mostFrequent = '';
    int maxCount = 0;
    freq.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = emotion;
      }
    });

    // ── Daily scores (aggregate by day) ──
    final dailyMap = <String, List<int>>{};
    for (var log in logs) {
      final key =
          '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      dailyMap.putIfAbsent(key, () => []).add(log.resolvedScore.round());
    }
    final dailyScores = <DailyMoodScore>[];
    dailyMap.forEach((key, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      dailyScores.add(DailyMoodScore(date: DateTime.parse(key), score: avg));
    });
    dailyScores.sort((a, b) => a.date.compareTo(b.date));

    // ── Trend direction (compare first half vs second half) ──
    String trendDirection = 'stable';
    if (dailyScores.length >= 4) {
      final mid = dailyScores.length ~/ 2;
      final firstHalf = dailyScores.sublist(0, mid);
      final secondHalf = dailyScores.sublist(mid);
      final firstAvg = firstHalf.map((d) => d.score).reduce((a, b) => a + b) /
          firstHalf.length;
      final secondAvg = secondHalf.map((d) => d.score).reduce((a, b) => a + b) /
          secondHalf.length;
      final diff = secondAvg - firstAvg;
      if (diff > 0.3) {
        trendDirection = 'improving';
      } else if (diff < -0.3) {
        trendDirection = 'declining';
      }
    }

    // ── Trend summary text ──
    final avgScore = totalIntensity / logs.length;
    String trendSummary;
    if (trendDirection == 'improving') {
      trendSummary = 'Your mood has been improving! Keep up the great work.';
    } else if (trendDirection == 'declining') {
      trendSummary =
          'Your mood has been declining recently. Consider trying some self-care activities.';
    } else if (avgScore >= 3.5) {
      trendSummary = 'Your mood has been mostly positive. You\'re doing well!';
    } else if (avgScore >= 2.5) {
      trendSummary =
          'Your mood has been mixed. Remember to take care of yourself.';
    } else {
      trendSummary = 'You\'ve had some tough days. We\'re here to support you.';
    }

    // ── Suggestions (NF6) ──
    final suggestions = _generateSuggestions(
        freq, trendDirection, avgScore, negativeDays, positiveDays);

    return EmotionInsight(
      mostFrequentEmotion: mostFrequent,
      emotionFrequencies: freq,
      averageIntensity: avgScore,
      trendSummary: trendSummary,
      dailyScores: dailyScores,
      totalLogs: logs.length,
      positiveDays: positiveDays,
      negativeDays: negativeDays,
      trendDirection: trendDirection,
      suggestions: suggestions,
    );
  }

  /// Generate actionable suggestions based on patterns (NF6)
  List<InsightSuggestion> _generateSuggestions(
    Map<String, int> freq,
    String trend,
    double avgScore,
    int negativeDays,
    int positiveDays,
  ) {
    final suggestions = <InsightSuggestion>[];

    // High anxiety → breathing
    if ((freq['Anxious'] ?? 0) >= 2) {
      suggestions.add(const InsightSuggestion(
        title: 'Try Box Breathing',
        description:
            'You\'ve felt anxious recently. Breathing exercises can help calm your mind.',
        icon: '🌬️',
        actionType: 'breathing',
      ));
    }

    // Sadness → journaling
    if ((freq['Sad'] ?? 0) >= 2) {
      suggestions.add(const InsightSuggestion(
        title: 'Start a Gratitude Journal',
        description:
            'Journaling about positives can help shift your perspective during tough times.',
        icon: '📝',
        actionType: 'journaling',
      ));
    }

    // Declining trend → chatbot
    if (trend == 'declining') {
      suggestions.add(const InsightSuggestion(
        title: 'Talk to AI Assistant',
        description:
            'Your mood has been declining. Our AI assistant is here to listen and help.',
        icon: '🤖',
        actionType: 'chatbot',
      ));
    }

    // Anger → relaxation
    if ((freq['Angry'] ?? 0) >= 2) {
      suggestions.add(const InsightSuggestion(
        title: 'Progressive Relaxation',
        description:
            'Muscle relaxation can help release physical tension from anger.',
        icon: '💆',
        actionType: 'relaxation',
      ));
    }

    // General positive → affirmations
    if (suggestions.isEmpty && avgScore >= 3.5) {
      suggestions.add(const InsightSuggestion(
        title: 'Positive Affirmations',
        description:
            'You\'re doing great! Reinforce your good mood with uplifting affirmations.',
        icon: '✨',
        actionType: 'affirmations',
      ));
    }

    // Fallback
    if (suggestions.isEmpty) {
      suggestions.add(const InsightSuggestion(
        title: 'Keep Tracking',
        description:
            'Continue logging your moods daily for more personalized insights.',
        icon: '📊',
        actionType: 'none',
      ));
    }

    return suggestions;
  }
}
