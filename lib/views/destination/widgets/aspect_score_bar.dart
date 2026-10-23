import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../models/aspect_score_model.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal bar showing an aspect's score with label and percentage.
class AspectScoreBar extends StatelessWidget {
  final AspectScoreModel aspect;

  const AspectScoreBar({super.key, required this.aspect});

  @override
  Widget build(BuildContext context) {
    final barColor = _colorForScore(aspect.score);
    final tier = _tierForScore(aspect.score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForAspect(aspect.aspect),
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpace.related),
              Expanded(
                child: Text(
                  aspect.aspect,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: aspect.score,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForScore(double score) {
    if (score >= 0.70) return AppColors.success;
    if (score >= 0.50) return AppColors.accent;
    return AppColors.error;
  }

  /// Etiqueta de rango (en vez del % crudo) — coherente con la leyenda.
  String _tierForScore(double score) {
    if (score >= 0.70) return 'Excelente';
    if (score >= 0.50) return 'Bueno';
    return 'Bajo';
  }

  IconData _iconForAspect(String aspect) {
    final lower = aspect.toLowerCase();
    if (lower.contains('atractivo')) return Icons.photo_camera_outlined;
    if (lower.contains('costo')) return Icons.attach_money_rounded;
    if (lower.contains('seguridad')) return Icons.shield_outlined;
    if (lower.contains('accesibilidad')) return Icons.accessible_rounded;
    if (lower.contains('limpieza')) return Icons.cleaning_services_outlined;
    if (lower.contains('atención') || lower.contains('servicio')) return Icons.support_agent_rounded;
    if (lower.contains('gastronomía')) return Icons.restaurant_outlined;
    if (lower.contains('alojamiento')) return Icons.hotel_outlined;
    if (lower.contains('clima')) return Icons.wb_sunny_outlined;
    if (lower.contains('aforo') || lower.contains('multitud')) return Icons.groups_outlined;
    return Icons.info_outline_rounded;
  }
}
