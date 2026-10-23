import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/aspect_score_model.dart';
import '../../../core/theme/app_colors.dart';

/// Grid-style aspect score display showing icon + aspect name + percentage
/// in a 2-column layout, matching the prototype design.
class AspectScoreGrid extends StatelessWidget {
  final List<AspectScoreModel> aspects;

  const AspectScoreGrid({super.key, required this.aspects});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // V3 presenta tres aspectos legibles a ancho completo.
        if (aspects.length <= 3)
          for (final aspect in aspects) _AspectScoreRow(aspect: aspect),
        if (aspects.length > 3)
        for (int i = 0; i < aspects.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < aspects.length ? 4 : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _AspectScoreRow(aspect: aspects[i]),
                ),
                if (i + 1 < aspects.length)
                  Expanded(
                    child: _AspectScoreRow(aspect: aspects[i + 1]),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),

        const SizedBox(height: AppSpace.field),

        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _legendDot(AppColors.success, 'Fortaleza (≥ 70%)'),
            _legendDot(AppColors.accent, 'Oportunidad (50 – 69%)'),
            _legendDot(AppColors.error, 'Bajo (< 50%)'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpace.micro),
        Flexible(child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        )),
      ],
    );
  }
}

/// Single row item in the aspect score grid.
class _AspectScoreRow extends StatelessWidget {
  final AspectScoreModel aspect;

  const _AspectScoreRow({required this.aspect});

  @override
  Widget build(BuildContext context) {
    final color = _colorForScore(aspect.score);
    final tier = _tierForScore(aspect.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForAspect(aspect.aspect),
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  aspect.aspect,
                  style: AppTextStyles.smallLabel,
                ),
              ),
              const SizedBox(width: AppSpace.micro),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.related),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: aspect.score,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
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
    if (lower.contains('atención') || lower.contains('servicio')) {
      return Icons.support_agent_rounded;
    }
    if (lower.contains('gastronomía')) return Icons.restaurant_outlined;
    if (lower.contains('alojamiento')) return Icons.hotel_outlined;
    if (lower.contains('clima')) return Icons.wb_sunny_outlined;
    if (lower.contains('aforo') || lower.contains('multitud')) {
      return Icons.groups_outlined;
    }
    return Icons.info_outline_rounded;
  }
}
