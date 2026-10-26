import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common/app_icon.dart';

class RankingHeaderCard extends StatelessWidget {
  const RankingHeaderCard({
    super.key,
    this.rankPosition,
    required this.compatibilityPercentage,
    required this.label,
  });
  final int? rankPosition;
  final int compatibilityPercentage;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.discovery.withValues(alpha: .15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AppIcon(AppIcons.sparkles, color: AppColors.discovery),
            SizedBox(width: 8),
            Expanded(
              child: Text('Este lugar y tú', style: AppTextStyles.cardTitle),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0,
            end: (compatibilityPercentage / 100).clamp(0, 1),
          ),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: AppColors.discovery,
                        backgroundColor: AppColors.discovery.withValues(
                          alpha: .08,
                        ),
                      ),
                    ),
                    Text(
                      '$compatibilityPercentage%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: AppColors.discovery,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  'de afinidad con tu perfil',
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(label, style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        const Text(
          'Es una afinidad relativa calculada por el motor, no una probabilidad de satisfacción.',
          style: AppTextStyles.body2,
        ),
        if (rankPosition != null) ...[
          const SizedBox(height: 12),
          Text(
            'Posición $rankPosition en el contexto del mes',
            style: AppTextStyles.bodySecondary,
          ),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: const PageStorageKey('destination-affinity/interpretation'),
              shape: Border(),
              collapsedShape: Border(),
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Cómo interpretar este resultado',
                style: AppTextStyles.label,
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'La afinidad combina tus intereses y las valoraciones del modelo. El orden también considera el clima y la afluencia del mes; por eso puede diferir del porcentaje.',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
