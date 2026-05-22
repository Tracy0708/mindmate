import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';
import '../../services/admin_realtime_notification_service.dart';
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
    AdminRealtimeNotificationService().startListening();
  }

  @override
  void dispose() {
    AdminRealtimeNotificationService().stopListening();
    super.dispose();
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
        children: const [
          _AdminHomeTab(),
          UserManagementScreen(),
          _UsageAnalyticsTab(),
          _AdminProfileTab(),
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.creamLight,
        child: RefreshIndicator(
          color: AppColors.golden,
          onRefresh: () => context.read<AdminViewModel>().generateReport(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Consumer<AdminViewModel>(
              builder: (context, vm, _) {
                final report = vm.usageReport;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ──
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, Admin 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _todayLabel(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brownMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (vm.isLoading)
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.golden),
                          )
                        else
                          GestureDetector(
                            onTap: vm.generateReport,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.golden.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.refresh_rounded,
                                  color: AppColors.golden, size: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (vm.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.errorRed.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                color: AppColors.errorRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(vm.errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.brownMedium)),
                            ),
                            TextButton(
                              onPressed: vm.generateReport,
                              child: const Text('Retry',
                                  style: TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── KPI GRID ──
                    const _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      title: 'Platform Overview',
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _StatCard(
                          value: '${report?['totalUsers'] ?? 0}',
                          label: 'Total Users',
                          color: AppColors.golden,
                          icon: Icons.group_rounded,
                          subtitle: 'All registered accounts',
                        ),
                        _StatCard(
                          value: '${report?['activeUsers'] ?? 0}',
                          label: 'Active',
                          color: const Color(0xFF26A69A),
                          icon: Icons.check_circle_rounded,
                          subtitle: 'Non-disabled users',
                        ),
                        _StatCard(
                          value: '${report?['disabledUsers'] ?? 0}',
                          label: 'Suspended',
                          color: AppColors.errorRed,
                          icon: Icons.block_rounded,
                          subtitle: 'Disabled accounts',
                        ),
                        _StatCard(
                          value: '${report?['adminUsers'] ?? 0}',
                          label: 'Admins',
                          color: const Color(0xFF7E57C2),
                          icon: Icons.admin_panel_settings_rounded,
                          subtitle: 'Admin-role accounts',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── USAGE SNAPSHOT ──
                    const _SectionHeader(
                      icon: Icons.insights_rounded,
                      title: 'Usage Snapshot',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.mood_rounded,
                                  label: 'Total Logs',
                                  value: '${report?['totalLogs'] ?? 0}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.today_rounded,
                                  label: 'Logs Today',
                                  value: '${report?['logsToday'] ?? 0}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.date_range_rounded,
                                  label: 'Logs (7d)',
                                  value: '${report?['logsThisWeek'] ?? 0}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.person_pin_circle_rounded,
                                  label: 'Active (7d)',
                                  value: '${report?['activeUsersThisWeek'] ?? 0}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.pie_chart_rounded,
                                  label: 'Avg Logs/User',
                                  value: '${report?['avgLogsPerUser'] ?? '0.0'}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashboardInfoTile(
                                  icon: Icons.schedule_rounded,
                                  label: 'Last Refreshed',
                                  value: _formatReportTime(report?['generatedAt']),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.fieldBorder),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.brownLight),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Pull down to refresh, or tap the refresh icon above.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brownLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),

      ),
    );
  }
}

String _formatReportTime(dynamic generatedAt) {
  if (generatedAt is! String) return 'N/A';
  final parsed = DateTime.tryParse(generatedAt);
  if (parsed == null) return 'N/A';
  return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

class _DashboardInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DashboardInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.golden, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.brownMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.golden.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.golden, size: 17),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDark)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDark)),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.brownMedium)),
        ],
      ),
    );
  }
}

class _UsageAnalyticsTab extends StatefulWidget {
  const _UsageAnalyticsTab();

  @override
  State<_UsageAnalyticsTab> createState() => _UsageAnalyticsTabState();
}

