import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminViewModel>(context, listen: false).generateReport();
    });
  }

  void _navigateToTab(int index) {
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          const _AdminHomeTab(),
          const UserManagementScreen(),
          _UsageAnalyticsTab(),
          const _AdminProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.golden);
                }
                return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.brownMedium);
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: _navigateToTab,
            height: 65,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.golden),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: AppColors.golden),
                  label: 'Users'),
              NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment, color: AppColors.golden),
                  label: 'Analytics'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.golden),
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab();

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Consumer<AdminViewModel>(
            builder: (context, vm, _) {
              final report = vm.usageReport;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.96),
                          const Color(0xFFFFF8E7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.fieldBorder.withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Admin Dashboard',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brownDark),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Live user and activity overview.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.brownMedium,
                                        height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vm.isLoading) ...[
                          const SizedBox(height: 14),
                          const LinearProgressIndicator(minHeight: 3),
                          const SizedBox(height: 8),
                          const Text(
                            'Refreshing usage report...',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.brownMedium),
                          ),
                        ],
                        if (vm.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: AppColors.errorRed.withOpacity(0.18)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.cloud_off_rounded,
                                    color: AppColors.errorRed),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Report sync failed',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brownDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vm.errorMessage!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.brownMedium,
                                            height: 1.35),
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton(
                                        onPressed: vm.generateReport,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                          value: '${report?['totalUsers'] ?? 0}',
                          label: 'Total Users',
                          color: AppColors.golden,
                          icon: Icons.group_rounded),
                      _StatCard(
                          value: '${report?['activeUsers'] ?? 0}',
                          label: 'Active Users',
                          color: AppColors.golden,
                          icon: Icons.check_circle_rounded),
                      _StatCard(
                          value: '${report?['disabledUsers'] ?? 0}',
                          label: 'Disabled',
                          color: AppColors.brownDark,
                          icon: Icons.block_rounded),
                      _StatCard(
                          value: '${report?['adminUsers'] ?? 0}',
                          label: 'Admins',
                          color: AppColors.brownDark,
                          icon: Icons.admin_panel_settings_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded,
                  size: 18, color: color.withOpacity(0.75)),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 30,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.brownMedium,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _UsageAnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.96),
                    const Color(0xFFFFF8E7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.fieldBorder.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Analytics',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brownDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'A compact summary of the main account and activity signals currently available in Firebase.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brownMedium,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Snapshot',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brownDark)),
                  SizedBox(height: 16),
                  _StatMetricCard(
                    icon: Icons.people,
                    iconColor: AppColors.golden,
                    title: 'Total Active Users',
                    value: '2,847',
                    trend: '↑ 12.5% vs last month',
                    isPositiveMatch: true,
                  ),
                  _StatMetricCard(
                    icon: Icons.insights,
                    iconColor: AppColors.golden,
                    title: 'Avg. Daily Active Users',
                    value: '1,234',
                    trend: '↑ 8.2% vs last month',
                    isPositiveMatch: true,
                  ),
                  _StatMetricCard(
                    icon: Icons.access_time_filled,
                    iconColor: AppColors.golden,
                    title: 'Avg. Session Duration',
                    value: '12:45',
                    trend: '↑ 5.2% vs last month',
                    isPositiveMatch: true,
                  ),
                  _StatMetricCard(
                    icon: Icons.mood,
                    iconColor: AppColors.golden,
                    title: 'Mood Log Completion',
                    value: '89%',
                    trend: '↓ 2.1% vs last month',
                    isPositiveMatch: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Recommended Filters',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brownDark)),
                  SizedBox(height: 16),
                  _FilterDropdown(label: 'Date Range', value: 'Last 30 Days'),
                  SizedBox(height: 16),
                  _FilterDropdown(label: 'User Group', value: 'All Users'),
                  SizedBox(height: 16),
                  _FilterDropdown(label: 'Key Metric', value: 'Engagement'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Engagement Trend',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brownDark)),
                  const SizedBox(height: 18),
                  _TrendBar(label: 'Mon', value: 0.65, color: AppColors.golden),
                  _TrendBar(label: 'Tue', value: 0.82, color: Colors.green),
                  _TrendBar(label: 'Wed', value: 0.58, color: Colors.blue),
                  _TrendBar(
                      label: 'Thu', value: 0.74, color: AppColors.brownDark),
                  _TrendBar(label: 'Fri', value: 0.90, color: Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Consumer<AdminViewModel>(
              builder: (context, vm, _) {
                return OutlinedButton.icon(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await vm.generateReport();
                          if (!context.mounted) return;

                          if (vm.errorMessage != null) {
                            InteractiveMessageService.showError(
                              context,
                              title: 'Report failed',
                              message: vm.errorMessage!,
                            );
                            return;
                          }

                          InteractiveMessageService.showSuccess(
                            context,
                            title: 'Report refreshed',
                            message:
                                'Analytics data was updated from Firebase.',
                          );
                        },
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.golden),
                  label: Text(
                    vm.isLoading ? 'Refreshing...' : 'Refresh Report',
                    style: const TextStyle(
                      color: AppColors.golden,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.golden, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the Users tab for account management actions.',
              style: TextStyle(
                  color: AppColors.brownMedium, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileTab extends StatefulWidget {
  const _AdminProfileTab();

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return 'A';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: SafeArea(
        child: currentUser == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline,
                          size: 42, color: AppColors.brownMedium),
                      SizedBox(height: 10),
                      Text('Admin session not found',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brownDark)),
                      SizedBox(height: 4),
                      Text('Please sign in again to view profile.',
                          style: TextStyle(color: AppColors.brownMedium)),
                    ],
                  ),
                ),
              )
            : FutureBuilder<UserModel?>(
                future:
                    context.read<AdminViewModel>().getUserById(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.golden));
                  }

                  final profile = snapshot.data;
                  final displayName = (profile?.userName.isNotEmpty == true)
                      ? profile!.userName
                      : (currentUser.displayName ?? 'Admin User');
                  final email = (profile?.userEmail.isNotEmpty == true)
                      ? profile!.userEmail
                      : (currentUser.email ?? 'No email');
                  final role = (profile?.role ?? 'admin').toUpperCase();
                  final status =
                      (profile?.isDisabled ?? false) ? 'Disabled' : 'Active';
                  final lastLogin = profile?.lastLogin;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 72),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE0A0),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initialsFromName(displayName),
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.golden),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppColors.fieldBorder),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 18,
                                color: AppColors.golden,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.brownMedium,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              _AdminProfileItem(
                                icon: Icons.verified_user_outlined,
                                label: 'Role',
                                value: role,
                              ),
                              const Divider(
                                  height: 1, color: AppColors.fieldBorder),
                              _AdminProfileItem(
                                icon: Icons.shield_outlined,
                                label: 'Status',
                                value: status,
                              ),
                              const Divider(
                                  height: 1, color: AppColors.fieldBorder),
                              _AdminProfileItem(
                                icon: Icons.badge_outlined,
                                label: 'User ID',
                                value: currentUser.uid,
                              ),
                              const Divider(
                                  height: 1, color: AppColors.fieldBorder),
                              _AdminProfileItem(
                                icon: Icons.access_time,
                                label: 'Last Login',
                                value: lastLogin == null
                                    ? 'N/A'
                                    : '${lastLogin.month}/${lastLogin.day}/${lastLogin.year}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (!mounted) return;
                                InteractiveMessageService.showInfo(
                                  context,
                                  title: 'Signed out',
                                  message: 'Admin session ended.',
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/admin-login',
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorRed,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AdminProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AdminProfileItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.golden.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.golden, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.brownMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.brownDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  const _FilterDropdown({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.brownDark, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: AppColors.brownDark)),
              const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.brownMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value, trend;
  final bool isPositiveMatch;

  const _StatMetricCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.value,
      required this.trend,
      required this.isPositiveMatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDark,
                  fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Text(value,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brownDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(trend,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositiveMatch ? Colors.green : AppColors.errorRed)),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TrendBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownMedium),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.fieldBorder.withOpacity(0.28),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
