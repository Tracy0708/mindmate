import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../main.dart';
import '../services/interactive_message_service.dart';

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
      setState(() {
        _dailyMoodReminder = prefs['dailyMoodReminder'] ?? true;
        _breathingReminder = prefs['breathingReminder'] ?? true;
        _weeklySummary = prefs['weeklySummary'] ?? true;
        _motivationalQuotes = prefs['motivationalQuotes'] ?? true;
        _masterToggle = _dailyMoodReminder ||
            _breathingReminder ||
            _weeklySummary ||
            _motivationalQuotes;
        _reminderTime = time;
        _isLoading = false;
      });
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
    await _authService.updateNotificationPrefs(prefs);
    await _authService.updateReminderTime(_reminderTime);

    // Schedule real device notifications
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
    });
    _savePreferences();
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
    });
    _savePreferences();
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.golden,
                  onPrimary: Colors.white,
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
      });
      _savePreferences();
    }
  }

  String get _formattedTime {
    final parts = _reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
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
        _dailyMoodReminder,
        _breathingReminder,
        _weeklySummary,
        _motivationalQuotes,
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
              color: AppColors.brownDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.golden)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.golden))
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
                        color: AppColors.fieldBorder.withOpacity(0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.golden.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tips_and_updates_outlined,
                            color: AppColors.golden,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reminder summary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _masterToggle
                                    ? '$_enabledCount notification types active at $_formattedTime'
                                    : 'Notifications are currently paused',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brownMedium,
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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.golden.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _masterToggle
                                ? Icons.notifications_active
                                : Icons.notifications_off_outlined,
                            color: AppColors.golden,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('All Notifications',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brownDark)),
                              const SizedBox(height: 4),
                              Text(
                                _masterToggle
                                    ? 'You will receive reminders'
                                    : 'All notifications are off',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.brownMedium),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _masterToggle,
                          activeThumbColor: AppColors.golden,
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
                          color: AppColors.brownDark)),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose which reminders are actually helpful so the app stays supportive instead of noisy.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brownMedium,
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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _NotificationToggle(
                          icon: Icons.mood,
                          iconColor: const Color(0xFFFFB300),
                          title: 'Daily Mood Reminder',
                          subtitle: 'Remind you to log your mood each day',
                          value: _dailyMoodReminder,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('dailyMoodReminder', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.air,
                          iconColor: const Color(0xFF26A69A),
                          title: 'Breathing Exercise',
                          subtitle: 'Guided breathing session reminders',
                          value: _breathingReminder,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('breathingReminder', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.bar_chart,
                          iconColor: const Color(0xFF5C6BC0),
                          title: 'Weekly Summary',
                          subtitle: 'A weekly report of your progress',
                          value: _weeklySummary,
                          enabled: _masterToggle,
                          onChanged: (v) => _onSubToggle('weeklySummary', v),
                        ),
                        const Divider(height: 1, indent: 68),
                        _NotificationToggle(
                          icon: Icons.format_quote,
                          iconColor: const Color(0xFFE91E63),
                          title: 'Motivational Quotes',
                          subtitle: 'Daily inspirational quotes',
                          value: _motivationalQuotes,
                          enabled: _masterToggle,
                          onChanged: (v) =>
                              _onSubToggle('motivationalQuotes', v),
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
                          color: AppColors.brownDark)),
                  const SizedBox(height: 6),
                  const Text(
                    'Your daily mood reminder and breathing reminder follow this time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brownMedium,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _masterToggle ? _pickReminderTime : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _masterToggle ? 1.0 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.golden.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.access_time,
                                  color: AppColors.golden, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Reminder Time',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brownDark)),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to change',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.brownMedium),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.golden.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formattedTime,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.golden),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await LocalNotificationService().showTestNotification();
                        if (mounted) {
                          InteractiveMessageService.showSuccess(
                            context,
                            title: 'Test notification sent! 🔔',
                            message: 'Check your notification bar',
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active, size: 20),
                      label: const Text('Send Test Notification',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golden,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                color: iconColor.withOpacity(0.15),
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
                          color: AppColors.brownDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.brownMedium)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.golden,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