class _UsageAnalyticsTabState extends State<_UsageAnalyticsTab> {
  int _refreshSeed = 0;
  String _searchQuery = '';
  String _riskFilter = 'All';

  String _formatDate(dynamic value) {
    if (value is! DateTime) return 'N/A';
    return '${value.month}/${value.day}/${value.year}';
  }

  String _riskLevel(double score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Moderate';
    return 'Observe';
  }

  Color _riskColor(double score) {
    if (score >= 80) return AppColors.errorRed;
    if (score >= 60) return const Color(0xFFDD8A00);
    return AppColors.brownMedium;
  }

  Future<void> _showUserRiskDetailSheet(Map<String, dynamic> user) async {
    final userId = (user['userId'] as String?) ?? '';
    if (userId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.creamLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: FutureBuilder<Map<String, dynamic>>(
                future:
                    context.read<AdminViewModel>().getUserUsageStats(userId),
                builder: (context, usageSnapshot) {
                  final riskScore =
                      (user['riskScore'] as num?)?.toDouble() ?? 0;
                  final color = _riskColor(riskScore);
                  final moodLogs =
                      usageSnapshot.data?['moodLogs'] ?? user['totalLogs'] ?? 0;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 46,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.fieldBorder,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (user['name'] as String?)?.isNotEmpty == true
                              ? user['name'] as String
                              : 'Unknown User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brownDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user['email'] as String?)?.isNotEmpty == true
                              ? user['email'] as String
                              : 'No email',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.brownMedium,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Risk score ${riskScore.toStringAsFixed(0)}% (${_riskLevel(riskScore)}) based on recent mood pattern.',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _RiskStatPill(
                              icon: Icons.insights_rounded,
                              label:
                                  '${(((user['negativeRatio'] as num?)?.toDouble() ?? 0) * 100).toStringAsFixed(0)}% negative logs',
                              color: color,
                            ),
                            _RiskStatPill(
                              icon: Icons.sentiment_dissatisfied_rounded,
                              label:
                                  'Dominant: ${((user['dominantNegativeMood'] as String?) ?? 'mixed').toUpperCase()}',
                              color: const Color(0xFFDD8A00),
                            ),
                            _RiskStatPill(
                              icon: Icons.history_rounded,
                              label: '$moodLogs logs tracked',
                              color: AppColors.golden,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Last mood entry: ${_formatDate(user['lastMoodAt'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brownMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last login: ${_formatDate(user['lastLogin'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brownMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (usageSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                color: AppColors.golden,
                              ),
                            ),
                          )
                        else if (usageSnapshot.hasError)
                          const Text(
                            'Could not load additional usage stats.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _matchesFilter(Map<String, dynamic> user) {
    final name = ((user['name'] as String?) ?? '').toLowerCase();
    final email = ((user['email'] as String?) ?? '').toLowerCase();
    final query = _searchQuery.trim().toLowerCase();
    final riskScore = (user['riskScore'] as num).toDouble();

    final queryMatch =
        query.isEmpty || name.contains(query) || email.contains(query);
    if (!queryMatch) return false;

    if (_riskFilter == 'All') return true;
    if (_riskFilter == 'High') return riskScore >= 80;
    if (_riskFilter == 'Moderate') return riskScore >= 60 && riskScore < 80;
    return riskScore < 60;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_refreshSeed),
        future: context.read<AdminViewModel>().getMoodRiskUsers(
              lookbackDays: 21,
              limit: 20,
            ),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final users = snapshot.data ?? const <Map<String, dynamic>>[];
          final filteredUsers =
              users.where(_matchesFilter).toList(growable: false);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Mood Risk Analytics',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Per-user mood pattern analysis to identify users who may need counselling follow-up.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brownMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.golden.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.golden.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.golden),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Score = negative mood ratio (58%) + recent trend (25%) + log volume (10%) + recency (7%)',
                          style: TextStyle(fontSize: 11, color: AppColors.brownMedium, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search user by name or email',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFFFFAEE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.fieldBorder.withOpacity(0.7)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.fieldBorder.withOpacity(0.7)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Risk Level:',
                            style: TextStyle(
                                color: AppColors.brownMedium,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _riskFilter,
                              items: const [
                                DropdownMenuItem(
                                    value: 'All', child: Text('All')),
                                DropdownMenuItem(
                                    value: 'High', child: Text('High')),
                                DropdownMenuItem(
                                    value: 'Moderate', child: Text('Moderate')),
                                DropdownMenuItem(
                                    value: 'Observe', child: Text('Observe')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _riskFilter = value);
                              },
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: const Color(0xFFFFFAEE),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.fieldBorder
                                          .withOpacity(0.7)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Showing ${filteredUsers.length} of ${users.length} users',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brownMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: AppColors.golden),
                    ),
                  )
                else if (snapshot.hasError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.errorRed.withOpacity(0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Could not load mood risk analysis',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$snapshot.error',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.brownMedium,
                              height: 1.35),
                        ),
                      ],
                    ),
                  )
                else if (filteredUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Text(
                      'No users match the current filter. Try adjusting search or risk level.',
                      style: TextStyle(
                          color: AppColors.brownMedium,
                          height: 1.4,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  ...filteredUsers.map((user) {
                    final riskScore = (user['riskScore'] as num).toDouble();
                    final color = _riskColor(riskScore);
                    final negativeRatio =
                        ((user['negativeRatio'] as num).toDouble() * 100)
                            .toStringAsFixed(0);

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showUserRiskDetailSheet(user),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.2)),
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
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    ((user['name'] as String?) ?? '?').isNotEmpty
                                        ? (user['name'] as String)[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (user['name'] as String?) ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brownDark,
                                        ),
                                      ),
                                      Text(
                                        (user['email'] as String?) ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.brownMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _riskLevel(riskScore),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  '${riskScore.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: color),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: riskScore / 100,
                                      minHeight: 6,
                                      backgroundColor:
                                          color.withOpacity(0.12),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _RiskStatPill(
                                  icon: Icons.insights_rounded,
                                  label: '$negativeRatio% negative',
                                  color: color,
                                ),
                                _RiskStatPill(
                                  icon: Icons.sentiment_dissatisfied_rounded,
                                  label: (user['dominantNegativeMood']
                                              as String)
                                          .toUpperCase(),
                                  color: const Color(0xFFDD8A00),
                                ),
                                _RiskStatPill(
                                  icon: Icons.history_rounded,
                                  label: '${user['totalLogs']} logs',
                                  color: AppColors.golden,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last mood: ${_formatDate(user['lastMoodAt'])}  ·  Last login: ${_formatDate(user['lastLogin'])}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.brownMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _refreshSeed++),
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.golden),
                  label: const Text(
                    'Refresh Mood Analysis',
                    style: TextStyle(
                      color: AppColors.golden,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.golden, width: 1.4),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RiskStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RiskStatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
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
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        const SizedBox(height: 24),

                        // ── SETTINGS HEADER ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.golden.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.settings,
                                  color: AppColors.golden, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Settings',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brownDark)),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // ── SETTINGS LIST ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(children: [
                              _AdminSettingsItem(
                                icon: Icons.notifications_active_outlined,
                                label: 'Notification Settings',
                                onTap: () => Navigator.pushNamed(
                                    context, '/admin-notifications-settings'),
                              ),
                              _AdminSettingsItem(
                                icon: Icons.shield_outlined,
                                label: 'Privacy',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/privacy'),
                              ),
                              _AdminSettingsItem(
                                icon: Icons.help_outline,
                                label: 'Help & Support',
                                onTap: () => Navigator.pushNamed(
                                    context, '/help-support'),
                              ),
                              _AdminSettingsItem(
                                icon: Icons.logout,
                                label: 'Sign Out',
                                isDestructive: true,
                                onTap: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (!context.mounted) return;
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
                              ),
                            ]),
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

class _AdminSettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _AdminSettingsItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : AppColors.brownDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Icon(icon,
              color: isDestructive ? color : AppColors.brownMedium, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          if (!isDestructive)
            const Icon(Icons.chevron_right,
                color: AppColors.brownLight, size: 20),
        ]),
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
              color: AppColors.golden.withValues(alpha: 0.14),
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
