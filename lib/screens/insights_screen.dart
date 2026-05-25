import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';
import '../main.dart';
import '../models/emotion_insight.dart';
import '../models/emotion_log.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../services/emotion_service.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_emoji.dart';
import 'activity_screen.dart';
import 'dashboard_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InsightsViewModel>(context, listen: false).fetchInsights();
    });
  }

  static const _emojiMap = {'Happy':'😊','Sad':'😢','Anxious':'😰','Angry':'😠','Calm':'😌','Tired':'😴'};
  static const _emotionColors = {
    'Happy': Color(0xFF4CAF50), 'Sad': Color(0xFF42A5F5), 'Anxious': Color(0xFFFF7043),
    'Angry': Color(0xFFE53935), 'Calm': Color(0xFF26A69A), 'Tired': Color(0xFF7E57C2),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<InsightsViewModel>(builder: (context, vm, _) {
      return Scaffold(
        backgroundColor: AppColors.creamLight,
        body: SafeArea(
          child: Column(
            children: [
              const AppScreenHeader(
                title: 'Insights',
                subtitle: 'Your mood, trends, and progress.',
              ),
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : vm.errorMessage != null
                        ? _errorView(vm)
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => vm.fetchInsights(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              child: _buildContent(vm),
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _errorView(InsightsViewModel vm) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off, size: 64, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(vm.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.textMedium)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => vm.fetchInsights(), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Retry', style: TextStyle(color: AppColors.textDark))),
      ],
    )));
  }

  Widget _buildContent(InsightsViewModel vm) {
    final insight = vm.currentInsight;
    if (insight == null) return const SizedBox.shrink();

    // EF1: No data
    if (insight.totalLogs == 0 && insight.mostFrequentEmotion == 'None') {
      return _emptyState();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 1. Date Range Tabs (AF1)
      _rangeTabs(vm),
      const SizedBox(height: 24),
      // 2. Trend Summary Card (NF3)
      _trendSummaryCard(insight),
      const SizedBox(height: 24),
      // 3. Mood Line Chart (NF4)
      if (insight.dailyScores.length >= 2) ...[
        _sectionHeader('Mood Over Time'),
        const SizedBox(height: 12),
        _moodLineChart(insight),
        const SizedBox(height: 24),
      ],
      // 4. Emotion Distribution (NF4)
      if (insight.emotionFrequencies.isNotEmpty) ...[
        _sectionHeader('Emotion Breakdown'),
        const SizedBox(height: 12),
        _emotionPieChart(insight),
        const SizedBox(height: 24),
      ],
      // 5. Stats Grid (NF3)
      _statsGrid(insight),
      const SizedBox(height: 24),
      // 6. Suggestions (NF6)
      if (insight.suggestions.isNotEmpty) ...[
        _sectionHeader('Suggestions For You'),
        const SizedBox(height: 12),
        ...insight.suggestions.map((s) => _suggestionCard(s)),
      ],
      const SizedBox(height: 24),
      // 7. Mood History Timeline (NF4, NF5)
      if (vm.logs.isNotEmpty) ...[
        _sectionHeader('Mood History'),
        const SizedBox(height: 12),
        ...vm.logs.take(10).map((log) => _timelineItem(log)),
      ],
    ]);
  }

  // ─── EMPTY STATE (EF1) ───
  Widget _emptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 80), child: Column(children: [
      Container(
        padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
        child: const Icon(Icons.insights, size: 64, color: AppColors.primary),
      ),
      const SizedBox(height: 24),
      const Text('No Insights Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 12),
      const Text('Start tracking your emotions to see\npersonalized insights and trends here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textMedium, height: 1.5)),
      const SizedBox(height: 32),
      ElevatedButton.icon(
        onPressed: () {
          context.findAncestorStateOfType<DashboardScreenState>()?.navigateToTab(0);
        },
        icon: const Icon(Icons.add, color: AppColors.textDark),
        label: const Text('Log Your First Mood', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ])));
  }

  // ─── RANGE TABS (AF1) ───
  Widget _rangeTabs(InsightsViewModel vm) {
    const tabs = [('week', 'Week'), ('month', 'Month'), ('3months', '3 Months')];
    return Row(children: tabs.map((t) {
      final isSelected = vm.selectedRange == t.$1;
      return Expanded(child: GestureDetector(
        onTap: () => vm.setRange(t.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(child: Text(t.$2, style: TextStyle(color: isSelected ? AppColors.textDark : AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14))),
        ),
      ));
    }).toList());
  }

  // ─── TREND SUMMARY (NF3) ───
  Widget _trendSummaryCard(EmotionInsight insight) {
    final emoji = _emojiMap[insight.mostFrequentEmotion] ?? '📊';
    IconData trendIcon; Color trendColor; String trendLabel;
    switch (insight.trendDirection) {
      case 'improving': trendIcon = Icons.trending_up; trendColor = const Color(0xFF4CAF50); trendLabel = 'Improving'; break;
      case 'declining': trendIcon = Icons.trending_down; trendColor = const Color(0xFFE53935); trendLabel = 'Declining'; break;
      default: trendIcon = Icons.trending_flat; trendColor = AppColors.primary; trendLabel = 'Stable';
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(children: [
        AppEmoji(emoji, size: 48),
        const SizedBox(height: 12),
        if (insight.mostFrequentEmotion != 'None')
          Text('Most frequent: ${insight.mostFrequentEmotion}', style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(insight.trendSummary, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.4)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: trendColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(trendIcon, size: 18, color: trendColor),
            const SizedBox(width: 6),
            Text(trendLabel, style: TextStyle(color: trendColor, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  // ─── MOOD LINE CHART (NF4) ───
  Widget _moodLineChart(EmotionInsight insight) {
    final scores = insight.dailyScores;
    final spots = <FlSpot>[];
    for (int i = 0; i < scores.length; i++) {
      spots.add(FlSpot(i.toDouble(), scores[i].score));
    }

    return Container(
      height: 220, padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: LineChart(LineChartData(
        minY: 0, maxY: 5.5,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.primary.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 30, interval: 1,
            getTitlesWidget: (v, _) {
              if (v == 1) return const Text('😠', style: TextStyle(fontSize: 12));
              if (v == 3) return const Text('😐', style: TextStyle(fontSize: 12));
              if (v == 5) return const Text('😊', style: TextStyle(fontSize: 12));
              return const SizedBox.shrink();
            },
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28, interval: _bottomInterval(scores.length),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= scores.length) return const SizedBox.shrink();
              return Text(DateFormat('d/M').format(scores[i].date), style: const TextStyle(fontSize: 10, color: AppColors.textMedium));
            },
          )),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, curveSmoothness: 0.3,
            color: AppColors.primary, barWidth: 3, dotData: FlDotData(show: scores.length <= 14),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.spotIndex;
              final date = i < scores.length ? DateFormat('MMM d').format(scores[i].date) : '';
              return LineTooltipItem('$date\nScore: ${s.y.toStringAsFixed(1)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12));
            }).toList(),
          ),
        ),
      )),
    );
  }

  double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return 10;
  }

  // ─── EMOTION PIE CHART (NF4) ───
  Widget _emotionPieChart(EmotionInsight insight) {
    final freq = insight.emotionFrequencies;
    final total = freq.values.fold(0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];
    freq.forEach((emotion, count) {
      final pct = (count / total * 100);
      sections.add(PieChartSectionData(
        value: count.toDouble(), title: '${pct.round()}%',
        color: _emotionColors[emotion] ?? Colors.grey, radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ));
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Center(child: SizedBox(height: 160, width: 160, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30, sectionsSpace: 2)))),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: freq.entries.map((e) {
            final color = _emotionColors[e.key] ?? Colors.grey;
            final emoji = _emojiMap[e.key] ?? '🙂';
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              TwemojiText(text: '$emoji ${e.key}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(width: 4),
              Text('${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  // ─── STATS GRID (NF3) ───
  Widget _statsGrid(EmotionInsight insight) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: [
        _statCard('${insight.totalLogs}', 'Total Logs', Icons.edit_note, const Color(0xFF42A5F5)),
        _statCard('${insight.positiveDays}', 'Positive Days', Icons.sentiment_satisfied, const Color(0xFF4CAF50)),
        _statCard(insight.averageIntensity.toStringAsFixed(1), 'Avg Score', Icons.speed, AppColors.primary),
        _statCard('${insight.negativeDays}', 'Tough Days', Icons.sentiment_dissatisfied, const Color(0xFFE53935)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
      ]),
    );
  }

  // ─── SUGGESTIONS (NF6) ───
  Widget _suggestionCard(InsightSuggestion s) {
    return GestureDetector(
      onTap: () => _launchSuggestion(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
        child: Row(children: [
          Text(s.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(s.description, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ]),
      ),
    );
  }

  void _launchSuggestion(InsightSuggestion s) {
    if (s.actionType == 'chatbot') {
      context.findAncestorStateOfType<DashboardScreenState>()?.navigateToTab(3);
      return;
    }
    if (s.actionType == 'none') return;

    final activityMap = {
      'breathing': const RecommendedActivity(title: 'Box Breathing', activityType: 'breathing', emoji: '🌬️', durationMinutes: 5, description: 'Inhale 4s, hold 4s, exhale 4s, hold 4s.'),
      'journaling': const RecommendedActivity(title: 'Guided Journaling', activityType: 'journaling', emoji: '📝', durationMinutes: 10, description: 'Write about 3 things you\'re grateful for.'),
      'meditation': const RecommendedActivity(title: 'Mindful Body Scan', activityType: 'meditation', emoji: '🧘', durationMinutes: 5, description: 'A gentle meditation to check in with your body.'),
      'relaxation': const RecommendedActivity(title: 'Progressive Relaxation', activityType: 'relaxation', emoji: '💆', durationMinutes: 5, description: 'Tense and release muscle groups to melt away stress.'),
      'affirmations': const RecommendedActivity(title: 'Positive Affirmations', activityType: 'affirmations', emoji: '✨', durationMinutes: 5, description: 'Reinforce your well-being with uplifting statements.'),
    };

    final activity = activityMap[s.actionType];
    if (activity != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityScreen(activity: activity)));
    }
  }

  // ─── MOOD HISTORY TIMELINE (NF5) ───
  Widget _timelineItem(EmotionLog log) {
    final emoji = _emojiMap[log.emotionType] ?? '🙂';
    final color = _emotionColors[log.emotionType] ?? Colors.grey;
    final time = DateFormat('MMM d, h:mm a').format(log.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: AppEmoji(emoji, size: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.emotionType, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          if (log.notes != null && log.notes!.isNotEmpty)
            Text(log.notes!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
        ])),
        Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark));
  }
}
