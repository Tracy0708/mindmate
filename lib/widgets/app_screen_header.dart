import 'package:flutter/material.dart';

import '../main.dart';

/// The single screen header used across MindMate screens (rendered inside the
/// body, not as an AppBar).
///
/// Layout is a single row: an optional rounded back button, an optional [icon]
/// badge (a rounded square tinted with the primary color, like the section
/// headers), then the text block — an optional small [eyebrow] line (used for
/// home greetings), a bold [title], and an optional one-line [subtitle] — and
/// finally an optional [trailing] widget (e.g. a notification bell or a
/// "Mark all read" action).
class AppScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final bool showBack;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.showBack = false,
    this.icon,
    this.trailing,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.pop(context)),
            const SizedBox(width: 12),
          ],
          if (icon != null) ...[
            _HeaderIcon(icon: icon!),
            const SizedBox(width: 12),
          ],
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
                // Auto-shrink: keep the title on one line and scale the font
                // down only when it would otherwise overflow — never ellipsize.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // Subtitle wraps fully (no ellipsis) so it is always visible.
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
    );
  }
}

/// The rounded-square icon badge shown to the left of the title — a larger
/// sibling of the admin section headers, tinted with the primary color.
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
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
