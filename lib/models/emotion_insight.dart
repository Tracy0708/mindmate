class EmotionInsight {
  final String mostFrequentEmotion;
  final Map<String, int> emotionFrequencies;
  final double averageIntensity;
  final String trendSummary;

  EmotionInsight({
    required this.mostFrequentEmotion,
    required this.emotionFrequencies,
    required this.averageIntensity,
    required this.trendSummary,
  });
}
