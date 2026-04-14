import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../main.dart';
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
          _AdminHomeTab(onNavigate: _navigateToTab),
          const UserManagementScreen(),
          _UsageAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
            selectedIndex: _selectedTab,
            onDestinationSelected: _navigateToTab,
            height: 65,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.golden), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppColors.golden), label: 'Users'),
              NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment, color: AppColors.golden), label: 'Analytics'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  final Function(int) onNavigate;

  const _AdminHomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Consumer<AdminViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) return const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator()));
            final report = vm.usageReport;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Center(
                  child: Text('Admin Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.golden)),
                ),
                const SizedBox(height: 28),

                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(value: '${report?['totalUsers'] ?? 0}', label: 'Total Users', color: AppColors.golden),
                    _StatCard(value: '${report?['totalUsers'] ?? 0}', label: 'Active Users', color: AppColors.golden),
                    _StatCard(value: '${report?['totalLogs'] ?? 0}', label: "Today's Logs", color: AppColors.brownDark),
                    _StatCard(value: '${((report?['totalLogs'] ?? 0) as int) > 0 ? ((report?['totalLogs'] as int) / 2).round() : 0}', label: 'Reports', color: AppColors.brownDark),
                  ],
                ),
                const SizedBox(height: 32),

                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.people_rounded,
                        label: 'User Management',
                        onTap: () => onNavigate(1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.insights_rounded,
                        label: 'Usage Analytics',
                        onTap: () => onNavigate(2),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.brownMedium, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.golden.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.golden),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
          ],
        ),
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
          children: [
            const SizedBox(height: 8),
            const Center(
              child: Text('Usage Analytics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.golden)),
            ),
            const SizedBox(height: 28),

            // Filters Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterDropdown(label: 'Date Range', value: 'Last 30 Days'),
                  SizedBox(height: 16),
                  _FilterDropdown(label: 'User Group', value: 'All Users'),
                  SizedBox(height: 16),
                  _FilterDropdown(label: 'Key Metric', value: 'Engagement'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stat Cards
            const _StatMetricCard(
              icon: Icons.people, iconColor: AppColors.golden,
              title: 'Total Active Users', value: '2,847', trend: '↑ 12.5% vs last month', isPositiveMatch: true,
            ),
            const _StatMetricCard(
              icon: Icons.insights, iconColor: AppColors.golden,
              title: 'Avg. Daily Active Users', value: '1,234', trend: '↑ 8.2% vs last month', isPositiveMatch: true,
            ),
            const _StatMetricCard(
              icon: Icons.access_time_filled, iconColor: AppColors.golden,
              title: 'Avg. Session Duration', value: '12:45', trend: '↑ 5.2% vs last month', isPositiveMatch: true,
            ),
            const _StatMetricCard(
              icon: Icons.mood, iconColor: AppColors.golden,
              title: 'Mood Log Completion', value: '89%', trend: '↓ 2.1% vs last month', isPositiveMatch: false,
            ),
            const SizedBox(height: 24),

            // Export button
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, color: AppColors.golden),
              label: const Text('Export Report', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.golden, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Trends / Chart mockup
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User\nEngagement\nTrends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                  const SizedBox(height: 24),
                  Container(height: 6, color: AppColors.golden, margin: const EdgeInsets.only(bottom: 12)),
                  Container(height: 6, color: Colors.green, margin: const EdgeInsets.only(bottom: 12, right: 40)),
                  Container(height: 6, color: Colors.blue, margin: const EdgeInsets.only(bottom: 12, right: 80)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Table Mockup
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700),
                  dataTextStyle: const TextStyle(color: AppColors.brownMedium),
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Active\nUsers')),
                    DataColumn(label: Text('Mood\nLogs')),
                    DataColumn(label: Text('Avg. Mood\nScore')),
                    DataColumn(label: Text('Chatbot\nSessions')),
                  ],
                  rows: const [
                    DataRow(cells: [DataCell(Text('May 24')), DataCell(Text('1,200')), DataCell(Text('800')), DataCell(Text('3.2')), DataCell(Text('400'))]),
                    DataRow(cells: [DataCell(Text('May 25')), DataCell(Text('1,350')), DataCell(Text('950')), DataCell(Text('3.2')), DataCell(Text('450'))]),
                    DataRow(cells: [DataCell(Text('May 26')), DataCell(Text('1,100')), DataCell(Text('750')), DataCell(Text('3.1')), DataCell(Text('350'))]),
                    DataRow(cells: [DataCell(Text('May 27')), DataCell(Text('1,400')), DataCell(Text('1,000')), DataCell(Text('3.2')), DataCell(Text('500'))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
        Text(label, style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700)),
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
              const Icon(Icons.keyboard_arrow_down, color: AppColors.brownMedium),
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

  const _StatMetricCard({required this.icon, required this.iconColor, required this.title, required this.value, required this.trend, required this.isPositiveMatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brownDark, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brownDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(trend, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPositiveMatch ? Colors.green : AppColors.errorRed)),
        ],
      ),
    );
  }
}
