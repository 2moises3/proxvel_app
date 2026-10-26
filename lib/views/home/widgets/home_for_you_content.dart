import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/recommendation_controller.dart';
import '../../../controllers/archive_controller.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cards/destination_recommendation_card.dart';
import '../../../core/widgets/states/empty_profile_for_ai_state.dart';
import 'month_fan_picker.dart';
import 'archive_loading_state.dart';
import 'recommendation_motion.dart';

class HomeForYouContent extends StatefulWidget {
  const HomeForYouContent({super.key});
  @override
  State<HomeForYouContent> createState() => _HomeForYouContentState();
}

class _HomeForYouContentState extends State<HomeForYouContent>
    with AutomaticKeepAliveClientMixin {
  final _entered = <String>{};
  int _revision = -1;
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<RecommendationController>();
    final archives = context.watch<ArchiveController>();
    if (_revision != controller.resultsRevision) {
      _revision = controller.resultsRevision;
      _entered.clear();
    }
    final eligible = controller.recommendations
        .where((r) => r.isEligible)
        .toList();
    final items = eligible
        .where((r) => !archives.isArchived(r.destination.id))
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          archives.loadArchives(),
          controller.loadRecommendations(forceRefresh: true),
        ]);
      },
      color: AppColors.discovery,
      child: CustomScrollView(
        key: const PageStorageKey('for-you-scroll'),
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => context.push('/profile/preferences'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.discovery,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 19),
                          label: const Text('Editar preferencias'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MonthFanPicker(
                        month: controller.selectedMonth,
                        onChanged: controller.setMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Destinos para ti',
                    style: AppTypography.style(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: const Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    !archives.hasLoaded
                        ? 'Recuperando tu selección…'
                        : controller.isLoading
                        ? 'Buscando coincidencias con tus preferencias…'
                        : '${items.length} ${items.length == 1 ? 'destino para explorar' : 'destinos para explorar'}',
                    style: AppTypography.style(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.isLoading) const RecommendationWorkingState(),
                  if (archives.hasLoaded && archives.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        archives.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (!archives.hasLoaded)
                    ArchiveLoadingState(controller: archives)
                  else if (controller.profileIncomplete)
                    const EmptyProfileForAiState()
                  else if (controller.error != null)
                    _message(
                      controller.error!,
                      'Reintentar',
                      () => controller.loadRecommendations(forceRefresh: true),
                    )
                  else if (!controller.isLoading && items.isEmpty)
                    _message(
                      eligible.isNotEmpty
                          ? 'Has ocultado estos destinos. Puedes recuperarlos desde Archivados.'
                          : 'No encontramos destinos recomendados con estas preferencias. Puedes probar otro mes o ajustar tus intereses.',
                      eligible.isNotEmpty
                          ? 'Ver archivados'
                          : 'Editar preferencias',
                      () => context.push(
                        eligible.isNotEmpty
                            ? '/archived'
                            : '/profile/preferences',
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (archives.hasLoaded && !controller.isLoading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final rec = items[index];
                  final entryKey =
                      '${controller.resultsRevision}/${rec.destination.id}';
                  final animate = _entered.add(entryKey);
                  return RecommendationArrival(
                    key: ValueKey(entryKey),
                    index: index,
                    animate: animate,
                    child: DestinationRecommendationCard(
                      recommendation: rec,
                      onTap: () {
                        final month = controller.selectedMonth;
                        context.push(
                          '/destination/${Uri.encodeComponent(rec.destination.id)}?source=ai_recommendation${month == null ? '' : '&month=$month'}',
                          extra: DestinationOpening(
                            rec.destination,
                            'recommendation',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.viewPaddingOf(context).bottom + 120,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (archives.hasLoaded && items.isNotEmpty) ...[
                    const Text(
                      'El clima y la afluencia se basan en datos históricos, no en un pronóstico. La recomendación orienta tu elección.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/archived'),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Gestionar destinos ocultos'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.discovery,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, String action, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
