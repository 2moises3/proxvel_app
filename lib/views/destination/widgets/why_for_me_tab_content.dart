import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import '../../../models/seasonality_model.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/aspect_score_model.dart';
import 'aspect_score_grid.dart';
import '../../../core/widgets/common/app_icon.dart';
import 'ranking_header_card.dart';

/// La explicación personalizada viene del motor. Los aspectos de reseñas y el
/// contexto mensual se presentan por separado para no atribuirles pesos falsos.
class WhyForMeTabContent extends StatelessWidget {
  final int? rankPosition;
  final double? shapBase;
  final Map<String, double> shapValues;
  final int compatibilityPercentage;
  final String label;
  final String explanation;
  final List<String> topAspects;
  final List<AspectScoreModel> aspectScores;
  final double? climaContextScore;
  final String? climaContextLabel;
  final double? aforoContextScore;
  final String? aforoContextLabel;
  final String? contextMonthName;

  const WhyForMeTabContent({
    super.key,
    this.rankPosition,
    this.shapBase,
    this.shapValues = const {},
    required this.compatibilityPercentage,
    required this.label,
    required this.explanation,
    required this.topAspects,
    required this.aspectScores,
    this.climaContextScore,
    this.climaContextLabel,
    this.aforoContextScore,
    this.aforoContextLabel,
    this.contextMonthName,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        expansionTileTheme: ExpansionTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RankingHeaderCard(
            rankPosition: rankPosition,
            compatibilityPercentage: compatibilityPercentage,
            label: label,
          ),
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.section),
            _title(context.l10n.howItMatches),
            const SizedBox(height: AppSpace.content),
            Text(explanation, style: AppTextStyles.bodySecondary),
          ],
          if (topAspects.isNotEmpty && aspectScores.isEmpty) ...[
            const SizedBox(height: AppSpace.section),
            _title(context.l10n.whatCounts),
            const SizedBox(height: AppSpace.content),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final aspect in topAspects)
                  Chip(
                    label: Text(context.aspectLabel(aspect)),
                    backgroundColor: AppColors.discovery.withValues(
                      alpha: 0.06,
                    ),
                    side: BorderSide.none,
                    labelStyle: AppTextStyles.smallLabel,
                  ),
              ],
            ),
          ],
          if (climaContextScore != null || aforoContextScore != null) ...[
            const SizedBox(height: AppSpace.section),
            _title(
              contextMonthName == null
                  ? context.l10n.monthlyContext
                  : _monthContextTitle(context, contextMonthName!),
            ),
            const SizedBox(height: AppSpace.content),
            Text(
              context.l10n.historicalValues,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.content),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (climaContextScore != null)
                  _contextChip(
                    context,
                    AppIcons.calendar,
                    context.l10n.weather,
                    climaContextLabel,
                    climaContextScore!,
                  ),
                if (aforoContextScore != null)
                  _contextChip(
                    context,
                    AppIcons.navProfile,
                    context.l10n.crowdTolerance,
                    aforoContextLabel,
                    aforoContextScore!,
                  ),
              ],
            ),
          ],
          if (shapBase != null && shapValues.isNotEmpty) ...[
            const SizedBox(height: AppSpace.section),
            ExpansionTile(
              key: const PageStorageKey(
                'destination-affinity/model-contributions',
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              initiallyExpanded: true,
              leading: const AppIcon(
                AppIcons.sliders,
                color: AppColors.discovery,
              ),
              title: Text(
                context.l10n.howRanked,
                style: AppTextStyles.cardTitle,
              ),
              children: [
                Text(
                  context.l10n.scoreContributions,
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppSpace.content),
                for (final entry in shapValues.entries)
                  _contribution(context, entry),
                const SizedBox(height: AppSpace.related),
                Text(
                  'Referencia: ${shapBase!.toStringAsFixed(3)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.content),
              ],
            ),
          ],
          if (aspectScores.isNotEmpty) ...[
            const SizedBox(height: AppSpace.section),
            ExpansionTile(
              key: const PageStorageKey(
                'destination-affinity/review-reference',
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                context.l10n.referenceRatings,
                style: AppTextStyles.cardTitle,
              ),
              subtitle: Text(
                context.l10n.pricesServiceAttractions,
                style: AppTextStyles.body2,
              ),
              children: [
                Text(
                  context.l10n.reviewPerceptions,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.content),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: AspectScoreGrid(aspects: aspectScores),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _contribution(BuildContext context, MapEntry<String, double> entry) {
    final maximum = shapValues.values.fold<double>(
      0,
      (largest, v) => v.abs() > largest ? v.abs() : largest,
    );
    final fraction = maximum == 0 ? 0.0 : entry.value.abs() / maximum;
    final positive = entry.value >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  {
                        'afinidad': context.l10n.uiAfinidadConTuPerfil,
                        'clima': context.l10n.uiClimaDelMes,
                        'afluencia': context.l10n.crowdTolerance,
                      }[entry.key] ??
                      entry.key,
                  style: AppTextStyles.label,
                ),
              ),
              Text(
                '${positive ? '+' : ''}${entry.value.toStringAsFixed(3)}',
                style: AppTextStyles.label,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 16,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.discovery.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: AppColors.textMuted),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 600),
                    builder: (_, value, _) => Align(
                      alignment: positive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: positive ? constraints.maxWidth / 2 : 0,
                          right: positive ? 0 : constraints.maxWidth / 2,
                        ),
                        child: Align(
                          alignment: positive
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            width: constraints.maxWidth / 2 * value,
                            height: 10,
                            decoration: BoxDecoration(
                              color: positive
                                  ? AppColors.discovery
                                  : AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
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

  Widget _title(String text) => Text(text, style: AppTextStyles.sectionTitle);

  String _monthContextTitle(BuildContext context, String month) {
    if (context.l10n.localeName != 'en') return 'Contexto de $month';
    final index = kMonthNames.indexOf(month.toLowerCase());
    return index < 0 ? context.l10n.monthlyContext : 'Conditions in ${context.fullMonth(index + 1)}';
  }

  Widget _contextChip(
    BuildContext context,
    String icon,
    String title,
    String? label,
    double score,
  ) {
    final percentage = (score * 100).round().clamp(0, 100);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - AppSpace.screen * 2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 22, color: AppColors.discovery),
            const SizedBox(width: AppSpace.related),
            Flexible(
              child: Text(
                '$title: ${label?.trim().isNotEmpty == true ? label : '$percentage / 100'}',
                style: AppTextStyles.smallLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
