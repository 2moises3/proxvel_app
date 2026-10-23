import 'package:flutter/material.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/recommendation_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/destination_recommendation_card.dart';
import '../../../core/widgets/states/ai_ranking_loader.dart';
import '../../../core/widgets/states/ai_ranking_skeleton.dart';
import '../../../core/widgets/states/empty_profile_for_ai_state.dart';
import '../../../controllers/archive_controller.dart'
    as import_archive_controller;
import 'profile_summary_card.dart';

/// Scrollable content for the "Para Ti" tab, showing personalized recommendations.
class HomeForYouContent extends StatelessWidget {
  const HomeForYouContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecommendationController>();
    final archiveCtrl = context
        .watch<import_archive_controller.ArchiveController>();
    final userName =
        context.watch<AuthController>().currentUser?.fullName ?? 'Viajero';

    if (controller.isLoading && controller.recommendations.isEmpty) {
      return const AiRankingLoader();
    }

    final filteredRecs = controller.recommendations
        .where((r) => !archiveCtrl.isArchived(r.destination.id))
        .take(3)
        .toList();

    if (filteredRecs.isEmpty) {
      final err = controller.error;
      // Caso perfil incompleto (o sin error): empty state honesto con acción.
      final isProfileIssue = controller.profileIncomplete;
      if (isProfileIssue) {
        return const EmptyProfileForAiState();
      }
      return _errorState(
        context,
        err ??
            'No hay destinos disponibles con estos filtros. Prueba otra región.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadRecommendations(forceRefresh: true),
      color: AppColors.accent,
      child: SingleChildScrollView(
        key: const PageStorageKey('for-you-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpace.section),

            // ── Profile Summary Card ──
            ProfileSummaryCard(userName: userName),

            // ── Background Refresh Error Banner ──
            if (controller.error != null &&
                controller.recommendations.isNotEmpty) ...[
              const SizedBox(height: AppSpace.field),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: AppSpace.content),
                      const Expanded(
                        child: Text(
                          'No pudimos actualizar tus recomendaciones. Inténtalo otra vez.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpace.group),

            // ── Section Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Destinos para ti', style: AppTextStyles.h2),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${filteredRecs.length} lugares seleccionados',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.field),

            // ── Selector de mes (clima/aforo del mes objetivo) ──
            _MonthSelectorBar(selected: controller.selectedMonth),
            const SizedBox(height: AppSpace.field),

            // ── Recommendation cards ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: controller.isLoading
                    ? Column(
                        key: const ValueKey('skeletons'),
                        children: List.generate(
                          3,
                          (index) => const AiRankingSkeletonCard(),
                        ),
                      )
                    : Column(
                        key: const ValueKey('cards'),
                        children: filteredRecs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final rec = entry.value;
                          return DestinationRecommendationCard(
                            recommendation: rec,
                            index: index,
                            onTap: () {
                              // Lleva el mes elegido al detalle, para que clima/aforo allí
                              // muestren la misma temporada que el ranking.
                              final m = controller.selectedMonth;
                              final q = m != null ? '&month=$m' : '';
                              context.push(
                                '/destination/${rec.destination.id}?source=ai_recommendation$q',
                                extra: DestinationOpening(
                                  rec.destination,
                                  'recommendation',
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),
            ),

            const SizedBox(height: AppSpace.group),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String error) {
    final controller = context.read<RecommendationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.screen),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 40,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpace.field),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpace.field),
          TextButton(
            onPressed: () => controller.loadRecommendations(forceRefresh: true),
            child: const Text('Reintentar'),
          ),
          if (controller.selectedRegion != null)
            TextButton(
              onPressed: () => controller.setRegion(null),
              child: const Text('Ver todas las regiones'),
            ),
        ],
      ),
    );
  }
}

/// Barra horizontal para elegir el mes objetivo del viaje.
/// Al tocar un mes, recarga las recomendaciones con el clima/aforo de ese mes.
class _MonthSelectorBar extends StatelessWidget {
  final int? selected;
  const _MonthSelectorBar({required this.selected});

  static const _names = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<RecommendationController>();
    final activeMonth = selected ?? DateTime.now().month;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 10),
          child: Text(
            '¿Para qué mes viajas?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.related),
            itemBuilder: (context, i) {
              final month = i + 1;
              final isSel = activeMonth == month;
              return GestureDetector(
                onTap: () => ctrl.setMonth(month),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: isSel
                          ? AppColors.accent
                          : AppColors.textSecondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    _names[i],
                    style: TextStyle(
                      color: isSel ? Colors.white : AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
