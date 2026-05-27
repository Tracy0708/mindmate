import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';
import 'dart:async';
import '../main.dart';
import '../services/auth_service.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../models/gamification_history.dart';
import '../widgets/daily_checkin_dialog.dart';
import '../widgets/app_emoji.dart';
import '../services/emotion_service.dart';
import 'emotion_tracking_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';
import 'activity_screen.dart';
import 'insights_screen.dart';
import 'gamification_screen.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/notification_bell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _checkinShown = false;

  void _onNavigate(int index) => setState(() => _selectedIndex = index);
  void navigateToTab(int index) => _onNavigate(index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyEmotion();
      final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
      gamVm.fetchUserStats();
      gamVm.fetchHistory();
    });
  }

  Future<void> _checkDailyEmotion() async {
    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    await vm.checkTodaysLog();
    if (mounted && !vm.hasLoggedToday && !_checkinShown) {
      _checkinShown = true;
      DailyCheckinDialog.show(context,
        onCompleted: () => vm.checkTodaysLog(),
        onSkipped: () {},
        onOpenChat: () => navigateToTab(3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(onNavigate: _onNavigate),
          const InsightsScreen(),
          const CalendarScreen(),
          const ChatbotScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
                }
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textMedium);
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavigate,
            height: 65,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights, color: AppColors.primary), label: 'Insights'),
              NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary), label: 'Calendar'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.primary), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  final Function(int) onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _emojiMap = {
    'Happy': '😊', 'Sad': '😢', 'Anxious': '😰',
    'Angry': '😠', 'Calm': '😌', 'Tired': '😴',
  };

  final AuthService _authService = AuthService();
  String _userName = 'MindMate';
  StreamSubscription<DocumentSnapshot>? _profileSub;

  @override
  void initState() {
    super.initState();
    _subscribeToUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
      gamVm.fetchHistory();
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _subscribeToUserName() {
    final user = _authService.currentUser;
    if (user == null) return;
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      final name = (data?['userName'] as String?)?.trim() ?? '';
      setState(() {
        _userName = name.isNotEmpty ? name : (user.displayName ?? 'MindMate');
      });
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmotionViewModel, GamificationViewModel>(
      builder: (context, vm, gamVm, _) {
        final todaysMood = vm.todaysLog;
        final streak = vm.streak;
        final logCount = vm.logCount;
        final activities = vm.completedActivityCount;
        final points = gamVm.totalPoints;

        // Badge count from real data
        final unlockedBadges = [
          streak >= 7, logCount >= 10, logCount >= 30, streak >= 30,
          logCount >= 1, activities >= 1, activities >= 10,
          vm.breathingSessionCount >= 5,
        ].where((b) => b).length;

        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await vm.checkTodaysLog();
              await gamVm.fetchUserStats();
              await gamVm.fetchHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── GREETING HEADER ──
                AppScreenHeader(
                  padding: EdgeInsets.zero,
                  eyebrow: '$_greeting 👋',
                  title: _userName,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.local_fire_department, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text('$streak day${streak == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const NotificationBell(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── SECTION 1: EMOJI DAILY LOG ──
                _TodayCard(
                  mood: todaysMood,
                  streak: streak,
                  emojiMap: _emojiMap,
                  onLogMood: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmotionTrackingScreen(onOpenChat: () => widget.onNavigate(3)))),
                ),
                const SizedBox(height: 24),

                // ── SECTION 2: OVERALL GAMIFICATION DISPLAY ──
                _GamificationHeroCard(
                  points: points,
                  streak: streak,
                  badges: unlockedBadges,
                  activities: activities,
                ),
                const SizedBox(height: 24),

                // ── SECTION 3: BADGE CENTER ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Badge Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                    child: const Text('See All →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ]),
                const SizedBox(height: 14),
                _BadgeMiniRow(streak: streak, logCount: logCount, activities: activities, breathing: vm.breathingSessionCount),
                const SizedBox(height: 24),

                // ── SECTION 4: SELF CARE ACTIVITIES ──
                const Text('Self Care Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(icon: Icons.air, label: 'Breathe', color: const Color(0xFF42A5F5), onTap: () {
                    const a = RecommendedActivity(title: 'Box Breathing', activityType: 'breathing', emoji: '🌬️', durationMinutes: 5, description: 'Inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat to calm your nervous system.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.edit_note, label: 'Journal', color: const Color(0xFF66BB6A), onTap: () {
                    const a = RecommendedActivity(title: 'Guided Journaling', activityType: 'journaling', emoji: '📝', durationMinutes: 10, description: 'Write about 3 things you\'re grateful for today.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.spa, label: 'Relax', color: const Color(0xFFFF7043), onTap: () {
                    const a = RecommendedActivity(title: 'Progressive Muscle Relaxation', activityType: 'relaxation', emoji: '💆', durationMinutes: 8, description: 'Tense and release each muscle group to let go of physical tension. Start from your toes and work up to your head.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _QuickAction(icon: Icons.self_improvement, label: 'Meditate', color: const Color(0xFFAB47BC), onTap: () {
                    const a = RecommendedActivity(title: 'Mindful Body Scan', activityType: 'meditation', emoji: '🧘', durationMinutes: 5, description: 'A gentle meditation to check in with your body and release tension.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.favorite, label: 'Gratitude', color: const Color(0xFF26A69A), onTap: () {
                    const a = RecommendedActivity(title: 'Gratitude Reflection', activityType: 'gratitude', emoji: '🙏', durationMinutes: 5, description: 'You\'re in a wonderful state of calm. Take a moment to appreciate this feeling and note what contributed to it.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.star, label: 'Affirm', color: const Color(0xFFFFB300), onTap: () {
                    const a = RecommendedActivity(title: 'Positive Affirmations', activityType: 'affirmations', emoji: '✨', durationMinutes: 3, description: 'Reinforce your well-being with uplifting statements. Read each one slowly and let it sink in.');
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                  }),
                ]),
                const SizedBox(height: 24),

                // ── SECTION 5: HISTORY FEED ──
                const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 14),
                _HistoryFeed(history: gamVm.history, recentLogs: vm.recentLogs, emojiMap: _emojiMap),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ─── GAMIFICATION HERO CARD ───
class _GamificationHeroCard extends StatelessWidget {
  final int points, streak, badges, activities;
  const _GamificationHeroCard({required this.points, required this.streak, required this.badges, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFFCC4D)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.textDark.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, color: AppColors.textDark, size: 20)),
          const SizedBox(width: 10),
          const Text('Your Achievements', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _HeroStat(icon: Icons.star_rounded, value: '$points', label: 'Points', iconColor: Colors.white),
          _VertDivider(),
          _HeroStat(icon: Icons.local_fire_department, value: '$streak', label: 'Streak', iconColor: const Color(0xFFFFE082)),
          _VertDivider(),
          _HeroStat(icon: Icons.workspace_premium, value: '$badges', label: 'Badges', iconColor: const Color(0xFFB3E5FC)),
          _VertDivider(),
          _HeroStat(icon: Icons.spa, value: '$activities', label: 'Activities', iconColor: const Color(0xFFC8E6C9)),
        ]),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: AppColors.textMedium.withValues(alpha: 0.25));
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color iconColor;
  const _HeroStat({required this.icon, required this.value, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 22)),
      Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─── BADGE MINI ROW ───
class _BadgeMiniRow extends StatelessWidget {
  final int streak, logCount, activities, breathing;
  const _BadgeMiniRow({required this.streak, required this.logCount, required this.activities, required this.breathing});

  @override
  Widget build(BuildContext context) {
    final badges = [
      _MiniBadgeData(icon: Icons.emoji_events,    label: 'Streak\nMaster',     unlocked: streak >= 7,      color: const Color(0xFFFFB300)),
      _MiniBadgeData(icon: Icons.favorite,         label: 'First\nStep',        unlocked: logCount >= 1,    color: const Color(0xFFF44336)),
      _MiniBadgeData(icon: Icons.ads_click,        label: 'Goal\nSetter',       unlocked: logCount >= 10,   color: const Color(0xFFE91E63)),
      _MiniBadgeData(icon: Icons.star,             label: 'Consistent',         unlocked: logCount >= 30,   color: const Color(0xFF4CAF50)),
      _MiniBadgeData(icon: Icons.nightlight_round, label: 'Dedicated',          unlocked: streak >= 30,     color: const Color(0xFF7C4DFF)),
      _MiniBadgeData(icon: Icons.spa,              label: 'Beginner',           unlocked: activities >= 1,  color: const Color(0xFF009688)),
      _MiniBadgeData(icon: Icons.spa,              label: 'Pro',                unlocked: activities >= 10, color: const Color(0xFF009688)),
      _MiniBadgeData(icon: Icons.air,              label: 'Zen\nMaster',        unlocked: breathing >= 5,   color: const Color(0xFF03A9F4)),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final b = badges[i];
          return Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: b.unlocked ? Colors.white : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: b.unlocked ? b.color.withOpacity(0.4) : Colors.grey.withOpacity(0.1)),
              boxShadow: b.unlocked ? [BoxShadow(color: b.color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(b.icon, size: 26, color: b.unlocked ? b.color : Colors.grey.shade400),
              const SizedBox(height: 6),
              Text(b.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: b.unlocked ? AppColors.textDark : Colors.grey, height: 1.2)),
            ]),
          );
        },
      ),
    );
  }
}

