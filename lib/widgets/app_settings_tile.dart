import 'package:flutter/material.dart';

import '../main.dart';

/// A single row in a settings list, shared by the user profile and the admin
/// profile tab so both surfaces stay visually identical.
///
/// Shows a leading icon, a label, and either a [trailingLabel] pill (e.g.
/// "On"/"Off"), a chevron, or nothing (for destructive actions like sign out).
class AppSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final bool isDestructive;
  final VoidCallback? onTap;

  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailingLabel,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : AppColors.textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive ? color : AppColors.textMedium, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingLabel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailingLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
            else if (!isDestructive)
              const Icon(Icons.chevron_right,
                  color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
