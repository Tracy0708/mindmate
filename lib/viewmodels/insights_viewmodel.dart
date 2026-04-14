import 'package:flutter/material.dart';
import '../models/emotion_insight.dart';
import '../services/emotion_service.dart';

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
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      _currentInsight = await _emotionService.getEmotionSummary(lastWeek, now);
    } catch (e) {
      _errorMessage = "Failed to retrieve insights: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