class _MiniBadgeData {
  final IconData icon;
  final String label;
  final bool unlocked;
  final Color color;
  const _MiniBadgeData({required this.icon, required this.label, required this.unlocked, required this.color});
}

// ─── TODAY'S CHECK-IN CARD ───
class _TodayCard extends StatelessWidget {
  final dynamic mood;
  final int streak;
  final Map<String, String> emojiMap;
  final VoidCallback onLogMood;
  const _TodayCard({required this.mood, required this.streak, required this.emojiMap, required this.onLogMood});

  @override
  Widget build(BuildContext context) {
    final isLogged = mood != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLogged
              ? [AppColors.primary.withOpacity(0.12), AppColors.primary.withOpacity(0.04)]
              : [AppColors.primaryLight, AppColors.cream],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: isLogged
          ? Row(children: [
              AppEmoji(emojiMap[mood.emotionType] ?? '🙂', size: 48),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("You're feeling ${mood.emotionType}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                if (mood.notes != null && mood.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"${mood.notes}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                  child: const Text('✅ Logged today', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ])),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
              ),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How are you feeling today?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 6),
              const Text('Take a moment to check in with yourself', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLogMood,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    AppEmoji('😊', size: 18),
                    SizedBox(width: 8),
                    Text('Log My Mood', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ]),
                ),
              ),
            ]),
    );
  }
}

