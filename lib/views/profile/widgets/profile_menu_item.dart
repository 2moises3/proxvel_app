import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';

/// A single tappable row in the profile menu.
class ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuItem({
    super.key,
    this.icon,
    this.svgIcon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  }) : assert(
         icon != null || svgIcon != null,
         'Either icon or svgIcon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: svgIcon != null
                    ? AppIcon(svgIcon!, color: color, size: 20)
                    : Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            AppIcon(
              AppIcons.chevronRight,
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
