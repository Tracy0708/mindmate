import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';

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
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF2), Color(0xFFFFF6E6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.96),
                      const Color(0xFFFFF8E7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.fieldBorder.withOpacity(0.45)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Management',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brownDark)),
                    SizedBox(height: 6),
                    Text(
                        'Search, inspect, and manage user accounts stored in Firebase.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brownMedium,
                            height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.fieldBorder.withOpacity(0.55)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or UID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AdminViewModel>(
                builder: (context, vm, _) {
                  return StreamBuilder<List<UserModel>>(
                    stream: vm.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded,
                                    color: AppColors.errorRed, size: 42),
                                const SizedBox(height: 10),
                                Text('Unable to fetch users\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.brownMedium,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color:
                                      AppColors.fieldBorder.withOpacity(0.45)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_off_rounded,
                                    size: 40, color: AppColors.brownMedium),
                                SizedBox(height: 10),
                                Text('No users found',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brownDark)),
                                SizedBox(height: 4),
                                Text('There are no accounts in Firestore yet.',
                                    style: TextStyle(
                                        color: AppColors.brownMedium)),
                              ],
                            ),
                          ),
                        );
                      }

                      final users = snapshot.data!.where((u) {
                        if (_searchQuery.isEmpty) return true;
                        final uid = u.userID.toLowerCase();
                        return u.userName
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            u.userEmail.toLowerCase().contains(_searchQuery) ||
                            uid.contains(_searchQuery);
                      }).toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color:
                                      AppColors.fieldBorder.withOpacity(0.45)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.manage_search_rounded,
                                    size: 40, color: AppColors.brownMedium),
                                SizedBox(height: 10),
                                Text('No matching users',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brownDark)),
                                SizedBox(height: 4),
                                Text('Try a different name, email, or UID.',
                                    style: TextStyle(
                                        color: AppColors.brownMedium)),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.golden.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${users.length} user${users.length == 1 ? '' : 's'} visible',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brownDark),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'All records'
                                      : 'Filtered results',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.brownMedium),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: users.length,
                              itemBuilder: (context, index) => _UserCard(
                                user: users[index],
                                onDelete: () =>
                                    _confirmDelete(context, vm, users[index]),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminViewModel vm, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete User?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete ${user.userName}?\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.brownMedium))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
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
    final isAdmin = user.role == 'admin';
    final isDisabled = user.isDisabled;
    final accentColor = isDisabled
        ? AppColors.errorRed
        : (isAdmin ? AppColors.golden : AppColors.brownDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFFFFBF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.18),
                      accentColor.withOpacity(0.06)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.person_rounded, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.userName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDark)),
                    const SizedBox(height: 3),
                    Text(user.userEmail,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.brownMedium)),
                  ],
                ),
              ),
              _UserChip(
                  label: isDisabled ? 'Disabled' : 'Active',
                  color: isDisabled ? AppColors.errorRed : Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UserChip(
                  label: isAdmin ? 'Admin' : 'User',
                  color: isAdmin ? AppColors.golden : AppColors.brownDark),
              _UserChip(
                  label: _formatDate(user.lastLogin),
                  color: AppColors.brownMedium),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUserDetail(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.fieldBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View Details',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.brownDark,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
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
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.97,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Consumer<AdminViewModel>(
            builder: (context, vm, _) {
              return FutureBuilder<Map<String, dynamic>>(
                future: vm.getUserUsageStats(user.userID),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  final isAdmin = user.role == 'admin';
                  final accentColor = user.isDisabled
                      ? AppColors.errorRed
                      : (isAdmin ? AppColors.golden : AppColors.brownDark);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              accentColor.withOpacity(0.08)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: accentColor.withOpacity(0.16)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accentColor.withOpacity(0.18),
                                    accentColor.withOpacity(0.06)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(Icons.person_rounded,
                                  color: accentColor, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.userName,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brownDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(user.userEmail,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.brownMedium)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _UserChip(
                                          label: isAdmin
                                              ? 'Administrator'
                                              : 'User',
                                          color: isAdmin
                                              ? AppColors.golden
                                              : AppColors.brownDark),
                                      _UserChip(
                                          label: user.isDisabled
                                              ? 'Disabled'
                                              : 'Active',
                                          color: user.isDisabled
                                              ? AppColors.errorRed
                                              : Colors.green),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          children: [
                            const Text(
                              'Profile Snapshot',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brownDark),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Core account details and identity status.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownMedium,
                                  height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    const Color(0xFFFFFBF4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.fieldBorder
                                        .withOpacity(0.55)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tileWidth = constraints.maxWidth < 360
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 12) / 2;

                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Name',
                                            value: user.userName),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Email',
                                            value: user.userEmail),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Role', value: user.role),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Status',
                                            value: user.isDisabled
                                                ? 'Disabled'
                                                : 'Active',
                                            valueColor: user.isDisabled
                                                ? AppColors.errorRed
                                                : Colors.green),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'UID', value: user.userID),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Last Login',
                                            value: _formatDate(user.lastLogin)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text('Usage Statistics',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brownDark)),
                            const SizedBox(height: 4),
                            const Text(
                              'Activity and account usage pulled from Firebase records.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownMedium,
                                  height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      AppColors.creamLight.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.fieldBorder
                                          .withOpacity(0.55)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5))
                                  ]),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tileWidth = constraints.maxWidth < 360
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 12) / 2;

                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Mood Logs',
                                            value: snapshot.connectionState ==
                                                    ConnectionState.waiting
                                                ? '...'
                                                : '${stats?['moodLogs'] ?? 0}'),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Last Active',
                                            value: _formatDate(
                                                stats?['lastActive']
                                                    as DateTime?)),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Account Type',
                                            value: user.role == 'admin'
                                                ? 'Administrator'
                                                : 'User'),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _DetailTile(
                                            label: 'Disabled',
                                            value:
                                                user.isDisabled ? 'Yes' : 'No',
                                            valueColor: user.isDisabled
                                                ? AppColors.errorRed
                                                : Colors.green),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text('Management Actions',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brownDark)),
                            const SizedBox(height: 4),
                            const Text(
                              'Account controls and profile cleanup.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownMedium,
                                  height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      AppColors.creamLight.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.fieldBorder
                                          .withOpacity(0.55)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5))
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await vm.resetPasswordForEmail(
                                            user.userEmail);
                                        if (context.mounted) {
                                          InteractiveMessageService.showSuccess(
                                            context,
                                            title: 'Password reset sent',
                                            message:
                                                'Email sent to ${user.userEmail}',
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.lock_reset),
                                      label: const Text('Reset Password'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await vm.setUserDisabled(
                                            user.userID, !user.isDisabled);
                                        if (context.mounted) {
                                          InteractiveMessageService.showSuccess(
                                            context,
                                            title: user.isDisabled
                                                ? 'Account enabled'
                                                : 'Account disabled',
                                            message: user.isDisabled
                                                ? 'The user can log in again.'
                                                : 'The user is blocked from logging in.',
                                          );
                                          Navigator.pop(ctx);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: user.isDisabled
                                                ? Colors.green
                                                : AppColors.errorRed),
                                      ),
                                      icon: Icon(
                                          user.isDisabled
                                              ? Icons.lock_open
                                              : Icons.block,
                                          color: user.isDisabled
                                              ? Colors.green
                                              : AppColors.errorRed),
                                      label: Text(user.isDisabled
                                          ? 'Enable Account'
                                          : 'Disable Account'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: onDelete,
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.errorRed),
                                      label: const Text(
                                          'Remove Firestore Profile',
                                          style: TextStyle(
                                              color: AppColors.errorRed)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Password resets use Firebase Auth. Disable/enable is enforced against the Firestore user record.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brownMedium,
                                        height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value,
      {Color color = AppColors.brownDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.brownMedium)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'N/A';
    return '${value.month}/${value.day}/${value.year}';
  }
}

class _UserChip extends StatelessWidget {
  final String label;
  final Color color;

  const _UserChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailTile(
      {required this.label,
      required this.value,
      this.valueColor = AppColors.brownDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.brownMedium,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1.25),
          ),
        ],
      ),
    );
  }
}