// ─── QUICK ACTION BUTTON ───
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ]),
        ),
      ),
    );
  }
}

// ─── HISTORY FEED ───
class _HistoryFeed extends StatelessWidget {
  final List<GamificationHistory> history;
  final List<dynamic> recentLogs;
  final Map<String, String> emojiMap;
  const _HistoryFeed({required this.history, required this.recentLogs, required this.emojiMap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  _HistoryItemData _buildItem(GamificationHistory h) {
    final type = h.metadata['type'] as String? ?? '';
    switch (type) {
      case 'mood_log':
        return _HistoryItemData(icon: Icons.mood, color: const Color(0xFF42A5F5), title: 'Mood Logged', subtitle: '+${h.pointsEarned} pts', time: _timeAgo(h.achievementTimestamp));
      case 'activity':
        final act = h.metadata['activity'] as String? ?? h.achievement;
        return _HistoryItemData(icon: Icons.spa, color: const Color(0xFF66BB6A), title: act.replaceAll('Activity Completed: ', ''), subtitle: '+${h.pointsEarned} pts', time: _timeAgo(h.achievementTimestamp));
      case 'milestone':
      case 'streak':
        return _HistoryItemData(icon: Icons.emoji_events, color: const Color(0xFFFFB300), title: h.achievement, subtitle: '+${h.pointsEarned} pts 🏅', time: _timeAgo(h.achievementTimestamp));
      case 'profile_update':
        return _HistoryItemData(icon: Icons.person, color: const Color(0xFFAB47BC), title: 'Profile Updated', subtitle: 'Info updated', time: _timeAgo(h.achievementTimestamp));
      case 'purchase':
        return _HistoryItemData(icon: Icons.storefront, color: const Color(0xFFFF7043), title: h.achievement, subtitle: '${h.pointsEarned} pts', time: _timeAgo(h.achievementTimestamp));
      default:
        return _HistoryItemData(icon: Icons.star, color: AppColors.primary, title: h.achievement, subtitle: h.pointsEarned > 0 ? '+${h.pointsEarned} pts' : '', time: _timeAgo(h.achievementTimestamp));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Center(child: Column(children: [
          AppEmoji('🌱', size: 36),
          SizedBox(height: 10),
          Text('Your activity will appear here', style: TextStyle(color: AppColors.textMedium, fontSize: 14)),
          Text('Start logging moods or doing activities!', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        ])),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length > 5 ? 5 : history.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.fieldBorder.withOpacity(0.5), indent: 68),
        itemBuilder: (_, i) {
          final item = _buildItem(history[i]);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: item.color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (item.subtitle.isNotEmpty) TwemojiText(text: item.subtitle, style: TextStyle(fontSize: 12, color: item.color, fontWeight: FontWeight.w600)),
              ])),
              Text(item.time, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ]),
          );
        },
      ),
    );
  }
}

class _HistoryItemData {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _HistoryItemData({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});
}
