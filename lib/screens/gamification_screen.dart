import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../widgets/app_screen_header.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GamificationViewModel>(context, listen: false).fetchUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GamificationViewModel, EmotionViewModel>(
      builder: (context, gamVm, emotionVm, _) {
        final totalPoints = gamVm.totalPoints;
        final streak = emotionVm.streak;
        final totalLogs = emotionVm.totalLogCount;
        final actCount = emotionVm.completedActivityCount;
        final breathing = emotionVm.breathingSessionCount;

        // Determine badge unlock status based on real data.
        // Grouped by category: mood logs, streaks, activities, breathing.
        final badges = [
          // ── Mood-log tiers ──
          _BadgeData(
            iconType: 'first',
            title: 'First Step',
            label: 'Log 1 mood',
            unlocked: totalLogs >= 1,
            progress: '${totalLogs.clamp(0, 1)}/1 logs',
          ),
          _BadgeData(
            iconType: 'target',
            title: 'Goal Setter',
            label: 'Log 10 moods',
            unlocked: totalLogs >= 10,
            progress: '${totalLogs.clamp(0, 10)}/10 logs',
          ),
          _BadgeData(
            iconType: 'star',
            title: 'Consistent',
            label: 'Log 30 moods',
            unlocked: totalLogs >= 30,
            progress: '${totalLogs.clamp(0, 30)}/30 logs',
          ),
          _BadgeData(
            iconType: 'committed',
            title: 'Committed',
            label: 'Log 50 moods',
            unlocked: totalLogs >= 50,
            progress: '${totalLogs.clamp(0, 50)}/50 logs',
          ),
          _BadgeData(
            iconType: 'century',
            title: 'Century Logger',
            label: 'Log 100 moods',
            unlocked: totalLogs >= 100,
            progress: '${totalLogs.clamp(0, 100)}/100 logs',
          ),

          // ── Streak tiers ──
          _BadgeData(
            iconType: 'spark',
            title: 'Getting Started',
            label: '3-day streak',
            unlocked: streak >= 3,
            progress: '${streak.clamp(0, 3)}/3 days',
          ),
          _BadgeData(
            iconType: 'trophy',
            title: 'Streak Master',
            label: '7-day streak',
            unlocked: streak >= 7,
            progress: '${streak.clamp(0, 7)}/7 days',
          ),
          _BadgeData(
            iconType: 'fortnight',
            title: 'Two Weeks Strong',
            label: '14-day streak',
            unlocked: streak >= 14,
            progress: '${streak.clamp(0, 14)}/14 days',
          ),
          _BadgeData(
            iconType: 'moon',
            title: 'Dedicated',
            label: '30-day streak',
            unlocked: streak >= 30,
            progress: '${streak.clamp(0, 30)}/30 days',
          ),
          _BadgeData(
            iconType: 'centurion',
            title: 'Centurion',
            label: '100-day streak',
            unlocked: streak >= 100,
            progress: '${streak.clamp(0, 100)}/100 days',
          ),

          // ── Activity tiers ──
          _BadgeData(
            iconType: 'activity',
            title: 'Beginner',
            label: '1 activity',
            unlocked: actCount >= 1,
            progress: '${actCount.clamp(0, 1)}/1 acts',
          ),
          _BadgeData(
            iconType: 'pro',
            title: 'Pro',
            label: '5 activities',
            unlocked: actCount >= 5,
            progress: '${actCount.clamp(0, 5)}/5 acts',
          ),
          _BadgeData(
            iconType: 'enthusiast',
            title: 'Enthusiast',
            label: '10 activities',
            unlocked: actCount >= 10,
            progress: '${actCount.clamp(0, 10)}/10 acts',
          ),
          _BadgeData(
            iconType: 'champion',
            title: 'Champion',
            label: '25 activities',
            unlocked: actCount >= 25,
            progress: '${actCount.clamp(0, 25)}/25 acts',
          ),

          // ── Breathing ──
          _BadgeData(
            iconType: 'zen',
            title: 'Zen Master',
            label: '5 breathing',
            unlocked: breathing >= 5,
            progress: '${breathing.clamp(0, 5)}/5 acts',
          ),
        ];

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Column(
              children: [
                const AppScreenHeader(
                  title: 'Badge Center',
                  subtitle: 'Unlock achievements on your journey.',
                  icon: Icons.workspace_premium_rounded,
                  showBack: true,
                ),
                Expanded(
                  child: gamVm.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => gamVm.fetchUserStats(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Points card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFFCC4D)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$totalPoints',
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              const Text('Achievement Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 16),
                              // Quick stats row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _QuickStat(icon: Icons.local_fire_department, value: '$streak', label: 'Streak'),
                                  const SizedBox(width: 32),
                                  _QuickStat(icon: Icons.edit_note, value: '$totalLogs', label: 'Logs'),
                                  const SizedBox(width: 32),
                                  _QuickStat(icon: Icons.workspace_premium, value: '${badges.where((b) => b.unlocked).length}', label: 'Badges'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Badge grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: badges.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final badge = badges[index];
                            return _BadgeCard(
                              iconType: badge.iconType,
                              title: badge.title,
                              label: badge.label,
                              unlocked: badge.unlocked,
                              progress: badge.progress,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BadgeData {
  final String iconType;
  final String title;
  final String label;
  final bool unlocked;
  final String progress;

  const _BadgeData({
    required this.iconType,
    required this.title,
    required this.label,
    required this.unlocked,
    required this.progress,
  });
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textDark, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String iconType;
  final String title;
  final String label;
  final bool unlocked;
  final String progress;

  const _BadgeCard({
    required this.iconType,
    required this.title,
    required this.label,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Widget getIcon() {
      const iconData = {
        'trophy': Icons.emoji_events,
        'target': Icons.ads_click,
        'star': Icons.star,
        'first': Icons.favorite,
        'activity': Icons.spa,
        'zen': Icons.air,
        'moon': Icons.nightlight_round,
        'committed': Icons.verified,
        'century': Icons.auto_awesome,
        'spark': Icons.bolt,
        'fortnight': Icons.calendar_month,
        'centurion': Icons.shield,
        'pro': Icons.self_improvement,
        'enthusiast': Icons.fitness_center,
        'champion': Icons.military_tech,
      };
      const iconColors = {
        'trophy': Color(0xFFFFB300),
        'target': Color(0xFFE91E63),
        'star': Color(0xFF4CAF50),
        'first': Color(0xFFF44336),
        'activity': Color(0xFF009688),
        'zen': Color(0xFF03A9F4),
        'moon': Color(0xFF7C4DFF),
        'committed': Color(0xFF00897B),
        'century': Color(0xFFFFA000),
        'spark': Color(0xFFFFC107),
        'fortnight': Color(0xFF5E35B1),
        'centurion': Color(0xFF3949AB),
        'pro': Color(0xFF43A047),
        'enthusiast': Color(0xFFFB8C00),
        'champion': Color(0xFFFFB300),
      };
      final d = iconData[iconType] ?? Icons.nightlight_round;
      final c = unlocked ? (iconColors[iconType] ?? AppColors.primary) : const Color(0xFF9E9E9E);

      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(d, size: 30, color: c),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1)),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getIcon(),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: unlocked ? AppColors.textDark : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          // Progress text
          Text(
            progress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: unlocked ? const Color(0xFF4CAF50) : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
