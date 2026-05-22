import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

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
      case 'high_risk':
        return Icons.warning_rounded;
      case 'abnormal':
        return Icons.gpp_maybe_rounded;
      case 'new_signup':
        return Icons.person_add_alt_1_rounded;
      case 'system':
        return Icons.analytics_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'high_risk':
        return AppColors.errorRed;
      case 'abnormal':
        return const Color(0xFFDD8A00);
      case 'new_signup':
        return const Color(0xFF26A69A);
      case 'system':
        return const Color(0xFF5C6BC0);
      default:
        return AppColors.golden;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final service = NotificationService();

    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        backgroundColor: AppColors.creamLight,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brownDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => service.markAllAsRead(uid),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.golden,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(
              child: Text('Not signed in.',
                  style: TextStyle(color: AppColors.brownMedium)))
          : StreamBuilder<List<NotificationModel>>(
              stream: service.getUserNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.golden));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load notifications.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.brownMedium),
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 52, color: AppColors.brownLight),
                        SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brownDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.brownMedium),
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
                                    color: AppColors.golden,
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
                                        color: AppColors.brownDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.notificationMessage,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.brownMedium,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(n.notificationTimestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.brownLight,
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
                                    color: AppColors.golden,
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
    );
  }
}
