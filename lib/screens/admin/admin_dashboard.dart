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
        children: [
          const _AdminHomeTab(),
          const UserManagementScreen(),
          const _UsageAnalyticsTab(),
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
                                    'Overall platform health and activity overview.',
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
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Snapshot',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brownDark),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Quick overall usage signals for monitoring engagement and data freshness.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.brownMedium,
                              height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.fieldBorder.withOpacity(0.55),
                            ),
                          ),
                          child: const Text(
                            'Mood Logs Captured shows the total number of emotion logs submitted by all users. Report Generated indicates when this dashboard summary was last refreshed from Firebase.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.brownMedium,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardInfoTile(
                                icon: Icons.mood_rounded,
                                label: 'Mood Logs Captured (All Users)',
                                value: '${report?['totalLogs'] ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DashboardInfoTile(
                                icon: Icons.schedule_rounded,
                                label: 'Report Generated',
                                value:
                                    _formatReportTime(report?['generatedAt']),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: vm.isLoading ? null : vm.generateReport,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.golden),
                          label: Text(
                            vm.isLoading
                                ? 'Refreshing...'
                                : 'Refresh Dashboard Data',
                            style: const TextStyle(
                              color: AppColors.golden,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.golden, width: 1.3),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
                    border: Border.all(
                        color: AppColors.fieldBorder.withOpacity(0.45)),
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
                        'Mood Risk Analytics',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brownDark),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Per-user analysis to identify who may need real counselling follow-up.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brownMedium,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.fieldBorder.withOpacity(0.55)),
                  ),
                  child: const Text(
                    'Risk score is based on negative mood ratio, recent negative trend (last 7 days), and logging consistency over the last 21 days.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.brownMedium,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
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
                              value: _riskFilter,
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
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showUserRiskDetailSheet(user),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: color.withOpacity(0.25)),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (user['name'] as String).isEmpty
                                              ? 'Unknown User'
                                              : user['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brownDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (user['email'] as String?)
                                                      ?.isNotEmpty ==
                                                  true
                                              ? user['email'] as String
                                              : 'No email',
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
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${riskScore.toStringAsFixed(0)}% ${_riskLevel(riskScore)}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.brownMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _RiskStatPill(
                                    icon: Icons.insights_rounded,
                                    label: '$negativeRatio% negative logs',
                                    color: color,
                                  ),
                                  _RiskStatPill(
                                    icon: Icons.sentiment_dissatisfied_rounded,
                                    label:
                                        'Dominant: ${(user['dominantNegativeMood'] as String).toUpperCase()}',
                                    color: const Color(0xFFDD8A00),
                                  ),
                                  _RiskStatPill(
                                    icon: Icons.history_rounded,
                                    label:
                                        '${user['totalLogs']} logs (21 days)',
                                    color: AppColors.golden,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Last mood entry: ${_formatDate(user['lastMoodAt'])}  |  Last login: ${_formatDate(user['lastLogin'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap to view more details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.brownMedium,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ));
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
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/admin-notifications-settings'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.golden.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.notifications_active_outlined, color: AppColors.golden, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'Notification Settings',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brownDark,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.brownMedium),
                                ],
                              ),
                            ),
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
