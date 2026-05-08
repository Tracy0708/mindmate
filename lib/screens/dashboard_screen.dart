import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../widgets/daily_checkin_dialog.dart';
import '../services/emotion_service.dart';
import 'emotion_tracking_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';
import 'activity_screen.dart';
import 'insights_screen.dart';

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
      Provider.of<GamificationViewModel>(context, listen: false).fetchUserStats();
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
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.golden);
                }
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.brownMedium);
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavigate,
            height: 65,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.golden), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights, color: AppColors.golden), label: 'Insights'),
              NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_month, color: AppColors.golden), label: 'Calendar'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: AppColors.golden), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.golden), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HOME TAB — redesigned with logical sections
// ═══════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final Function(int) onNavigate;
  const _HomeTab({required this.onNavigate});

  static const _emojiMap = {
    'Happy': '😊', 'Sad': '😢', 'Anxious': '😰',
    'Angry': '😠', 'Calm': '😌', 'Tired': '😴',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmotionViewModel, GamificationViewModel>(
      builder: (context, vm, gamVm, _) {
        final todaysMood = vm.todaysLog;
        final streak = vm.streak;
        final logCount = vm.logCount;
        final activities = vm.completedActivityCount;
        final points = gamVm.totalPoints;

        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.golden,
            onRefresh: () async {
              await vm.checkTodaysLog();
              await gamVm.fetchUserStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ─── 1. TODAY'S CHECK-IN ───
                _TodayCard(
                  mood: todaysMood,
                  streak: streak,
                  onLogMood: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmotionTrackingScreen())),
                ),
                const SizedBox(height: 28),

                // ─── 2. QUICK ACTIONS ───
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(
                    icon: Icons.air, label: 'Breathe', color: const Color(0xFF42A5F5),
                    onTap: () {
                      const a = RecommendedActivity(
                        title: 'Box Breathing', activityType: 'breathing', emoji: '🌬️', durationMinutes: 5,
                        description: 'Inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat to calm your nervous system.',
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.edit_note, label: 'Journal', color: const Color(0xFF66BB6A),
                    onTap: () {
                      const a = RecommendedActivity(
                        title: 'Guided Journaling', activityType: 'journaling', emoji: '📝', durationMinutes: 10,
                        description: 'Write about 3 things you\'re grateful for today.',
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.self_improvement, label: 'Meditate', color: const Color(0xFFAB47BC),
                    onTap: () {
                      const a = RecommendedActivity(
                        title: 'Mindful Body Scan', activityType: 'meditation', emoji: '🧘', durationMinutes: 5,
                        description: 'A gentle meditation to check in with your body and release tension.',
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen(activity: a)));
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.chat_bubble_outline, label: 'Chat', color: const Color(0xFFFF7043),
                    onTap: () => onNavigate(3),
                  ),
                ]),
                const SizedBox(height: 28),

                // ─── 3. YOUR PROGRESS ───
                const Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    Row(children: [
                      _StatTile(icon: Icons.local_fire_department, value: '$streak', label: 'Streak', color: const Color(0xFFFF5722)),
                      _StatTile(icon: Icons.edit_calendar, value: '$logCount', label: 'Mood Logs', color: AppColors.golden),
                      _StatTile(icon: Icons.spa, value: '$activities', label: 'Activities', color: const Color(0xFF66BB6A)),
                      _StatTile(icon: Icons.star, value: '$points', label: 'Points', color: const Color(0xFFAB47BC)),
                    ]),
                    const SizedBox(height: 20),
                    // Combined progress bar — mood logging
                    _ProgressRow(label: 'Mood Logging', value: logCount, target: 30, unit: 'days'),
                    const SizedBox(height: 14),
                    _ProgressRow(label: 'Self-Care Activities', value: activities, target: 10, unit: 'completed'),
                  ]),
                ),
                const SizedBox(height: 28),

                // ─── 4. RECENT MOODS (last 5 days) ───
                if (vm.recentLogs.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Moods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                      GestureDetector(
                        onTap: () => onNavigate(2),
                        child: const Text('See Calendar →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.golden)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.recentLogs.length.clamp(0, 7),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final log = vm.recentLogs[index];
                        final emoji = _emojiMap[log.emotionType] ?? '🙂';
                        final isToday = _isToday(log.timestamp);
                        return Container(
                          width: 64, padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.golden.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isToday ? AppColors.golden : AppColors.golden.withOpacity(0.15), width: isToday ? 2 : 1),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              isToday ? 'Today' : _shortDay(log.timestamp),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isToday ? AppColors.golden : AppColors.brownMedium),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _shortDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

// ─── TODAY'S CHECK-IN CARD ───
class _TodayCard extends StatelessWidget {
  final dynamic mood; // EmotionLog?
  final int streak;
  final VoidCallback onLogMood;

  const _TodayCard({required this.mood, required this.streak, required this.onLogMood});

  @override
  Widget build(BuildContext context) {
    final isLogged = mood != null;
    const emojiMap = {'Happy': '😊', 'Sad': '😢', 'Anxious': '😰', 'Angry': '😠', 'Calm': '😌', 'Tired': '😴'};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLogged
              ? [AppColors.golden.withOpacity(0.12), AppColors.golden.withOpacity(0.04)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFFDF5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.golden.withOpacity(0.2)),
      ),
      child: isLogged
          ? Row(children: [
              Text(emojiMap[mood.emotionType] ?? '🙂', style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("You're feeling ${mood.emotionType}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 4),
                if (mood.notes != null && mood.notes!.isNotEmpty)
                  Text('"${mood.notes}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.brownMedium, fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_fire_department, size: 14, color: AppColors.golden),
                      const SizedBox(width: 4),
                      Text('$streak day streak', style: const TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                  ),
              ])),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
              ),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('👋', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              const Text("How are you feeling today?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
              const SizedBox(height: 6),
              const Text("Take a moment to check in with yourself", style: TextStyle(fontSize: 14, color: AppColors.brownMedium)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: onLogMood,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Log Your Mood', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDark)),
          ]),
        ),
      ),
    );
  }
}

// ─── STAT TILE (inside progress card) ───
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.brownMedium, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── PROGRESS ROW (label + animated bar + count) ───
class _ProgressRow extends StatelessWidget {
  final String label;
  final int value, target;
  final String unit;
  const _ProgressRow({required this.label, required this.value, required this.target, required this.unit});

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brownDark)),
        Text('$value/$target $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownMedium)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(children: [
          Container(height: 10, decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.12), borderRadius: BorderRadius.circular(6))),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(height: 10, decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.golden, Color(0xFFFF8F00)]),
              borderRadius: BorderRadius.circular(6),
            )),
          ),
        ]),
      ),
    ]);
  }
}
