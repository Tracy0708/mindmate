import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/local_notification_service.dart';
import '../../main.dart';

class AdminNotificationSettingsScreen extends StatefulWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  State<AdminNotificationSettingsScreen> createState() =>
      _AdminNotificationSettingsScreenState();
}

class _AdminNotificationSettingsScreenState
    extends State<AdminNotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  // Toggle states
  bool _masterToggle = true;
  bool _highRiskAlerts = true;
  bool _abnormalBehavior = true;
  bool _newSignups = false;
  bool _systemReports = true;
  String _reportTime = '18:00';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final profile = await _authService.getUserProfile();
    if (profile != null && mounted) {
      final prefs =
          profile.settings['adminNotificationPrefs'] as Map<String, dynamic>? ?? {};
      final time = profile.settings['adminReportTime'] as String? ?? '18:00';
      setState(() {
        _highRiskAlerts = prefs['highRiskAlerts'] ?? true;
        _abnormalBehavior = prefs['abnormalBehavior'] ?? true;
        _newSignups = prefs['newSignups'] ?? false;
        _systemReports = prefs['systemReports'] ?? true;
        _masterToggle = _highRiskAlerts ||
            _abnormalBehavior ||
            _newSignups ||
            _systemReports;
        _reportTime = time;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'settings.adminNotificationPrefs': {
          'highRiskAlerts': _masterToggle ? _highRiskAlerts : false,
          'abnormalBehavior': _masterToggle ? _abnormalBehavior : false,
          'newSignups': _masterToggle ? _newSignups : false,
          'systemReports': _masterToggle ? _systemReports : false,
        },
        'settings.adminReportTime': _reportTime,
      });
    }

    final parts = _reportTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 18;
    final minute = int.tryParse(parts[1]) ?? 0;

    await LocalNotificationService().applyAdminPreferences(
      masterEnabled: _masterToggle,
      highRiskAlerts: _highRiskAlerts,
      newSignups: _newSignups,
      systemReports: _systemReports,
      abnormalBehavior: _abnormalBehavior,
      hour: hour,
      minute: minute,
    );
  }

  void _onMasterToggle(bool val) {
    setState(() {
      _masterToggle = val;
      if (!val) {
        _highRiskAlerts = false;
        _abnormalBehavior = false;
        _newSignups = false;
        _systemReports = false;
      } else {
        _highRiskAlerts = true;
        _abnormalBehavior = true;
        _newSignups = false; // default false for noise
        _systemReports = true;
      }
    });
    _savePreferences();
  }

  void _onSubToggle(String key, bool val) {
    setState(() {
      switch (key) {
        case 'highRiskAlerts':
          _highRiskAlerts = val;
          break;
        case 'abnormalBehavior':
          _abnormalBehavior = val;
          break;
        case 'newSignups':
          _newSignups = val;
          break;
        case 'systemReports':
          _systemReports = val;
          break;
      }
      _masterToggle = _highRiskAlerts ||
          _abnormalBehavior ||
          _newSignups ||
          _systemReports;
    });
    _savePreferences();
  }

  Future<void> _pickReportTime() async {
    final parts = _reportTime.split(':');
    final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18, minute: int.tryParse(parts[1]) ?? 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: AppColors.textDark,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _reportTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _savePreferences();
    }
  }

  String get _formattedTime {
    final parts = _reportTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 18;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12
        ? hour - 12
        : hour == 0
            ? 12
            : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  int get _enabledCount => [
        _highRiskAlerts,
        _abnormalBehavior,
        _newSignups,
        _systemReports,
      ].where((value) => value).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin Notifications',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.fieldBorder.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alert Summary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _masterToggle
                                    ? '$_enabledCount alert types active'
                                    : 'All admin alerts are paused',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Master Toggle Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _masterToggle
                                ? Icons.notifications_active
                                : Icons.notifications_off_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('All Alerts',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text(
                                _masterToggle
                                    ? 'You will receive admin alerts'
                                    : 'All alerts are off',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMedium),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _masterToggle,
                          activeThumbColor: AppColors.primary,
                          onChanged: _onMasterToggle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Granular Toggles Section
                  const Text('Alert Types',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  const Text(
                    'Select which events trigger a push notification to your device.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _NotificationToggle(
                          icon: Icons.warning_rounded,
                          iconColor: AppColors.errorRed,
                          title: 'High Risk Alerts',
                          subtitle: 'Users flagged with severe negative mood',
                          value: _highRiskAlerts,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('highRiskAlerts', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.gpp_maybe_rounded,
                          iconColor: const Color(0xFFDD8A00),
                          title: 'Abnormal Behavior',
                          subtitle: 'Unusual platform activity or anomalies',
                          value: _abnormalBehavior,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('abnormalBehavior', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.person_add_alt_1_rounded,
                          iconColor: const Color(0xFF26A69A),
                          title: 'New Signups',
                          subtitle: 'When a new user creates an account',
                          value: _newSignups,
                          enabled: _masterToggle,
                          onChanged: (v) => _onSubToggle('newSignups', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.analytics_rounded,
                          iconColor: const Color(0xFF5C6BC0),
                          title: 'System Reports',
                          subtitle: 'Daily platform health and usage summary',
                          value: _systemReports,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('systemReports', v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Report Time Section
                  const Text('Daily Report Time',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  const Text(
                    'When should we send your daily system overview?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: (_masterToggle && _systemReports) ? _pickReportTime : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: (_masterToggle && _systemReports) ? 1.0 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.access_time,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Report Time',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark)),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to change',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMedium),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formattedTime,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
