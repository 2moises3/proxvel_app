import 'widgets/destination_section_loading.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/navigation/destination_opening.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/destination_controller.dart';
import 'widgets/destination_cover.dart';
import '../../controllers/profile_controller.dart';
import '../../models/traveler_profile_model.dart';
import '../../models/destination_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common/app_icon.dart';
import '../../core/widgets/images/adaptive_destination_image.dart';
import '../../core/widgets/states/loading_view.dart';
import '../../core/widgets/announcements/announcement_banner.dart';
import 'widgets/why_for_me_tab_content.dart';
import 'widgets/about_destination_tab_content.dart';
import 'widgets/seasonality_section.dart';
import 'widgets/reviews_tab_content.dart';

class DestinationDetailScreen extends StatefulWidget {
  final String destinationId;
  final DestinationOpening? opening;

  /// Origen de navegación: explore | search | ai_recommendation | ai_search.
  /// Preserva el contexto de entrada; la recomendación va primero cuando se abre desde el motor.
  final String source;

  /// Mes objetivo (1-12) para clima/aforo. null = mes actual.
  /// Se sincroniza con el mes elegido en "Para Ti".
  final int? month;

  const DestinationDetailScreen({
    super.key,
    required this.destinationId,
    this.opening,
    this.source = 'explore',
    this.month,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int _selectedTabIndex = 0;
  String? _selectedImageUrl;
  bool _loadStarted = false;

  List<String> get _tabKeys => widget.source.startsWith('ai_')
      ? const ['ai', 'about', 'reviews']
      : const ['about', 'ai', 'reviews'];

  String _tabLabel(String key) {
    switch (key) {
      case 'ai':
        return 'Para ti';
      case 'about':
        return 'El lugar';
      default:
        return 'Reseñas';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  void _loadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _loadStarted = true);
      context.read<DestinationController>().loadDestination(
        widget.destinationId,
        month: widget.month,
      );
    });
  }

