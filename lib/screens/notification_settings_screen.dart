import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/interactive_message_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_notification_toggle.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // Toggle states
  bool _masterToggle = true;
  bool _dailyMoodReminder = true;
  bool _breathingReminder = true;
  bool _weeklySummary = true;
  bool _motivationalQuotes = true;
  String _reminderTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final profile = await _authService.getUserProfile();
    if (profile != null && mounted) {
      final prefs =
          profile.settings['notificationPrefs'] as Map<String, dynamic>? ?? {};
      final time = profile.settings['reminderTime'] as String? ?? '09:00';
      final dailyMood = prefs['dailyMoodReminder'] ?? true;
      final breathing = prefs['breathingReminder'] ?? true;
      final weekly = prefs['weeklySummary'] ?? true;
      final motivational = prefs['motivationalQuotes'] ?? true;
      setState(() {
        _dailyMoodReminder = dailyMood;
        _breathingReminder = breathing;
        _weeklySummary = weekly;
        _motivationalQuotes = motivational;
        _masterToggle = dailyMood || breathing || weekly || motivational;
        _reminderTime = time;
        _isLoading = false;
      });
      // Delete stale preference-reminder placeholder documents that older app
      // versions wrote into the notifications collection. They are configuration
      // state, not received notifications, and no longer belong there.
      await NotificationService()
          .deletePreferenceReminderPlaceholders(profile.userID);

      // Re-apply the schedule on the device so that notifications survive
      // a fresh install or reinstall without the user having to toggle anything.
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      await LocalNotificationService().applyPreferences(
        masterEnabled: dailyMood || breathing || weekly || motivational,
        dailyMood: dailyMood,
        breathing: breathing,
        weeklySummary: weekly,
        motivational: motivational,
        hour: hour,
        minute: minute,
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = <String, bool>{
      'dailyMoodReminder': _masterToggle ? _dailyMoodReminder : false,
      'breathingReminder': _masterToggle ? _breathingReminder : false,
      'weeklySummary': _masterToggle ? _weeklySummary : false,
      'motivationalQuotes': _masterToggle ? _motivationalQuotes : false,
    };
    if (mounted) setState(() => _isSaving = true);
    try {
      await _authService.updateNotificationPrefs(prefs);
      await _authService.updateReminderTime(_reminderTime);
    } catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Save failed',
          message: 'Connection timed out. Please check your internet and try again.',
          onRetry: _savePreferences,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
      InteractiveMessageService.showSuccess(
        context,
        title: 'Settings saved',
        message: 'Your notification preferences have been updated.',
      );
    }

    // Schedule real device notifications — local only, no network needed
    final parts = _reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    await LocalNotificationService().applyPreferences(
      masterEnabled: _masterToggle,
      dailyMood: _dailyMoodReminder,
      breathing: _breathingReminder,
      weeklySummary: _weeklySummary,
      motivational: _motivationalQuotes,
      hour: hour,
      minute: minute,
    );
  }

  void _onMasterToggle(bool val) {
    setState(() {
      _masterToggle = val;
      if (!val) {
        _dailyMoodReminder = false;
        _breathingReminder = false;
        _weeklySummary = false;
        _motivationalQuotes = false;
      } else {
        _dailyMoodReminder = true;
        _breathingReminder = true;
        _weeklySummary = true;
        _motivationalQuotes = true;
      }
      _hasUnsavedChanges = true;
    });
  }

  void _onSubToggle(String key, bool val) {
    setState(() {
      switch (key) {
        case 'dailyMoodReminder':
          _dailyMoodReminder = val;
          break;
        case 'breathingReminder':
          _breathingReminder = val;
          break;
        case 'weeklySummary':
          _weeklySummary = val;
          break;
        case 'motivationalQuotes':
          _motivationalQuotes = val;
          break;
      }
      _masterToggle = _dailyMoodReminder ||
          _breathingReminder ||
          _weeklySummary ||
          _motivationalQuotes;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
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
        _reminderTime =
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
        content: const Text(
            'You have unsaved notification settings. Discard them?'),
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

  String get _formattedTime => _offsetTime(0);

  String _offsetTime(int plusMinutes) {
    final parts = _reminderTime.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = int.tryParse(parts[1]) ?? 0;
    final total = h * 60 + m + plusMinutes;
    final newH = (total ~/ 60) % 24;
    final newM = total % 60;
    final period = newH >= 12 ? 'PM' : 'AM';
    final displayH = newH > 12 ? newH - 12 : newH == 0 ? 12 : newH;
    return '$displayH:${newM.toString().padLeft(2, '0')} $period';
  }

  int get _enabledCount => [
        _dailyMoodReminder,
        _breathingReminder,
        _weeklySummary,
        _motivationalQuotes,
      ].where((v) => v).length;

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
                title: 'Notifications',
                subtitle: 'Tune what reaches you and when.',
                icon: Icons.tune_rounded,
                showBack: true,
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reminder summary card
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
                                            Icons.tips_and_updates_outlined,
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
                                                'Reminder summary',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _masterToggle
                                                    ? '$_enabledCount type${_enabledCount == 1 ? '' : 's'} active · first at $_formattedTime'
                                                    : 'Notifications are currently paused',
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
                                          child: Icon(
                                            _masterToggle
                                                ? Icons.notifications_active
                                                : Icons
                                                    .notifications_off_outlined,
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
                                              const Text('All Notifications',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.textDark)),
                                              const SizedBox(height: 4),
                                              Text(
                                                _masterToggle
                                                    ? 'You will receive reminders'
                                                    : 'All notifications are off',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textMedium),
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
                                  const Text('Notification Types',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark)),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Pick which reminders you want.',
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
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        AppNotificationToggle(
                                          icon: Icons.mood,
                                          iconColor: const Color(0xFFFFB300),
                                          title: 'Daily Mood Reminder',
                                          subtitle:
                                              'Log your mood each day · $_formattedTime',
                                          value: _dailyMoodReminder,
                                          enabled: _masterToggle,
                                          onChanged: (v) =>
                                              _onSubToggle('dailyMoodReminder', v),
                                        ),
                                        AppNotificationToggle(
                                          icon: Icons.air,
                                          iconColor: const Color(0xFF26A69A),
                                          title: 'Breathing Exercise',
                                          subtitle:
                                              'Guided breathing session · ${_offsetTime(30)}',
                                          value: _breathingReminder,
                                          enabled: _masterToggle,
                                          onChanged: (v) =>
                                              _onSubToggle('breathingReminder', v),
                                        ),
                                        AppNotificationToggle(
                                          icon: Icons.bar_chart,
                                          iconColor: const Color(0xFF5C6BC0),
                                          title: 'Weekly Summary',
                                          subtitle:
                                              'Weekly progress report · Sundays at $_formattedTime',
                                          value: _weeklySummary,
                                          enabled: _masterToggle,
                                          onChanged: (v) =>
                                              _onSubToggle('weeklySummary', v),
                                        ),
                                        AppNotificationToggle(
                                          icon: Icons.format_quote,
                                          iconColor: const Color(0xFFE91E63),
                                          title: 'Motivational Quotes',
                                          subtitle:
                                              'Daily inspiration · ${_offsetTime(5)}',
                                          value: _motivationalQuotes,
                                          enabled: _masterToggle,
                                          onChanged: (v) => _onSubToggle(
                                              'motivationalQuotes', v),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Reminder Time Section
                                  const Text('Reminder Time',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark)),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Mood reminder fires at this time. Inspiration +5 min, Breathing +30 min.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMedium,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _masterToggle
                                        ? _pickReminderTime
                                        : null,
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity: _masterToggle ? 1.0 : 0.5,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                                              padding:
                                                  const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                  Icons.access_time,
                                                  color: AppColors.primary,
                                                  size: 28),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Daily Reminder Time',
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textDark)),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Tap to change',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textMedium),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
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
                                      onPressed: (_hasUnsavedChanges &&
                                              !_isSaving)
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
