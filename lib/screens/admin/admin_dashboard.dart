import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';
import '../../services/admin_realtime_notification_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/app_settings_tile.dart';
import '../../widgets/app_emoji.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
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
                      color: AppColors.primary);
                }
                return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textMedium);
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
                  selectedIcon: Icon(Icons.home, color: AppColors.primary),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: AppColors.primary),
                  label: 'Users'),
              NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
                  label: 'Analytics'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.primary),
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  bool _isExportingReport = false;
  bool _isPreviewingReport = false;

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

  Future<void> _exportSystemReport() async {
    setState(() => _isExportingReport = true);
    try {
      final bytes = await context
          .read<AdminViewModel>()
          .exportSystemReport(lookbackDays: 30);
      final filename =
          'mindmate_system_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingReport = false);
    }
  }

  Future<void> _previewSystemReport() async {
    setState(() => _isPreviewingReport = true);
    try {
      final bytes = await context
          .read<AdminViewModel>()
          .exportSystemReport(lookbackDays: 30);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            title: 'System Report',
            buildPdf: () async => bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPreviewingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.creamLight,
        child: RefreshIndicator(
          color: AppColors.primary,
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
                    AppScreenHeader(
                      padding: EdgeInsets.zero,
                      eyebrow: '${_greeting()} 👋',
                      title: 'Admin',
                      subtitle: _todayLabel(),
                      trailing: const NotificationBell(iconSize: 26),
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
                                      color: AppColors.textMedium)),
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
                          color: AppColors.primary,
                          icon: Icons.group_rounded,
                          subtitle: 'All registered accounts',
                        ),
                        _StatCard(
                          value: '${report?['activeUsers'] ?? 0}',
                          label: 'Active',
                          color: const Color(0xFF81B29A),
                          icon: Icons.check_circle_rounded,
                          subtitle: 'Non-disabled users',
                        ),
                        _StatCard(
                          value: '${report?['disabledUsers'] ?? 0}',
                          label: 'Suspended',
                          color: const Color(0xFFBF616A),
                          icon: Icons.block_rounded,
                          subtitle: 'Disabled accounts',
                        ),
                        _StatCard(
                          value: '${report?['adminUsers'] ?? 0}',
                          label: 'Admins',
                          color: const Color(0xFF9B8EA8),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── SYSTEM REPORT EXPORT ──
                    const _SectionHeader(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'System Report',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Full platform report (last 30 days) as a PDF.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: _isPreviewingReport
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary),
                                        )
                                      : const Icon(Icons.preview_rounded,
                                          size: 16),
                                  label: Text(_isPreviewingReport
                                      ? 'Loading…'
                                      : 'Preview'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                  onPressed: (_isExportingReport ||
                                          _isPreviewingReport)
                                      ? null
                                      : _previewSystemReport,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: _isExportingReport
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textDark,
                                          ),
                                        )
                                      : const Icon(Icons.download_rounded,
                                          size: 18),
                                  label: Text(_isExportingReport
                                      ? 'Generating…'
                                      : 'Export PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textDark,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                  onPressed: (_isExportingReport ||
                                          _isPreviewingReport)
                                      ? null
                                      : _exportSystemReport,
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
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
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
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 17),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
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
                  color: AppColors.textDark)),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMedium)),
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
  int _lookbackDays = 21;

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
    return AppColors.textMedium;
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
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user['email'] as String?)?.isNotEmpty == true
                              ? user['email'] as String
                              : 'No email',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
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
                              color: AppColors.primary,
                            ),
                            if ((user['mixedMoodCount'] as int? ?? 0) > 0)
                              _RiskStatPill(
                                icon: Icons.swap_horiz_rounded,
                                label:
                                    '${user['mixedMoodCount']} mixed mood entries',
                                color: const Color(0xFF7B61FF),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Last mood entry: ${_formatDate(user['lastMoodAt'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last login: ${_formatDate(user['lastLogin'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Emotion Breakdown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _EmotionBreakdownChips(
                          emotionByType: (user['emotionByType'] as Map?)
                                  ?.map((k, v) => MapEntry(
                                      k.toString(), (v as num).toInt())) ??
                              const {},
                        ),
                        const SizedBox(height: 16),
                        if (usageSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
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
                        const SizedBox(height: 8),
                        _ExportUserPdfButton(user: user),
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
      child: FutureBuilder<List<dynamic>>(
        key: ValueKey('$_refreshSeed-$_lookbackDays'),
        future: Future.wait([
          context.read<AdminViewModel>().getMoodRiskUsers(
                lookbackDays: _lookbackDays,
                limit: 20,
              ),
          context.read<AdminViewModel>().getPlatformEmotionStats(
                lookbackDays: _lookbackDays,
              ),
        ]),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final users =
              (snapshot.data?[0] as List<Map<String, dynamic>>?) ??
                  const <Map<String, dynamic>>[];
          final platformStats =
              (snapshot.data?[1] as Map<String, dynamic>?) ??
                  const <String, dynamic>{};
          final filteredUsers =
              users.where(_matchesFilter).toList(growable: false);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const AppScreenHeader(
                  padding: EdgeInsets.zero,
                  icon: Icons.monitor_heart_rounded,
                  title: 'Mood Risk Analytics',
                  subtitle: 'Spot users who may need a counselling follow-up.',
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Score = negative mood ratio (58%) + recent trend (25%) + log volume (10%) + recency (7%)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _LookbackSelector(
                  selected: _lookbackDays,
                  onChanged: (v) => setState(() => _lookbackDays = v),
                ),
                const SizedBox(height: 14),
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
                                color: AppColors.textMedium,
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
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (!isLoading && !snapshot.hasError) ...[
                  _RiskSummaryRow(users: users),
                  const SizedBox(height: 14),
                  _EmotionBarChart(
                    platformStats: platformStats,
                    lookbackDays: _lookbackDays,
                  ),
                  const SizedBox(height: 14),
                  _DailyTrendChart(platformStats: platformStats),
                  const SizedBox(height: 14),
                ],
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: AppColors.primary),
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
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$snapshot.error',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
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
                          color: AppColors.textMedium,
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
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        (user['email'] as String?) ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMedium,
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
                                  color: AppColors.primary,
                                ),
                                if ((user['mixedMoodCount'] as int? ?? 0) > 0)
                                  _RiskStatPill(
                                    icon: Icons.swap_horiz_rounded,
                                    label: '${user['mixedMoodCount']} mixed mood',
                                    color: const Color(0xFF7B61FF),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last mood: ${_formatDate(user['lastMoodAt'])}  ·  Last login: ${_formatDate(user['lastLogin'])}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMedium,
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
                      color: AppColors.primary),
                  label: const Text(
                    'Refresh Mood Analysis',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.4),
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

// ── Lookback period chip selector ──────────────────────────────────────────
class _LookbackSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _LookbackSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [7, 14, 21, 30];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: options.map((days) {
        final isSelected = days == selected;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => onChanged(days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${days}D',
                style: TextStyle(
                  color: isSelected ? AppColors.textDark : AppColors.textMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Risk distribution summary row ───────────────────────────────────────────
class _RiskSummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const _RiskSummaryRow({required this.users});

  @override
  Widget build(BuildContext context) {
    int high = 0, moderate = 0, observe = 0;
    for (final u in users) {
      final score = (u['riskScore'] as num).toDouble();
      if (score >= 80) {
        high++;
      } else if (score >= 60) {
        moderate++;
      } else {
        observe++;
      }
    }
    return Row(
      children: [
        Expanded(
          child: _RiskMiniCard(
            label: 'High Risk',
            count: high,
            color: AppColors.errorRed,
            icon: Icons.warning_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RiskMiniCard(
            label: 'Moderate',
            count: moderate,
            color: const Color(0xFFDD8A00),
            icon: Icons.info_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RiskMiniCard(
            label: 'Observe',
            count: observe,
            color: AppColors.textMedium,
            icon: Icons.visibility_rounded,
          ),
        ),
      ],
    );
  }
}

class _RiskMiniCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _RiskMiniCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Emotion distribution bar chart ──────────────────────────────────────────
class _EmotionBarChart extends StatelessWidget {
  final Map<String, dynamic> platformStats;
  final int lookbackDays;

  const _EmotionBarChart({
    required this.platformStats,
    required this.lookbackDays,
  });

  static const _emotions = [
    'Happy', 'Calm', 'Tired', 'Anxious', 'Sad', 'Angry'
  ];
  static const _positiveEmotions = {'Happy', 'Calm'};
  static const _emojis = ['😊', '😌', '😴', '😰', '😢', '😠'];

  @override
  Widget build(BuildContext context) {
    final counts =
        (platformStats['emotionCounts'] as Map<String, dynamic>?) ?? {};

    final maxY = _emotions
        .map((e) => (counts[e] as int? ?? 0).toDouble())
        .fold(0.0, (prev, e) => e > prev ? e : prev);
    final yMax = maxY < 1 ? 5.0 : (maxY * 1.25).ceilToDouble();

    final barGroups = _emotions.asMap().entries.map((entry) {
      final idx = entry.key;
      final emotion = entry.value;
      final count = (counts[emotion] as int? ?? 0).toDouble();
      final isPositive = _positiveEmotions.contains(emotion);
      final barColor =
          isPositive ? const Color(0xFF81B29A) : const Color(0xFFBF616A);

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: count,
            color: barColor,
            width: 22,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotion Distribution (last ${lookbackDays}d)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.fieldBorder.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_emotions[group.x]}\n${rod.toY.toInt()} logs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _emojis.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AppEmoji(_emojis[i], size: 14),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendDot(
                  color: const Color(0xFF81B29A), label: 'Positive'),
              const SizedBox(width: 16),
              _ChartLegendDot(
                  color: const Color(0xFFBF616A), label: 'Negative'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textMedium),
        ),
      ],
    );
  }
}

// ── Daily activity trend line chart ─────────────────────────────────────────
class _DailyTrendChart extends StatelessWidget {
  final Map<String, dynamic> platformStats;

  const _DailyTrendChart({required this.platformStats});

  @override
  Widget build(BuildContext context) {
    final dailyCounts =
        (platformStats['dailyCounts'] as Map<String, dynamic>?) ?? {};

    final sortedKeys = dailyCounts.keys.toList()..sort();
    final last7 = sortedKeys.length > 7
        ? sortedKeys.sublist(sortedKeys.length - 7)
        : sortedKeys;

    if (last7.isEmpty) return const SizedBox.shrink();

    final spots = last7.asMap().entries.map((entry) {
      final idx = entry.key;
      final key = entry.value;
      return FlSpot(
          idx.toDouble(), (dailyCounts[key] as int? ?? 0).toDouble());
    }).toList();

    final maxY =
        spots.map((s) => s.y).fold(0.0, (prev, y) => y > prev ? y : prev);
    final yMax = maxY < 1 ? 5.0 : (maxY * 1.25).ceilToDouble();

    const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabels = last7.map((key) {
      final date = DateTime.tryParse(key);
      if (date == null) return key.substring(8);
      return dayAbbr[date.weekday - 1];
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Activity Trend (last 7d)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (last7.length - 1).toDouble(),
                minY: 0,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeColor: AppColors.primaryDark,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.fieldBorder.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipColor: (_) => AppColors.textDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        final label =
                            i < dayLabels.length ? dayLabels[i] : '';
                        return LineTooltipItem(
                          '$label\n${spot.y.toInt()} logs',
                          const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dayLabels[i],
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-user emotion type breakdown chips (used in detail sheet) ─────────────
class _EmotionBreakdownChips extends StatelessWidget {
  final Map<String, int> emotionByType;

  const _EmotionBreakdownChips({required this.emotionByType});

  static const _allEmotions = [
    'Happy', 'Calm', 'Tired', 'Anxious', 'Sad', 'Angry'
  ];
  static const _positiveEmotions = {'Happy', 'Calm'};
  static const _emotionEmoji = {
    'Happy': '😊',
    'Calm': '😌',
    'Tired': '😴',
    'Anxious': '😰',
    'Sad': '😢',
    'Angry': '😠',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allEmotions.map((emotion) {
        final count = emotionByType[emotion] ?? 0;
        final isPositive = _positiveEmotions.contains(emotion);
        final color = isPositive
            ? const Color(0xFF81B29A)
            : AppColors.textMedium;
        final emoji = _emotionEmoji[emotion] ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmoji(emoji, size: 13),
              const SizedBox(width: 5),
              Text(
                emotion,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                          size: 42, color: AppColors.textMedium),
                      SizedBox(height: 10),
                      Text('Admin session not found',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      SizedBox(height: 4),
                      Text('Please sign in again to view profile.',
                          style: TextStyle(color: AppColors.textMedium)),
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
                            CircularProgressIndicator(color: AppColors.primary));
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
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initialsFromName(displayName),
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
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
                                color: AppColors.primary,
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
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
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
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.settings,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Settings',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark)),
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
                              AppSettingsTile(
                                icon: Icons.notifications_active_outlined,
                                label: 'Notification Settings',
                                onTap: () => Navigator.pushNamed(
                                    context, '/admin-notifications-settings'),
                              ),
                              AppSettingsTile(
                                icon: Icons.shield_outlined,
                                label: 'Privacy',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/privacy'),
                              ),
                              AppSettingsTile(
                                icon: Icons.help_outline,
                                label: 'Help & Support',
                                onTap: () => Navigator.pushNamed(
                                    context, '/help-support'),
                              ),
                              AppSettingsTile(
                                icon: Icons.logout,
                                label: 'Log out',
                                isDestructive: true,
                                onTap: () async {
                                  await FCMService().clearTokenForCurrentUser();
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
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
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
                    color: AppColors.textMedium,
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
                    color: AppColors.textDark,
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

// ── Full-screen PDF preview screen ───────────────────────────────────────────

class _PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() buildPdf;

  const _PdfPreviewScreen({required this.title, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textDark,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: PdfPreview(
        build: (_) => buildPdf(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '${title.toLowerCase().replaceAll(' ', '_')}_'
            '${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      ),
    );
  }
}

// ── Per-user PDF export button (used in the Analytics tab detail sheet) ──────

class _ExportUserPdfButton extends StatefulWidget {
  final Map<String, dynamic> user;

  const _ExportUserPdfButton({required this.user});

  @override
  State<_ExportUserPdfButton> createState() => _ExportUserPdfButtonState();
}

class _ExportUserPdfButtonState extends State<_ExportUserPdfButton> {
  bool _loading = false;
  bool _previewing = false;

  String get _filename {
    final rawName = (widget.user['name'] as String? ?? 'user')
        .replaceAll(' ', '_')
        .toLowerCase();
    return 'mindmate_${rawName}_mood_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
  }

  Future<Uint8List> _generateBytes() =>
      context.read<AdminViewModel>().exportSingleUserMoodReport(widget.user);

  Future<void> _preview() async {
    setState(() => _previewing = true);
    try {
      final bytes = await _generateBytes();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            title: 'Mood Report',
            buildPdf: () async => bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final bytes = await _generateBytes();
      await Printing.sharePdf(bytes: bytes, filename: _filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _previewing;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: _previewing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.preview_rounded, size: 16),
            label: Text(_previewing ? 'Loading…' : 'Preview'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onPressed: busy ? null : _preview,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textDark),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(_loading ? 'Generating…' : 'Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onPressed: busy ? null : _export,
          ),
        ),
      ],
    );
  }
}
