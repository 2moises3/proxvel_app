import 'package:flutter/material.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Contenido de la pestaña "Explorar" — catálogo abierto.
/// Solo muestra secciones que tienen datos reales. Nunca rellena la pantalla
/// con datos inventados ni con mocks.
class HomeExploreContent extends StatefulWidget {
  final VoidCallback onSwitchToForYou;

  const HomeExploreContent({super.key, required this.onSwitchToForYou});

  @override
  State<HomeExploreContent> createState() => _HomeExploreContentState();
}

class _HomeExploreContentState extends State<HomeExploreContent> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final archiveCtrl = context
        .watch<import_archive_controller.ArchiveController>();
    final recommendations = context
        .watch<RecommendationController>()
        .globalRecommendations;
    final personalizeOrder =
        context.watch<ProfileController>().profile?.applyAiGlobally == true;

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
    final categories = controller.categories;
    final recent = controller.recentSearches;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<HomeController>().loadDestinations();
        if (context.mounted) {
          await context.read<AnnouncementController>().refresh(
            placement: 'home_top',
          );
        }
      },
      child: SingleChildScrollView(
        key: const PageStorageKey('explore-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpace.card),

            // ═══ SEARCH BAR ═══
            _buildSearchBar(context),
            const SizedBox(height: AppSpace.card),

            // ═══ ANUNCIO INTERNO (si hay) ═══
            const AnnouncementBanner(),

            // ═══ ERROR (si el backend falló) ═══
            if (controller.error != null && all.isEmpty) ...[
              _buildError(controller.error!),
              const SizedBox(height: AppSpace.section),
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

            // ═══ CATEGORÍAS (reales) movidas arriba ═══
            if (categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: Text(
                  'Explora nuevos horizontes',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              const SizedBox(height: AppSpace.field),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.screen,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpace.related),
                  itemBuilder: (_, i) =>
                      _categoryChip(context, categories[i], i == 0),
                ),
              ),
              const SizedBox(height: AppSpace.group),
            ],

            // ═══ DESTINOS DESTACADOS (Coverflow Carousel) ═══
            if (featured.isNotEmpty) ...[
              CoverflowCarousel(
                destinations: featured,
                onDestinationTap: (dest) => context.push(
                  '/destination/${dest.id}?source=explore',
                  extra: DestinationOpening(dest, 'coverflow'),
                ),
              ),
              const SizedBox(height: AppSpace.group),
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

            const SizedBox(height: AppSpace.group),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(left: 24, right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(width: AppSpace.field),
              Expanded(
                child: Text(
                  '¿A dónde viajas hoy?',
                  style: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
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
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String category, bool isFirst) {
    return GestureDetector(
      onTap: () =>
          context.push('/search?category=${Uri.encodeComponent(category)}'),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        decoration: BoxDecoration(
          color: isFirst ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isFirst ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
            color: isFirst ? Colors.white : AppColors.textPrimary,
          ),
        ),
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
