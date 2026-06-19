import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/app_screen_header.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'crisis_flag':
        return Icons.crisis_alert_rounded;
      case 'high_risk':
        return Icons.warning_rounded;
      case 'abnormal':
        return Icons.gpp_maybe_rounded;
      case 'new_signup':
        return Icons.person_add_alt_1_rounded;
      case 'system':
      case 'system_report':
        return Icons.analytics_rounded;
      case 'daily_mood_reminder':
        return Icons.mood_rounded;
      case 'breathing_reminder':
        return Icons.air_rounded;
      case 'weekly_summary':
        return Icons.bar_chart_rounded;
      case 'motivational_quote':
        return Icons.format_quote_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'crisis_flag':
        return AppColors.errorRed;
      case 'high_risk':
        return AppColors.errorRed;
      case 'abnormal':
        return const Color(0xFFDD8A00);
      case 'new_signup':
        return const Color(0xFF26A69A);
      case 'system':
      case 'system_report':
        return const Color(0xFF5C6BC0);
      case 'daily_mood_reminder':
        return AppColors.primary;
      case 'breathing_reminder':
        return const Color(0xFF26A69A);
      case 'weekly_summary':
        return const Color(0xFF5C6BC0);
      case 'motivational_quote':
        return const Color(0xFFE91E63);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final service = NotificationService();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Notifications',
              subtitle: 'Quiet, useful, never noisy',
              icon: Icons.notifications_rounded,
              showBack: true,
              trailing: uid == null
                  ? null
                  : Tooltip(
                      message: 'Mark all read',
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => service.markAllAsRead(uid),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(Icons.done_all_rounded,
                                  color: AppColors.textDark, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: uid == null
                  ? const Center(
                      child: Text('Not signed in.',
                          style: TextStyle(color: AppColors.textMedium)))
                  : StreamBuilder<List<NotificationModel>>(
              stream: service.getUserNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load notifications.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMedium),
                      ),
                    ),
                  );
                }

                // Exclude preference-reminder placeholder documents — these are
                // configuration records, not received notifications.
                const reminderTypes = {
                  'daily_mood_reminder',
                  'breathing_reminder',
                  'weekly_summary',
                  'motivational_quote',
                };
                final notifications = (snapshot.data ?? [])
                    .where((n) => !reminderTypes.contains(n.notificationType))
                    .toList();

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 52, color: AppColors.textLight),
                        SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.fieldBorder),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final isUnread = n.notificationStatus == 'unread';
                    final color = _colorFor(n.notificationType);

                    return Dismissible(
                      key: Key(n.notificationID),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.errorRed,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      onDismissed: (_) =>
                          service.deleteNotification(n.notificationID),
                      child: InkWell(
                        onTap: isUnread
                            ? () => service.markAsRead(n.notificationID)
                            : null,
                        child: Container(
                          color: isUnread ? Colors.white : AppColors.creamLight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isUnread)
                                Container(
                                  width: 3,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                              else
                                const SizedBox(width: 15),
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconFor(n.notificationType),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.notificationMessage,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMedium,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(n.notificationTimestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4, left: 8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
}
