import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/interactive_message_service.dart';
import '../../services/local_notification_service.dart';
import '../../main.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/app_notification_toggle.dart';

class AdminNotificationSettingsScreen extends StatefulWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  State<AdminNotificationSettingsScreen> createState() =>
      _AdminNotificationSettingsScreenState();
}

class _AdminNotificationSettingsScreenState
    extends State<AdminNotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final settings = data['settings'] as Map<String, dynamic>? ?? {};
        final prefs =
            settings['adminNotificationPrefs'] as Map<String, dynamic>? ?? {};
        final time = settings['adminReportTime'] as String? ?? '18:00';
        final parts = time.split(':');
        final hour = int.tryParse(parts[0]) ?? 18;
        final minute = int.tryParse(parts[1]) ?? 0;
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
        await LocalNotificationService().applyAdminPreferences(
          masterEnabled: _masterToggle,
          highRiskAlerts: _highRiskAlerts,
          newSignups: _newSignups,
          systemReports: _systemReports,
          abnormalBehavior: _abnormalBehavior,
          hour: hour,
          minute: minute,
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (mounted) setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'settings.adminNotificationPrefs': {
          'highRiskAlerts': _masterToggle ? _highRiskAlerts : false,
          'abnormalBehavior': _masterToggle ? _abnormalBehavior : false,
          'newSignups': _masterToggle ? _newSignups : false,
          'systemReports': _masterToggle ? _systemReports : false,
        },
        'settings.adminReportTime': _reportTime,
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Save failed',
          message:
              'Connection timed out. Please check your internet and try again.',
          onRetry: _savePreferences,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
      InteractiveMessageService.showSuccess(
        context,
        title: 'Settings saved',
        message: 'Your admin alert preferences have been updated.',
      );
    }
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
        _newSignups = false;
        _systemReports = true;
      }
      _hasUnsavedChanges = true;
    });
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
      _masterToggle =
          _highRiskAlerts || _abnormalBehavior || _newSignups || _systemReports;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickReportTime() async {
    final parts = _reportTime.split(':');
    final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18,
        minute: int.tryParse(parts[1]) ?? 0);

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
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _onPopAttempt() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content:
            const Text('You have unsaved alert settings. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  String get _formattedTime {
    final parts = _reportTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 18;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayH = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$displayH:${minute.toString().padLeft(2, '0')} $period';
  }

  int get _enabledCount => [
        _highRiskAlerts,
        _abnormalBehavior,
        _newSignups,
        _systemReports,
      ].where((v) => v).length;

  String get _summaryText {
    if (!_masterToggle) return 'All admin alerts are paused';
    if (_systemReports) {
      return '$_enabledCount active · report at $_formattedTime, rest real-time';
    }
    return '$_enabledCount active · all real-time';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              const AppScreenHeader(
                title: 'Admin Notifications',
                subtitle: 'Choose which alerts reach you.',
                icon: Icons.notifications_active_rounded,
                showBack: true,
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Alert summary card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.fieldBorder
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          _summaryText,
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
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              fontSize: 13,
                                              color: AppColors.textMedium),
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
                              'Pick which events alert you.',
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
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  AppNotificationToggle(
                                    icon: Icons.warning_rounded,
                                    iconColor: AppColors.errorRed,
                                    title: 'High Risk Alerts',
                                    subtitle:
                                        'Real-time · 3 consecutive negative mood days',
                                    value: _highRiskAlerts,
                                    enabled: _masterToggle,
                                    onChanged: (v) =>
                                        _onSubToggle('highRiskAlerts', v),
                                  ),
                                  AppNotificationToggle(
                                    icon: Icons.gpp_maybe_rounded,
                                    iconColor: const Color(0xFFDD8A00),
                                    title: 'Abnormal Behavior',
                                    subtitle:
                                        'Real-time · unusual platform activity',
                                    value: _abnormalBehavior,
                                    enabled: _masterToggle,
                                    onChanged: (v) =>
                                        _onSubToggle('abnormalBehavior', v),
                                  ),
                                  AppNotificationToggle(
                                    icon: Icons.person_add_alt_1_rounded,
                                    iconColor: const Color(0xFF26A69A),
                                    title: 'New Signups',
                                    subtitle:
                                        'Real-time · triggers on every new account',
                                    value: _newSignups,
                                    enabled: _masterToggle,
                                    onChanged: (v) =>
                                        _onSubToggle('newSignups', v),
                                  ),
                                  AppNotificationToggle(
                                    icon: Icons.analytics_rounded,
                                    iconColor: const Color(0xFF5C6BC0),
                                    title: 'System Reports',
                                    subtitle: 'Scheduled daily · $_formattedTime',
                                    value: _systemReports,
                                    enabled: _masterToggle,
                                    onChanged: (v) =>
                                        _onSubToggle('systemReports', v),
                                  ),
                                  // Crisis alerts are permanently active — not toggleable
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.errorRed
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.sos_rounded,
                                            color: AppColors.errorRed,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Crisis Alerts',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Real-time · crisis language detected in chat',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorRed
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Always on',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.errorRed,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                              'When to send the daily overview.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: (_masterToggle && _systemReports)
                                  ? _pickReportTime
                                  : null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: (_masterToggle && _systemReports)
                                    ? 1.0
                                    : 0.5,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.access_time,
                                            color: AppColors.primary, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                            const SizedBox(height: 32),

                            // Save button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    (_hasUnsavedChanges && !_isSaving)
                                        ? _savePreferences
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.fieldBorder,
                                  foregroundColor: AppColors.textDark,
                                  disabledForegroundColor:
                                      AppColors.textMedium,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.textDark,
                                        ),
                                      )
                                    : Text(
                                        _hasUnsavedChanges
                                            ? 'Save Changes'
                                            : 'Saved',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
