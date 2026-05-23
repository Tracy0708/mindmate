import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../viewmodels/emotion_viewmodel.dart';

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
        final logCount = emotionVm.logCount;

        // Determine badge unlock status based on real data
        final badges = [
          _BadgeData(
            iconType: 'trophy',
            title: 'Streak Master',
            label: '7-day streak',
            unlocked: streak >= 7,
            progress: '${streak.clamp(0, 7)}/7 days',
          ),
          _BadgeData(
            iconType: 'target',
            title: 'Goal Setter',
            label: 'Log 10 moods',
            unlocked: logCount >= 10,
            progress: '${logCount.clamp(0, 10)}/10 logs',
          ),
          _BadgeData(
            iconType: 'star',
            title: 'Consistent',
            label: 'Log 30 moods',
            unlocked: logCount >= 30,
            progress: '${logCount.clamp(0, 30)}/30 logs',
          ),
          _BadgeData(
            iconType: 'moon',
            title: 'Dedicated',
            label: '30-day streak',
            unlocked: streak >= 30,
            progress: '${streak.clamp(0, 30)}/30 days',
          ),
          _BadgeData(
            iconType: 'first',
            title: 'First Step',
            label: 'Log 1 mood',
            unlocked: logCount >= 1,
            progress: '${logCount.clamp(0, 1)}/1 logs',
          ),
          _BadgeData(
            iconType: 'activity',
            title: 'Beginner',
            label: '1 activity',
            unlocked: emotionVm.completedActivityCount >= 1,
            progress: '${emotionVm.completedActivityCount.clamp(0, 1)}/1 acts',
          ),
          _BadgeData(
            iconType: 'activity',
            title: 'Pro',
            label: '10 activities',
            unlocked: emotionVm.completedActivityCount >= 10,
            progress: '${emotionVm.completedActivityCount.clamp(0, 10)}/10 acts',
          ),
          _BadgeData(
            iconType: 'zen',
            title: 'Zen Master',
            label: '5 breathing',
            unlocked: emotionVm.breathingSessionCount >= 5,
            progress: '${emotionVm.breathingSessionCount.clamp(0, 5)}/5 acts',
          ),
        ];

        return Scaffold(
          backgroundColor: AppColors.creamLight,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Badge Center', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
                    Text('Unlock achievements on your journey', style: TextStyle(color: AppColors.textMedium.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          body: gamVm.isLoading
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
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
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
                                  _QuickStat(icon: Icons.edit_note, value: '$logCount', label: 'Logs'),
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
                            childAspectRatio: 0.82,
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
      IconData d;
      Color c;
      if (iconType == 'trophy') {
        d = Icons.emoji_events;
        c = unlocked ? const Color(0xFFFFB300) : const Color(0xFF9E9E9E);
      } else if (iconType == 'target') {
        d = Icons.ads_click;
        c = unlocked ? const Color(0xFFE91E63) : const Color(0xFF9E9E9E);
      } else if (iconType == 'star') {
        d = Icons.star;
        c = unlocked ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E);
      } else if (iconType == 'first') {
        d = Icons.favorite;
        c = unlocked ? const Color(0xFFF44336) : const Color(0xFF9E9E9E);
      } else if (iconType == 'activity') {
        d = Icons.spa;
        c = unlocked ? const Color(0xFF009688) : const Color(0xFF9E9E9E);
      } else if (iconType == 'zen') {
        d = Icons.air;
        c = unlocked ? const Color(0xFF03A9F4) : const Color(0xFF9E9E9E);
      } else {
        d = Icons.nightlight_round;
        c = unlocked ? const Color(0xFF7C4DFF) : const Color(0xFF9E9E9E);
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(d, size: 36, color: c),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? AppColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getIcon(),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: unlocked ? AppColors.textDark : Colors.grey)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 8),
          // Progress text
          Text(
            progress,
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
