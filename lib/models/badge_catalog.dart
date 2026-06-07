import 'package:flutter/material.dart';

/// Single source of truth for the gamification badges shown across the app
/// (the Badge Center grid and the dashboard hero count / mini-row). Keeping one
/// catalog avoids the screens drifting out of sync on thresholds or counts.
enum BadgeCategory { logs, streak, activity, breathing }

class BadgeDef {
  final String title; // short name, e.g. 'Goal Setter'
  final String label; // requirement, e.g. 'Log 10 moods'
  final IconData icon;
  final Color color;
  final int threshold;
  final int points; // awarded when unlocked
  final BadgeCategory category;

  const BadgeDef({
    required this.title,
    required this.label,
    required this.icon,
    required this.color,
    required this.threshold,
    required this.points,
    required this.category,
  });
}

/// A badge plus its computed state for a given user's counts.
class BadgeStatus {
  final BadgeDef def;
  final bool unlocked;
  final String progress; // e.g. '10/10 logs'
  const BadgeStatus(this.def, this.unlocked, this.progress);

  String get title => def.title;
  String get label => def.label;
  IconData get icon => def.icon;
  Color get color => def.color;
  int get points => def.points;
}

/// The canonical ordered badge list. Mirrors the award logic in
/// GamificationViewModel (same titles + thresholds).
const List<BadgeDef> kBadgeCatalog = [
  // ── Mood-log tiers ──
  BadgeDef(title: 'First Step', label: 'Log 1 mood', icon: Icons.favorite, color: Color(0xFFF44336), threshold: 1, points: 50, category: BadgeCategory.logs),
  BadgeDef(title: 'Goal Setter', label: 'Log 10 moods', icon: Icons.ads_click, color: Color(0xFFE91E63), threshold: 10, points: 100, category: BadgeCategory.logs),
  BadgeDef(title: 'Consistent', label: 'Log 30 moods', icon: Icons.star, color: Color(0xFF4CAF50), threshold: 30, points: 250, category: BadgeCategory.logs),
  BadgeDef(title: 'Committed', label: 'Log 50 moods', icon: Icons.verified, color: Color(0xFF00897B), threshold: 50, points: 400, category: BadgeCategory.logs),
  BadgeDef(title: 'Century Logger', label: 'Log 100 moods', icon: Icons.auto_awesome, color: Color(0xFFFFA000), threshold: 100, points: 750, category: BadgeCategory.logs),

  // ── Streak tiers ──
  BadgeDef(title: 'Getting Started', label: '3-day streak', icon: Icons.bolt, color: Color(0xFFFFC107), threshold: 3, points: 30, category: BadgeCategory.streak),
  BadgeDef(title: 'Streak Master', label: '7-day streak', icon: Icons.emoji_events, color: Color(0xFFFFB300), threshold: 7, points: 70, category: BadgeCategory.streak),
  BadgeDef(title: 'Two Weeks Strong', label: '14-day streak', icon: Icons.calendar_month, color: Color(0xFF5E35B1), threshold: 14, points: 140, category: BadgeCategory.streak),
  BadgeDef(title: 'Dedicated', label: '30-day streak', icon: Icons.nightlight_round, color: Color(0xFF7C4DFF), threshold: 30, points: 300, category: BadgeCategory.streak),
  BadgeDef(title: 'Centurion', label: '100-day streak', icon: Icons.shield, color: Color(0xFF3949AB), threshold: 100, points: 1000, category: BadgeCategory.streak),
  BadgeDef(title: 'Yearly Champion', label: '365-day streak', icon: Icons.workspace_premium, color: Color(0xFFD81B60), threshold: 365, points: 3650, category: BadgeCategory.streak),

  // ── Activity tiers ──
  BadgeDef(title: 'Beginner', label: '1 activity', icon: Icons.spa, color: Color(0xFF009688), threshold: 1, points: 50, category: BadgeCategory.activity),
  BadgeDef(title: 'Pro', label: '5 activities', icon: Icons.self_improvement, color: Color(0xFF43A047), threshold: 5, points: 150, category: BadgeCategory.activity),
  BadgeDef(title: 'Enthusiast', label: '10 activities', icon: Icons.fitness_center, color: Color(0xFFFB8C00), threshold: 10, points: 300, category: BadgeCategory.activity),
  BadgeDef(title: 'Champion', label: '25 activities', icon: Icons.military_tech, color: Color(0xFFFFB300), threshold: 25, points: 600, category: BadgeCategory.activity),

  // ── Breathing ──
  BadgeDef(title: 'Zen Master', label: '5 breathing', icon: Icons.air, color: Color(0xFF03A9F4), threshold: 5, points: 150, category: BadgeCategory.breathing),
];

/// Evaluate the whole catalog against the user's current counts. Used by both
/// the Badge Center and the dashboard so the unlocked set is always identical.
List<BadgeStatus> evaluateBadges({
  required int streak,
  required int totalLogs,
  required int activityCount,
  required int breathingCount,
}) {
  int countFor(BadgeCategory c) {
    switch (c) {
      case BadgeCategory.logs:
        return totalLogs;
      case BadgeCategory.streak:
        return streak;
      case BadgeCategory.activity:
        return activityCount;
      case BadgeCategory.breathing:
        return breathingCount;
    }
  }

  String unitFor(BadgeCategory c) {
    switch (c) {
      case BadgeCategory.logs:
        return 'logs';
      case BadgeCategory.streak:
        return 'days';
      case BadgeCategory.activity:
      case BadgeCategory.breathing:
        return 'acts';
    }
  }

  return kBadgeCatalog.map((def) {
    final count = countFor(def.category);
    final progress =
        '${count.clamp(0, def.threshold)}/${def.threshold} ${unitFor(def.category)}';
    return BadgeStatus(def, count >= def.threshold, progress);
  }).toList();
}
