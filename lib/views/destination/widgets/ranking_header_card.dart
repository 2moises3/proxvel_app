import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class RankingHeaderCard extends StatelessWidget {
  final int? rankPosition;
  final int compatibilityPercentage;
  final String label;
  const RankingHeaderCard({
    super.key,
    this.rankPosition,
    required this.compatibilityPercentage,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.card),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpace.field),
        Row(
          children: [
            Text(
              '$compatibilityPercentage%',
              style: AppTextStyles.h1.copyWith(color: AppColors.accent),
            ),
            const SizedBox(width: AppSpace.content),
            const Expanded(
              child: Text('Afinidad relativa', style: AppTextStyles.body2),
            ),
          ],
        ),
        if (rankPosition != null) ...[
          const SizedBox(height: AppSpace.related),
          Text('Posición #$rankPosition este mes', style: AppTextStyles.label),
        ],
        const SizedBox(height: AppSpace.related),
        const Text(
          'No indica una probabilidad de satisfacción.',
          style: AppTextStyles.body2,
        ),
        const SizedBox(height: AppSpace.related),
        const Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Entender mi afinidad', style: AppTextStyles.label),
            children: [
              Text(
                'La afinidad compara tus intereses y las valoraciones del modelo. El orden también considera el clima y la afluencia del mes; por eso puede diferir del porcentaje.',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