  @override
  void didUpdateWidget(covariant DestinationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationId != widget.destinationId ||
        oldWidget.month != widget.month ||
        oldWidget.source != widget.source) {
      _selectedTabIndex = 0;
      _selectedImageUrl = null;
      _loadStarted = false;
      _loadAfterFrame();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final controller = context.watch<DestinationController>();
    final dest = controller.destination;

    if (!_loadStarted || controller.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _openingPreview(),
      );
    }
    if (dest == null || dest.id != widget.destinationId) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  size: 44,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpace.field),
                Text(
                  controller.error ?? 'No pudimos abrir este destino.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpace.field),
                TextButton(
                  onPressed: () => controller.loadDestination(
                    widget.destinationId,
                    month: widget.month,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        key: PageStorageKey(
          'destination/${widget.destinationId}/${widget.source}',
        ),
        slivers: [
          SliverToBoxAdapter(
            child: DestinationCover(
              destination: dest,
              heroTag: widget.opening?.destination.id == dest.id
                  ? widget.opening?.tag
                  : null,
              latitude: controller.tourismInfo?.latitude ?? dest.latitude,
              longitude: controller.tourismInfo?.longitude ?? dest.longitude,
              rating: controller.hasReviewsError
                  ? null
                  : controller.averageRating,
              reviewCount: controller.hasReviewsError
                  ? 0
                  : controller.reviews.length,
              onOpenGallery: () => _openGallery(dest),
              onImageChanged: (url) => _selectedImageUrl = url,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _DestinationTabsHeader(
              topInset: MediaQuery.paddingOf(context).top,
              child: _buildTabSelector(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (MediaQuery.sizeOf(context).height -
                              MediaQuery.paddingOf(context).top -
                              138)
                          .clamp(0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnnouncementBanner(
                      placement: 'destination_detail',
                      destinationId: widget.destinationId,
                      padding: const EdgeInsets.only(bottom: 24),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.duration(context),
                      layoutBuilder: (current, previous) =>
                          current ?? const SizedBox.shrink(),
                      child: _buildTabContent(
                        _tabKeys[_selectedTabIndex],
                        controller,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        for (var i = 0; i < _tabKeys.length; i++)
          Expanded(
            child: Semantics(
              selected: _selectedTabIndex == i,
              child: TextButton(
                onPressed: () => setState(() => _selectedTabIndex = i),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  foregroundColor: _selectedTabIndex == i
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  backgroundColor: _selectedTabIndex == i
                      ? AppColors.accent
                      : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  _tabLabel(_tabKeys[i]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildTabContent(String key, DestinationController controller) {
    switch (key) {
      case 'ai':
        return _buildWhyForMeContent(controller);
      case 'about':
        return _buildAboutDestinationContent(controller);
      default:
        if (controller.isReviewsLoading) {
          return const DestinationSectionLoading(label: 'Cargando reseñas…');
        }
        return ReviewsTabContent(
          key: const ValueKey('reviews'),
          controller: controller,
          month: widget.month,
        );
    }
  }

  // ── Tab 0: Para ti ──
  Widget _buildWhyForMeContent(DestinationController controller) {
    // Try to get traveler profile if ProfileController is available
    TravelerProfileModel? travelerProfile;
    try {
      travelerProfile = context.read<ProfileController>().profile;
    } catch (_) {
      // ProfileController might not be in the tree
    }

    // Sin recomendación del motor (no hay perfil, o el destino aún no entra al motor):
    // no se inventa un porcentaje; se explica por qué.
    if (travelerProfile?.isRecommendationReady != true ||
        !controller.hasRecommendation) {
      return _buildNoRecommendationCard(
        hasProfile: travelerProfile?.isRecommendationReady == true,
      );
    }

    return Column(
      key: const ValueKey('personalized_detail'),
      children: [
        WhyForMeTabContent(
          key: const ValueKey('why_for_me'),
          rankPosition: controller.rankingInfo?.rank,
          shapBase: controller.rankingInfo?.explanation?.shapBase,
          shapValues:
              controller.rankingInfo?.explanation?.shapValues ?? const {},
          compatibilityPercentage: controller.compatibility,
          label:
              controller.recommendationLabel ?? 'Recomendación personalizada',
          explanation: controller.explanation,
          topAspects: controller.recommendationTopAspects,
          aspectScores: controller.aspectScores,
          climaContextScore: controller.climaContextScore,
          climaContextLabel: controller.climaContextLabel,
          aforoContextScore: controller.aforoContextScore,
          aforoContextLabel: controller.aforoContextLabel,
          contextMonthName: controller.contextMonthName,
        ),
        SeasonalitySection(
          initialMonth: widget.month,
          destinationId: widget.destinationId,
          clima: travelerProfile?.climaPreferido,
          tolerancia: travelerProfile?.toleranciaMultitudes,
        ),
      ],
    );
  }

  Widget _buildNoRecommendationCard({required bool hasProfile}) {
    return Container(
      key: const ValueKey('why_for_me_empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          const AppIcon(
            AppIcons.sparkles,
            color: AppColors.discovery,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            hasProfile
                ? 'Tu afinidad, cuando esté disponible'
                : 'Tu viaje merece algo más personal.',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpace.content),
          Text(
            hasProfile
                ? 'No tenemos un resultado del motor para mostrarte en este momento. Puedes volver a consultarlo.'
                : '¿Este lugar va contigo? Cuéntanos cómo te gusta viajar y descubre la afinidad, el clima y la afluencia según tus preferencias.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          if (hasProfile)
            TextButton(
              onPressed: () => context
                  .read<DestinationController>()
                  .loadDestination(widget.destinationId, month: widget.month),
              child: const Text('Volver a consultar'),
            ),
          if (!hasProfile) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () async {
                await context.push('/profile/preferences');
                if (mounted) {
                  await context.read<DestinationController>().loadDestination(
                    widget.destinationId,
                    month: widget.month,
                  );
                }
              },
              child: const Text('Descubrir mi afinidad'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _openingPreview() {
    final opening = widget.opening;
    if (opening == null || opening.destination.id != widget.destinationId) {
      return const LoadingView();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        DestinationHero(
          tag: opening.tag,
          child: AdaptiveDestinationImage(
            imagePath: opening.destination.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: BackButton(color: Colors.white),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ],
    );
  }

  // ── Tab 1: El lugar ──
  Widget _buildAboutDestinationContent(DestinationController controller) {
    final dest = controller.destination!;

    return Column(
      key: const ValueKey('about_destination'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.hasTourismError) ...[
          const Text(
            'No pudimos cargar toda la información para planificar la visita.',
            style: AppTextStyles.body2,
          ),
          TextButton(
            onPressed: () => controller.loadDestination(
              widget.destinationId,
              month: widget.month,
            ),
            child: const Text('Reintentar'),
          ),
          const SizedBox(height: AppSpace.field),
        ],
        AboutDestinationTabContent(
          destination: dest,
          isLoading: controller.isTourismLoading,
          tourismInfo: controller.tourismInfo,
        ),
      ],
    );
  }

  void _openGallery(DestinationModel destination) {
    final images = [
      destination.imageUrl,
      ...destination.galleryImages,
    ].where((url) => url.isNotEmpty).toList();
    if (images.isEmpty) return;
    var page = images.indexOf(_selectedImageUrl ?? destination.imageUrl);
    if (page < 0) page = 0;
    final pageController = PageController(initialPage: page);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: (index) => setDialogState(() => page = index),
                  itemBuilder: (context, index) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: AdaptiveDestinationImage(
                        imagePath: images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    tooltip: 'Cerrar galería',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Text(
                    '${page + 1} de ${images.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => pageController.dispose());
  }
}

/// Give the pinned selector a finite extent independently of AppBar's toolbar
/// and flexible-space layout, including when reassembled while scrolled.
class _DestinationTabsHeader extends SliverPersistentHeaderDelegate {
  const _DestinationTabsHeader({required this.topInset, required this.child});
  final double topInset;
  final Widget child;

  @override
  double get minExtent => 86 + topInset;
  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF9FAFB),
                  Color(0xE6F9FAFB),
                  Color(0x66F9FAFB),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topInset + 12, 24, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DestinationTabsHeader oldDelegate) =>
      topInset != oldDelegate.topInset || child != oldDelegate.child;
}
