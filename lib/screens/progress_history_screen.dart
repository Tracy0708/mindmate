import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gamification_viewmodel.dart';

class ProgressHistoryScreen extends StatelessWidget {
  const ProgressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress History'),
      ),
      body: Consumer<GamificationViewModel>(
        builder: (context, vm, child) {
          final stats = vm.userStats;
          if (stats == null || stats['recentAchievements'] == null) {
            return const Center(child: Text("No history available."));
          }
          
          final List recent = stats['recentAchievements'];
          
          if (recent.isEmpty) {
            return const Center(child: Text("Start completing activities to see history."));
          }

          return ListView.builder(
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final item = recent[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.history),
                ),
                title: Text(item['achievement'] ?? 'Achievement'),
                subtitle: Text('Earned on ${item['timestamp']?.split('T')[0]}'),
                trailing: Text('+${item['points']} XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}
