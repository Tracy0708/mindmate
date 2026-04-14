import 'package:flutter/material.dart';
import '../main.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: AppColors.golden,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.golden.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Column(
                children: [
                  Text('1,200', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Achievement Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: const [
                _BadgeCard(iconType: 'trophy', title: 'Streak Master', label: '30-day streak', unlocked: true),
                _BadgeCard(iconType: 'target', title: 'Goal Setter', label: 'Completed 10 goals', unlocked: true),
                _BadgeCard(iconType: 'star', title: 'Early Bird', label: 'Log before 8am', unlocked: false),
                _BadgeCard(iconType: 'moon', title: 'Night Owl', label: 'Log after midnight', unlocked: false),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String iconType;
  final String title;
  final String label;
  final bool unlocked;

  const _BadgeCard({
    required this.iconType,
    required this.title,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    Widget getIcon() {
      // Very basic mockup of the 3D-ish icons
      IconData d; Color c;
      if (iconType == 'trophy') { d = Icons.emoji_events; c = const Color(0xFFFFB300); }
      else if (iconType == 'target') { d = Icons.ads_click; c = const Color(0xFFE91E63); }
      else if (iconType == 'star') { d = Icons.star; c = const Color(0xFF9E9E9E); }
      else { d = Icons.nightlight_round; c = const Color(0xFF9E9E9E); }
      
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
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.golden.withOpacity(unlocked ? 0.2 : 0.05)),
        boxShadow: unlocked ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getIcon(),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: unlocked ? AppColors.golden : Colors.grey)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.brownMedium)),
        ],
      ),
    );
  }
}
