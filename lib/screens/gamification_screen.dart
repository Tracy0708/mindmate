import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/badge_catalog.dart';
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

        // Determine badge unlock status from the shared catalog so the Badge
        // Center and the dashboard always agree.
        final badges = evaluateBadges(
          streak: streak,
          totalLogs: totalLogs,
          activityCount: actCount,
          breathingCount: breathing,
        );

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
                              icon: badge.icon,
                              color: badge.color,
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
  final IconData icon;
  final Color color;
  final String title;
  final String label;
  final bool unlocked;
  final String progress;

  const _BadgeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.label,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Widget getIcon() {
      final c = unlocked ? color : const Color(0xFF9E9E9E);
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 30, color: c),
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
