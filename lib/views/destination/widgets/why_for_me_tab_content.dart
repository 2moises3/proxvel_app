import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/aspect_score_model.dart';
import 'aspect_score_grid.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RankingHeaderCard(
          rankPosition: rankPosition,
          compatibilityPercentage: compatibilityPercentage,
          label: label,
        ),
        if (explanation.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpace.section),
          _title('Cómo encaja contigo'),
          const SizedBox(height: AppSpace.content),
          Text(explanation, style: AppTextStyles.bodySecondary),
        ],
        if (topAspects.isNotEmpty && aspectScores.isEmpty) ...[
          const SizedBox(height: AppSpace.section),
          _title('Lo que se tiene en cuenta'),
          const SizedBox(height: AppSpace.content),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final aspect in topAspects)
                Chip(
                  label: Text(aspect),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
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
                ? 'Contexto del mes'
                : 'Contexto de $contextMonthName',
          ),
          const SizedBox(height: AppSpace.content),
          Text(
            'Valores históricos del mes; no son un pronóstico ni el puntaje final.',
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
                  Icons.wb_sunny_outlined,
                  'Clima',
                  climaContextLabel,
                  climaContextScore!,
                ),
              if (aforoContextScore != null)
                _contextChip(
                  context,
                  Icons.groups_outlined,
                  'Afluencia según tu tolerancia',
                  aforoContextLabel,
                  aforoContextScore!,
                ),
            ],
          ),
        ],
        if (shapBase != null && shapValues.isNotEmpty) ...[
          const SizedBox(height: AppSpace.section),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Cómo se ordena este destino',
              style: AppTextStyles.cardTitle,
            ),
            children: [
              const Text(
                'Aportes respecto a una referencia del modelo. Un valor positivo eleva el puntaje; uno negativo lo reduce. No son probabilidades.',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: AppSpace.content),
              for (final entry in shapValues.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          {
                                'afinidad': 'Afinidad con tu perfil',
                                'clima': 'Clima del mes',
                                'afluencia': 'Afluencia según tu tolerancia',
                              }[entry.key] ??
                              entry.key,
                        ),
                      ),
                      Text(
                        '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(3)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
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
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Valoraciones de referencia',
              style: AppTextStyles.cardTitle,
            ),
            subtitle: const Text(
              'Precios, atención y atractivos',
              style: AppTextStyles.body2,
            ),
            children: [
              const Text(
                'Percepciones agregadas del conjunto de reseñas del modelo; no representan tarifas ni condiciones garantizadas.',
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
    );
  }

  Widget _title(String text) => Text(text, style: AppTextStyles.sectionTitle);

  Widget _contextChip(
    BuildContext context,
    IconData icon,
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
            Icon(icon, size: 18, color: AppColors.accent),
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
