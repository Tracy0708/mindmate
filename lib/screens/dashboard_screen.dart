import 'package:flutter/material.dart';
import '../main.dart';
import 'emotion_tracking_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  void _onNavigate(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(onNavigate: _onNavigate),
          const EmotionTrackingScreen(),
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
              NavigationDestination(icon: Icon(Icons.add), selectedIcon: Icon(Icons.add, color: AppColors.golden), label: 'Log Mood'),
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

// ─── HOME TAB (Activity Progress) ───
class _HomeTab extends StatelessWidget {
  final Function(int) onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.bolt, color: AppColors.golden, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('Activity Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.golden)),
              ],
            ),
            const SizedBox(height: 32),

            // Daily Mood Log Card
            _ActivityCard(
              title: 'Daily Mood Log',
              subtitle: "Today's mood not yet logged",
              actionLabel: '+ Log Mood',
              progressWidth: 0.8,
              progressLabel: '8/10 days',
              extraWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: AppColors.golden),
                    SizedBox(width: 4),
                    Text('8 day streak', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              onAction: () => onNavigate(1),
            ),
            const SizedBox(height: 24),

            // Breathing Exercises Card
            _ActivityCard(
              title: 'Breathing Exercises',
              subtitle: 'Last session: 2 hours ago',
              actionLabel: '► Start Session',
              progressWidth: 0.4,
              progressLabel: '4/10 sessions',
              onAction: () {},
            ),
            const SizedBox(height: 24),

            // Self-Care Goals Card
            _ActivityCard(
              title: 'Self-Care Goals',
              subtitle: '3 tasks remaining today',
              actionLabel: '≡ View Goals',
              progressWidth: 0.5,
              progressLabel: '5/10 goals',
              onAction: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title, subtitle, actionLabel, progressLabel;
  final double progressWidth;
  final Widget? extraWidget;
  final VoidCallback onAction;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.progressLabel,
    required this.progressWidth,
    this.extraWidget,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.golden)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.brownMedium)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          Stack(
            children: [
              Container(height: 14, decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.15), borderRadius: BorderRadius.circular(7))),
              FractionallySizedBox(
                widthFactor: progressWidth,
                child: Container(height: 14, decoration: BoxDecoration(color: AppColors.golden, borderRadius: BorderRadius.circular(7))),
              )
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(progressLabel, style: const TextStyle(fontSize: 12, color: AppColors.brownMedium)),
          ),
          if (extraWidget != null) ...[
            const SizedBox(height: 8),
            extraWidget!,
          ]
        ],
      ),
    );
  }
}
