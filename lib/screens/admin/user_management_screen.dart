import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Title
          const Center(
            child: Text('User Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.golden)),
          ),
          const SizedBox(height: 20),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search user by name or email...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.fieldBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.fieldBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.golden, width: 2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User list
          Expanded(
            child: Consumer<AdminViewModel>(
              builder: (context, vm, _) {
                return StreamBuilder<List<UserModel>>(
                  stream: vm.getUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No users found', style: TextStyle(color: AppColors.brownMedium)));
                    }

                    final users = snapshot.data!.where((u) {
                      if (_searchQuery.isEmpty) return true;
                      return u.userName.toLowerCase().contains(_searchQuery) ||
                          u.userEmail.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(child: Text('No matching users', style: TextStyle(color: AppColors.brownMedium)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: users.length,
                      itemBuilder: (context, index) => _UserCard(
                        user: users[index],
                        onDelete: () => _confirmDelete(context, vm, users[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminViewModel vm, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete User?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${user.userName}?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.brownMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () {
              vm.deleteUser(user.userID);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.golden.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
          const SizedBox(height: 4),
          Text(user.userEmail, style: const TextStyle(fontSize: 13, color: AppColors.brownMedium)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // View button
              OutlinedButton(
                onPressed: () => _showUserDetail(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  side: const BorderSide(color: AppColors.fieldBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View', style: TextStyle(fontSize: 13, color: AppColors.brownDark, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              // Delete button
              ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Header line
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const Text('User Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Basic Information Header
                    const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _infoCol('Name', user.userName)),
                              Expanded(child: _infoCol('Email', user.userEmail)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _infoCol('Phone', '+1 (555) 123-4567')), // Simulated
                              Expanded(child: _infoCol('Join Date', 'Oct 15, 2024')),   // Simulated
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Usage Statistics Header
                    const Text('Usage Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _infoCol('Status', 'Active', color: Colors.green)),
                              Expanded(child: _infoCol('Last Active', '2 hours ago')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _infoCol('Mood Entries', '142')),
                              Expanded(child: _infoCol('Streak Days', '28')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _infoCol('Badges Earned', '15')),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Daily Tasks Completion', style: TextStyle(fontSize: 11, color: AppColors.brownMedium)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                                              FractionallySizedBox(widthFactor: 0.85, child: Container(height: 6, decoration: BoxDecoration(color: AppColors.golden, borderRadius: BorderRadius.circular(3)))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('85%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.golden)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity Header
                    const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.edit_note, color: AppColors.golden, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Logged Daily Mood', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.brownDark)),
                                Text('5/30/2025 • 2:30 PM', style: TextStyle(fontSize: 12, color: AppColors.brownMedium)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value, {Color color = AppColors.brownDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.brownMedium)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
