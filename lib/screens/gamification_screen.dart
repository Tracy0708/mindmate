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
        ];

        return Scaffold(
          backgroundColor: AppColors.creamLight,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: AppColors.golden),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Badge Center', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 20)),
                    Text('Unlock achievements on your journey', style: TextStyle(color: AppColors.brownMedium.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          body: gamVm.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.golden))
              : RefreshIndicator(
                  color: AppColors.golden,
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
                              colors: [AppColors.golden, Color(0xFFFF8F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.golden.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$totalPoints',
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text('Achievement Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
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
      } else {
        d = Icons.nightlight_round;
        c = unlocked ? const Color(0xFF7C4DFF) : const Color(0xFF9E9E9E);
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.golden.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
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
        border: Border.all(color: unlocked ? AppColors.golden.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.golden.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getIcon(),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: unlocked ? AppColors.brownDark : Colors.grey)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.brownMedium)),
          const SizedBox(height: 8),
          // Progress text
          Text(
            progress,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: unlocked ? const Color(0xFF4CAF50) : AppColors.brownLight,
            ),
          ),
        ],
      ),
    );
  }
}
