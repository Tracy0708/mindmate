class EmotionInsight {
  final String mostFrequentEmotion;
  final Map<String, int> emotionFrequencies;
  final double averageIntensity;
  final String trendSummary;

  // Chart data
  final List<DailyMoodScore> dailyScores;

  // Summary counts
  final int totalLogs;
  final int positiveDays;
  final int negativeDays;

  // Trend
  final String trendDirection; // 'improving', 'declining', 'stable'

  // Suggestions
  final List<InsightSuggestion> suggestions;

  EmotionInsight({
    required this.mostFrequentEmotion,
    required this.emotionFrequencies,
    required this.averageIntensity,
    required this.trendSummary,
    this.dailyScores = const [],
    this.totalLogs = 0,
    this.positiveDays = 0,
    this.negativeDays = 0,
    this.trendDirection = 'stable',
    this.suggestions = const [],
  });
}

/// A single day's aggregated mood score for the line chart
class DailyMoodScore {
  final DateTime date;
  final double score; // 1.0 - 5.0

  const DailyMoodScore({required this.date, required this.score});
}

/// An actionable suggestion based on mood patterns
class InsightSuggestion {
  final String title;
  final String description;
  final String icon; // emoji
  final String actionType; // 'breathing', 'journaling', 'chatbot', 'meditation'

  const InsightSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionType,
  });
}
