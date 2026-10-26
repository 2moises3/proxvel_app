import 'package:flutter/material.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/recommendation_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/announcement_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/announcements/announcement_banner.dart';
import '../../../core/widgets/cards/recent_search_chip.dart';
import '../../../core/widgets/carousels/coverflow_carousel.dart';
import '../../../controllers/archive_controller.dart'
    as import_archive_controller;
import 'home_discovery_sections.dart';
import 'archive_loading_state.dart';
import '../../../models/recommendation_result_model.dart';

/// Contenido de la pestaña "Explorar" — catálogo abierto.
/// Solo muestra secciones que tienen datos reales. Nunca rellena la pantalla
/// con datos inventados ni con mocks.
class HomeExploreContent extends StatefulWidget {
  final VoidCallback onSwitchToForYou;

  const HomeExploreContent({super.key, required this.onSwitchToForYou});

  @override
  State<HomeExploreContent> createState() => _HomeExploreContentState();
}

class _HomeExploreContentState extends State<HomeExploreContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<HomeController>();
    final archiveCtrl = context
        .watch<import_archive_controller.ArchiveController>();
    if (!archiveCtrl.hasLoaded) {
      return SingleChildScrollView(
        child: ArchiveLoadingState(controller: archiveCtrl),
      );
    }
    final personalizeOrder =
        context.watch<ProfileController>().profile?.applyAiGlobally == true;
    final recommendations = personalizeOrder
        ? context.select<
            RecommendationController,
            List<RecommendationResultModel>
          >((c) => c.globalRecommendations)
        : const <RecommendationResultModel>[];

    final all = controller.allDestinations
        .where((d) => !archiveCtrl.isArchived(d.id))
        .toList();
    if (personalizeOrder && recommendations.isNotEmpty) {
      final scoreById = {
        for (final entry in recommendations.asMap().entries)
          entry.value.destination.id: entry.key,
      };
      all.sort((a, b) {
        final aScore = scoreById[a.id];
        final bScore = scoreById[b.id];
        if (aScore == null && bScore == null) return 0;
        if (aScore == null) return 1;
        if (bScore == null) return -1;
        return aScore.compareTo(bScore);
      });
    }
    final featured = all.take(5).toList();
    final recent = controller.recentSearches;

    return RefreshIndicator(
      onRefresh: () async {
        await archiveCtrl.loadArchives();
        if (!context.mounted) return;
        await context.read<HomeController>().refreshDestinations();
        if (context.mounted) {
          await context.read<AnnouncementController>().refresh(
            placement: 'home_top',
          );
        }
      },
      child: SingleChildScrollView(
        key: const PageStorageKey('explore-scroll'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 102,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ ANUNCIO INTERNO (si hay) ═══
            const AnnouncementBanner(),

            // ═══ ERROR (si el backend falló) ═══
            if (controller.error != null && all.isEmpty) ...[
              _buildError(controller.error!),
              const SizedBox(height: AppSpace.section),
            ],

            // Baraja del catálogo, sin etiquetas de popularidad inventadas.
            if (featured.isNotEmpty) ...[
              CoverflowCarousel(
                destinations: featured,
                onDestinationTap: (dest) => context.push(
                  '/destination/${Uri.encodeComponent(dest.id)}?source=explore',
                  extra: DestinationOpening(dest, 'coverflow'),
                ),
              ),
              const SizedBox(height: AppSpace.group),
            ],

            // ═══ BÚSQUEDAS RECIENTES ═══
            if (recent.isNotEmpty) ...[
              _sectionHeader('Búsquedas recientes'),
              const SizedBox(height: AppSpace.content),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.screen,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpace.content),
                  itemBuilder: (_, i) => RecentSearchChip(
                    destination: recent[i],
                    onTap: () => context.push(
                      '/search?q=${Uri.encodeComponent(recent[i].name)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Secciones editoriales derivadas del catálogo y del motor real.
            if (all.isNotEmpty) ...[
              HomeDiscoverySections(
                destinations: all,
                recommendations: recommendations,
                onOpenForYou: widget.onSwitchToForYou,
                onOpenDestination: (destination) => context.push(
                  '/destination/${Uri.encodeComponent(destination.id)}?source=explore',
                ),
                onOpenCategory: (category) => context.push(
                  '/search?category=${Uri.encodeComponent(category)}',
                ),
                onOpenCatalog: () => context.push('/search'),
              ),
            ] else if (controller.error == null) ...[
              _buildEmpty(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section header ──
  Widget _sectionHeader(String title, {VoidCallback? onSeeMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
          if (onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                'Ver más',
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error state ──
  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.error),
            const SizedBox(width: AppSpace.content),
            Expanded(
              child: Text(
                'No se pudieron cargar los destinos.\n$message',
                style: AppTextStyles.body2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
      child: Column(
        children: [
          Icon(
            Icons.travel_explore_rounded,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpace.field),
          const Text(
            'Aún no hay destinos disponibles',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpace.related),
          const Text(
            'El catálogo se mostrará aquí cuando haya destinos publicados.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }
}
