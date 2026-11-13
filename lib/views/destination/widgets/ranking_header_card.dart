import '../../../core/localization/l10n.dart';
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
        Row(
          children: [
            const AppIcon(AppIcons.sparkles, color: AppColors.discovery),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.thisPlaceAndYou,
                style: AppTextStyles.cardTitle,
              ),
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
              Expanded(
                child: Text(
                  context.l10n.profileMatch,
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(switch (label.trim().toLowerCase()) {
          'recomendado' => context.l10n.recommended,
          'parcialmente recomendado' ||
          'parcialmente_recomendado' => context.l10n.partlyRecommended,
          'no recomendado' || 'no_recomendado' => context.l10n.notRecommended,
          _ => label,
        }, style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        Text(context.l10n.matchNotProbability, style: AppTextStyles.body2),
        if (rankPosition != null) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.rankForMonth(rankPosition!),
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
              title: Text(
                context.l10n.interpretResult,
                style: AppTextStyles.label,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.rankExplanation,
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
