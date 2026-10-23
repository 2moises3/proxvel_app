import 'package:flutter/material.dart';
import '../../core/navigation/destination_opening.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/destination_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/traveler_profile_model.dart';
import '../../models/destination_model.dart';
import '../../core/theme/app_colors.dart';
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
  /// Define la jerarquía de pestañas (info primero vs IA primero).
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
  final ScrollController _galleryScrollController = ScrollController();

  /// Orden de pestañas según el origen.
  /// - IA primaria: [IA, El lugar, Opiniones]
  /// - Catálogo/Búsqueda: [El lugar, Opiniones, IA] (IA al final)
  List<String> get _tabKeys =>
      widget.source == 'ai_recommendation' || widget.source == 'ai_search'
      ? const ['ai', 'about', 'reviews']
      : const ['about', 'reviews', 'ai'];

  String _tabLabel(String key) {
    switch (key) {
      case 'ai':
        return 'Para ti';
      case 'about':
        return 'El lugar';
      default:
        return 'Opiniones';
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
    _galleryScrollController.dispose();
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
      body: Stack(
        children: [
          // ── Scrollable content ──
          CustomScrollView(
            key: PageStorageKey(
              'destination/${widget.destinationId}/${widget.source}',
            ),
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══ HERO IMAGE ═══
              SliverAppBar(
                expandedHeight: (MediaQuery.sizeOf(context).height * 0.52)
                    .clamp(340.0, 420.0),
                collapsedHeight: 120,
                toolbarHeight: 120,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final currentHeight = constraints.maxHeight;
                    // El SliverAppBar incluye el padding del status bar en su altura mínima real
                    final minHeight =
                        120.0 + MediaQuery.of(context).padding.top;

                    // El carrusel desaparece primero
                    final double carouselOpacity =
                        ((currentHeight - (minHeight + 150)) / 100.0).clamp(
                          0.0,
                          1.0,
                        );

                    // El título principal y la ubicación desaparecen un poco después
                    final double largeTitleOpacity =
                        ((currentHeight - (minHeight + 50)) / 100.0).clamp(
                          0.0,
                          1.0,
                        );

                    // El título pequeño en la parte superior se vuelve 100% opaco exactamente al colapsar
                    final double smallTitleOpacity =
                        1.0 -
                        ((currentHeight - minHeight) / 60.0).clamp(0.0, 1.0);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          layoutBuilder:
                              (
                                Widget? currentChild,
                                List<Widget> previousChildren,
                              ) {
                                return Stack(
                                  fit: StackFit.expand,
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: AppMotion.curve,
                                  ),
                                  child: child,
                                );
                              },
                          child: GestureDetector(
                            key: ValueKey(_selectedImageUrl ?? dest.imageUrl),
                            onTap: () => _openGallery(dest),
                            child: DestinationHero(
                              tag:
                                  widget.opening?.destination.id == dest.id &&
                                      (_selectedImageUrl == null ||
                                          _selectedImageUrl == dest.imageUrl)
                                  ? widget.opening?.tag
                                  : null,
                              child: AdaptiveDestinationImage(
                                imagePath: _selectedImageUrl ?? dest.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay (Reducido para que no sea tan fuerte)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(
                                  alpha: 0.3,
                                ), // Un poco oscuro arriba para los botones
                                Colors.transparent,
                                Colors.black.withValues(
                                  alpha: 0.55,
                                ), // Mucho más claro que antes (0.8)
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),

                        // Fading Content (Title, Location, Carousel)
                        Stack(
                          fit: StackFit.expand,
                          children: [
                            // Title & Location
                            Positioned(
                              left: AppSpace.screen,
                              bottom: AppRadius.sheet + AppSpace.section,
                              right: AppSpace.screen,
                              child: Opacity(
                                opacity: largeTitleOpacity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dest.name,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 2),
                                            blurRadius: 6,
                                            color: Colors.black45,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.related),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: AppColors.accent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: AppSpace.micro),
                                        Expanded(
                                          child: Text(
                                            [dest.city, dest.region]
                                                .where(
                                                  (p) => p.trim().isNotEmpty,
                                                )
                                                .join(', '),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 4,
                                                  color: Colors.black45,
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Carrousel vertical de galería
                            if (dest.galleryImages.isNotEmpty)
                              Positioned(
                                right: 12,
                                top: MediaQuery.of(context).padding.top + 76,
                                child: Opacity(
                                  opacity: carouselOpacity,
                                  child: SizedBox(
                                    width: 72,
                                    child: _buildGalleryCarousel(
                                      dest.galleryImages,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Top actions (Back / Title / Favorite)
                        if (dest.imageUrl.isNotEmpty ||
                            dest.galleryImages.isNotEmpty)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 68,
                            left: 20,
                            child: TextButton.icon(
                              onPressed: () => _openGallery(dest),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: Text(
                                'Ver fotos (${(dest.imageUrl.isNotEmpty ? 1 : 0) + dest.galleryImages.length})',
                              ),
                            ),
                          ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _circleButton(
                                Icons.arrow_back_rounded,
                                () => context.pop(),
                              ),
                              Expanded(
                                child: Opacity(
                                  opacity: smallTitleOpacity,
                                  child: Text(
                                    dest.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 4,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Selector<FavoritesController, bool>(
                                    selector: (_, c) => c.isFavorite(dest.id),
                                    builder: (context, isFav, _) =>
                                        _circleButton(
                                          isFav
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          () => context
                                              .read<FavoritesController>()
                                              .toggleFavorite(dest.id, dest),
                                          iconColor: isFav
                                              ? AppColors.error
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpace.related),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // El remate curvo ya aporta el espacio superior del contenido.
                        Positioned(
                          bottom:
                              -1, // -1 para evitar líneas sutiles de renderizado
                          left: 0,
                          right: 0,
                          child: Container(
                            height: AppRadius.sheet + 1,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.sheet),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ═══ BODY ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    0,
                    AppSpace.screen,
                    AppSpace.section,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info badges ──
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _infoBadge(Icons.category_outlined, dest.category),
                          if (!controller.hasReviewsError &&
                              controller.reviews.isNotEmpty)
                            _infoBadge(
                              Icons.star_rounded,
                              '${controller.averageRating.toStringAsFixed(1)} según opiniones',
                            ),
                          if (controller.tourismInfo?.difficultyLabel != null)
                            _infoBadge(
                              Icons.hiking_rounded,
                              controller.tourismInfo!.difficultyLabel!,
                            ),
                          if (controller.tourismInfo?.costLabel != null)
                            _infoBadge(
                              Icons.payments_outlined,
                              'Gasto estimado: ${controller.tourismInfo!.costLabel!.replaceFirst('Costo ', '').toLowerCase()}',
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpace.card),

                      // ── Anuncio del destino (si el dashboard publicó uno) ──
                      AnnouncementBanner(
                        placement: 'destination_detail',
                        destinationId: widget.destinationId,
                        padding: const EdgeInsets.only(bottom: 20),
                      ),

                      // ── Tab selector ──
                      _buildTabSelector(),

                      const SizedBox(height: AppSpace.section),

                      // ── Tab content (según el orden definido por el origen) ──
                      AnimatedSwitcher(
                        duration: AppMotion.duration(context),
                        child: _buildTabContent(
                          _tabKeys[_selectedTabIndex],
                          controller,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _tabKeys.length; i++)
            Expanded(child: _tabItem(_tabLabel(_tabKeys[i]), i)),
        ],
      ),
    );
  }

  Widget _buildTabContent(String key, DestinationController controller) {
    switch (key) {
      case 'ai':
        return _buildWhyForMeContent(controller);
      case 'about':
        return _buildAboutDestinationContent(controller);
      default:
        return ReviewsTabContent(
          key: const ValueKey('reviews'),
          controller: controller,
        );
    }
  }

  Widget _tabItem(String title, int index) {
    final isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 38,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.related),
            AnimatedContainer(
              duration: AppMotion.duration(context),
              height: 3,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: isActive ? 0 : 30),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
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
    if (!controller.hasRecommendation) {
      return _buildNoRecommendationCard(
        hasProfile: travelerProfile?.isRecommendationReady == true,
      );
    }

    // Determine rank position from recommendations context
    // We don't have the list index here, so we pass null instead of a fake rank

    return WhyForMeTabContent(
      key: const ValueKey('why_for_me'),
      rankPosition: controller.rankingInfo?.rank,
      shapBase: controller.rankingInfo?.explanation?.shapBase,
      shapValues: controller.rankingInfo?.explanation?.shapValues ?? const {},
      compatibilityPercentage: controller.compatibility,
      label: controller.recommendationLabel ?? 'Recomendación personalizada',
      explanation: controller.explanation,
      topAspects: controller.recommendationTopAspects,
      aspectScores: controller.aspectScores,
      climaContextScore: controller.climaContextScore,
      climaContextLabel: controller.climaContextLabel,
      aforoContextScore: controller.aforoContextScore,
      aforoContextLabel: controller.aforoContextLabel,
      contextMonthName: controller.contextMonthName,
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
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.accent,
            size: 32,
          ),
          const SizedBox(height: AppSpace.content),
          Text(
            hasProfile
                ? 'Este destino aún no forma parte de tus recomendaciones personalizadas.'
                : 'Completa tu perfil viajero para ver qué tan compatible es este destino contigo.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          if (!hasProfile) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => context.push('/profile/preferences'),
              child: const Text('Completar mi perfil'),
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: (MediaQuery.sizeOf(context).height * .52).clamp(
            340.0,
            420.0,
          ),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: DestinationHero(
              tag: opening.tag,
              child: AdaptiveDestinationImage(
                imagePath: opening.destination.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpace.screen),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ),
      ],
    );
  }

  // ── Tab 1: El lugar ──
  Widget _buildAboutDestinationContent(DestinationController controller) {
    final dest = controller.destination!;

    // El calendario se personaliza con el clima y la tolerancia del perfil (si lo hay).
    TravelerProfileModel? profile;
    try {
      profile = context.read<ProfileController>().profile;
    } catch (_) {
      // ProfileController puede no estar en el árbol
    }

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
          tourismInfo: controller.tourismInfo,
        ),
        SeasonalitySection(
          key: ValueKey(
            '${dest.id}|${profile?.climaPreferido}|${profile?.toleranciaMultitudes}',
          ),
          destinationId: dest.id,
          clima: profile?.climaPreferido,
          tolerancia: profile?.toleranciaMultitudes,
        ),
      ],
    );
  }

  // ── Circle icon button (back, fav) ──
  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  // ── Info badge ──
  Widget _infoBadge(IconData icon, String text) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 40,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCarousel(List<String> images) {
    final currentImage =
        _selectedImageUrl ??
        context.read<DestinationController>().destination?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight:
              217, // Espacio para imágenes y padding (muestra ~3.5 elementos)
        ),
        child: RawScrollbar(
          controller: _galleryScrollController,
          thumbVisibility: true,
          thumbColor: Colors.white.withValues(alpha: 0.5),
          radius: const Radius.circular(8),
          thickness: 3,
          child: ListView.separated(
            controller: _galleryScrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.all(
              4,
            ), // El padding va adentro para que toda el área capture el scroll
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final isSelected = currentImage == images[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedImageUrl = images[i]),
                child: AnimatedContainer(
                  duration: AppMotion.duration(context),
                  width: isSelected ? 54 : 50,
                  height: isSelected ? 54 : 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AdaptiveDestinationImage(imagePath: images[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
