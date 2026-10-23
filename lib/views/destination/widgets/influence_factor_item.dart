import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_colors.dart';

/// Displays a key influence factor with icon and description.
/// Used in the "Factores que más influyen" section.
class InfluenceFactorItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  /// Color del factor (verde = fortaleza, ámbar = oportunidad, rojo = a tener
  /// en cuenta). Por defecto, el acento de la marca.
  final Color? color;

  const InfluenceFactorItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: AppSpace.content),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
