import 'dart:async';
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

  // The single in-flight top toast, if any. Tracked so a new message replaces
  // the current one instead of stacking (no pile-ups).
  static OverlayEntry? _current;

  static void _showCustomMessage(
    BuildContext context, {
    required MessageType type,
    required String title,
    String? message,
    VoidCallback? onAction,
    String actionLabel = 'Dismiss',
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = MyApp.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Remove any toast already on screen.
    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        type: type,
        title: title,
        message: message,
        onAction: onAction,
        actionLabel: actionLabel,
        duration: duration,
        backgroundColor: _getBackgroundColor(type),
        onDismissed: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
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

// Top-anchored animated toast. Slides down from the top so it never collides
// with the keyboard or the bottom nav bar. Auto-dismisses, tap-to-dismiss, and
// supports an optional action button.
class _TopToast extends StatefulWidget {
  final MessageType type;
  final String title;
  final String? message;
  final VoidCallback? onAction;
  final String actionLabel;
  final Duration duration;
  final Color backgroundColor;
  final VoidCallback onDismissed;

  const _TopToast({
    required this.type,
    required this.title,
    required this.message,
    required this.onAction,
    required this.actionLabel,
    required this.duration,
    required this.backgroundColor,
    required this.onDismissed,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (mounted) await _ctrl.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MessageContent(
                          type: widget.type,
                          title: widget.title,
                          message: widget.message,
                        ),
                      ),
                      if (widget.onAction != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            widget.onAction!();
                            _dismiss();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            widget.actionLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
