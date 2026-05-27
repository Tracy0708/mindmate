import 'package:flutter/material.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';
import '../main.dart';

enum MessageType { success, error, info, warning, confirmation }

class InteractiveMessageService {
  static void showSuccess(
    BuildContext context, {
    required String title,
    String? message,
    VoidCallback? onAction,
    String actionLabel = 'Dismiss',
    Duration duration = const Duration(seconds: 4),
  }) {
    _showCustomMessage(
      context,
      type: MessageType.success,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    String? message,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 5),
  }) {
    _showCustomMessage(
      context,
      type: MessageType.error,
      title: title,
      message: message,
      onAction: onRetry,
      actionLabel: retryLabel,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? message,
    VoidCallback? onAction,
    String actionLabel = 'Got it',
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomMessage(
      context,
      type: MessageType.info,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration,
    );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        icon: Icon(
          isDangerous ? Icons.warning_rounded : Icons.info_rounded,
          color: isDangerous ? AppColors.errorRed : AppColors.golden,
          size: 48,
        ),
        title: TwemojiText(
          text: title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
        content: TwemojiText(
          text: message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.brownMedium,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                color: AppColors.brownMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDangerous ? AppColors.errorRed : AppColors.golden,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDangerous ? Colors.white : AppColors.brownDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showCustomMessage(
    BuildContext context, {
    required MessageType type,
    required String title,
    String? message,
    VoidCallback? onAction,
    String actionLabel = 'Dismiss',
    Duration duration = const Duration(seconds: 4),
  }) {
    final snackBar = SnackBar(
      content: _MessageContent(
        type: type,
        title: title,
        message: message,
      ),
      backgroundColor: _getBackgroundColor(type),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      duration: duration,
      action: onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    MyApp.scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  static Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return const Color(0xFF4CAF50);
      case MessageType.error:
        return AppColors.errorRed;
      case MessageType.warning:
        return const Color(0xFFFFC107);
      case MessageType.info:
      case MessageType.confirmation:
        return AppColors.golden;
    }
  }
}

class _MessageContent extends StatelessWidget {
  final MessageType type;
  final String title;
  final String? message;

  const _MessageContent({
    required this.type,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getIcon(type),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TwemojiText(
                text: title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 4),
                TwemojiText(
                  text: message!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _getIcon(MessageType type) {
    IconData iconData;
    switch (type) {
      case MessageType.success:
        iconData = Icons.check_circle_rounded;
      case MessageType.error:
        iconData = Icons.error_rounded;
      case MessageType.warning:
        iconData = Icons.warning_rounded;
      case MessageType.info:
      case MessageType.confirmation:
        iconData = Icons.info_rounded;
    }
    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }
}
