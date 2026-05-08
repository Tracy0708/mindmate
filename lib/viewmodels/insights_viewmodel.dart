import 'package:flutter/material.dart';
import '../models/emotion_insight.dart';
import '../models/emotion_log.dart';
import '../services/emotion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightsViewModel extends ChangeNotifier {
  final EmotionService _emotionService = EmotionService();

  EmotionInsight? _currentInsight;
  bool _isLoading = false;
  String? _errorMessage;

  EmotionInsight? get currentInsight => _currentInsight;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeeklyInsights() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final logs = await _emotionService.getRecentLogs(userId, days: 7);

      if (logs.isEmpty) {
        _currentInsight = EmotionInsight(
          mostFrequentEmotion: 'None',
          emotionFrequencies: {},
          averageIntensity: 0.0,
          trendSummary: 'No data to show.',
        );
      } else {
        final freq = <String, int>{};
        double totalIntensity = 0;
        String mostFrequent = '';
        int maxCount = 0;

        for (var log in logs) {
          freq[log.emotionType] = (freq[log.emotionType] ?? 0) + 1;
          totalIntensity += log.intensityScore;

          if (freq[log.emotionType]! > maxCount) {
            maxCount = freq[log.emotionType]!;
            mostFrequent = log.emotionType;
          }
        }

        _currentInsight = EmotionInsight(
          mostFrequentEmotion: mostFrequent,
          emotionFrequencies: freq,
          averageIntensity: totalIntensity / logs.length,
          trendSummary:
              'Your mood has mostly been $mostFrequent recently. Keep up the tracking!',
        );
      }
    } catch (e) {
      _errorMessage = "Failed to retrieve insights: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
