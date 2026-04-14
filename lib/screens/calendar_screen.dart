import 'package:flutter/material.dart';
import '../main.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mood Calendar', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 24)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All Moods', isSelected: true),
                    _FilterChip(icon: '😊', label: 'Happy', isSelected: false),
                    _FilterChip(icon: '😢', label: 'Sad', isSelected: false),
                    _FilterChip(icon: '😰', label: 'Anxious', isSelected: false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Month Selector
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left, color: AppColors.brownDark),
                  ),
                  const SizedBox(width: 16),
                  const Text('May 2025', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, color: AppColors.brownDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar Grid (Mockup for now)
              _buildCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => Text(d, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brownLight))).toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 35,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.8),
          itemBuilder: (context, index) {
            final day = index - 3; // Offset to start at 1
            if (day < 1 || day > 31) return Center(child: Text('${day < 1 ? day + 30 : day - 31}', style: const TextStyle(color: Color(0xFFE0E0E0))));
            
            // Mock some moods
            String? mood;
            if (day == 1 || day == 8 || day == 15 || day == 22) mood = '😊';
            if (day == 5 || day == 20) mood = '😌';
            if (day == 3) mood = '😢';
            if (day == 10) mood = '😰';
            if (day == 18) mood = '😤';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: day == 30 ? Border.all(color: AppColors.golden, width: 2) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: const TextStyle(color: AppColors.brownLight)),
                ),
                if (mood != null) Text(mood, style: const TextStyle(fontSize: 16)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String? icon;
  final String label;
  final bool isSelected;
  const _FilterChip({this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.golden : AppColors.golden.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Text(icon!), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.brownDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
