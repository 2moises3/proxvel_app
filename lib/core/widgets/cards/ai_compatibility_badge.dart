import 'package:flutter/material.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_colors.dart';

/// Insignia discreta de compatibilidad IA.
/// Solo debe usarse cuando existe un porcentaje real calculado por el backend
/// y la preferencia de IA aplica. Nunca mostrar un valor inventado.
class AiCompatibilityBadge extends StatelessWidget {
  final int compatibility;

  /// `compact` = versión pequeña para esquinas de cards de catálogo.
  final bool compact;

  const AiCompatibilityBadge({
    super.key,
    required this.compatibility,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: compact ? 11 : 13, color: AppColors.accent),
          const SizedBox(width: AppSpace.micro),
          Text(
            '$compatibility% afinidad',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
