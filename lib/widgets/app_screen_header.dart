import 'package:flutter/material.dart';

import '../main.dart';

/// The single screen header used across MindMate screens (rendered inside the
/// body, not as an AppBar).
///
/// Layout: an optional rounded back button, an optional small [eyebrow] line
/// (used for home greetings), a bold left-aligned [title], an optional one-line
/// [subtitle], and an optional [trailing] widget (e.g. a notification bell or a
/// "Mark all read" action).
class AppScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.showBack = false,
    this.trailing,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.pop(context)),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null && eyebrow!.isNotEmpty)
                      Text(
                        eyebrow!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark, size: 22),
        ),
      ),
    );
  }
}
