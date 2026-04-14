import 'package:flutter/material.dart';
import '../main.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        title: const Text('Weekly Insights', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 24)),
        centerTitle: true,
        backgroundColor: AppColors.creamLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TabButton(title: 'This Week', isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                _TabButton(title: 'Last Week', isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                _TabButton(title: 'This Month', isSelected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
              ],
            ),
            const SizedBox(height: 32),

            // Big Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0A0), // specific logic for light yellow
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('😊', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 24),
                  Text(
                    'Your mood has been mostly positive this week!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brownDark, height: 1.4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Keep up the great work!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.brownMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2x2 Grid of Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: const [
                _StatCard(value: '75%', label: 'Positive Moods'),
                _StatCard(value: '12', label: 'Mood Logs'),
                _StatCard(value: '8', label: 'Calm Days'),
                _StatCard(value: '3', label: 'Stress Days'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.golden : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.brownMedium,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6), // very light yellow/cream
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.golden)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.brownDark)),
        ],
      ),
    );
  }
}
