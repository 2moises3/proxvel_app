import 'dart:ui';
import '../../core/widgets/maps/destination_location.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_layout.dart';
import '../../controllers/notifications_controller.dart';
import '../main/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/announcement_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/archive_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/announcements/announcement_modal.dart';
import '../../core/widgets/announcements/announcement_style.dart';
import '../legal/terms_gate_overlay.dart';
import '../../core/legal/legal_texts.dart';
import '../../models/announcement_model.dart';
import 'widgets/home_explore_content.dart';
import 'widgets/explore_hero.dart';
import 'widgets/home_for_you_content.dart';
import '../../core/widgets/common/app_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HomeController _homeController;
  bool _startModalShown = false;
  bool _startAnnouncementResolved = false;
  AnnouncementModel? _startAnnouncement;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _homeController = context.read<HomeController>();
    _homeController.addListener(_onHomeControllerUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_homeController.destinations.isEmpty && !_homeController.isLoading) {
        _homeController.loadDestinations();
      }
      context.read<RecommendationController>().loadRecommendations();
      context.read<FavoritesController>().ensureFavoritesLoaded();
      final archives = context.read<ArchiveController>();
      if (!archives.hasLoaded && archives.error == null) {
        archives.loadArchives();
      }
      final notifications = context.read<NotificationsController>();
      notifications.refreshCount();
      notifications.startPolling();
      _maybeShowStartAnnouncement();
    });
  }

  void _onHomeControllerUpdated() {
    if (_homeController.requestedTabIndex != -1 &&
        _homeController.requestedTabIndex != _tabController.index) {
      _tabController.animateTo(_homeController.requestedTabIndex);
      _homeController.resetTabRequest();
    }
  }

  /// Ventana al abrir la app: aviso importante pendiente o anuncio de inicio
  /// (respetando su límite de veces). Una por sesión. Falla suave: si no hay
  /// anuncio, no hace nada. Se muestra como overlay (no como ruta de diálogo)
  /// para sobrevivir a los refrescos de GoRouter durante la verificación de sesión.
  Future<void> _maybeShowStartAnnouncement() async {
    if (_startModalShown) return;
    // Primero los textos legales: el anuncio de inicio espera a la próxima sesión.
    final accepted =
        context.read<AuthController>().currentUser?.acceptedTermsVersion ==
        kLegalVersion;
    if (!accepted) return;
    _startModalShown = true;
    final annCtrl = context.read<AnnouncementController>();
    final ann = await annCtrl.pickStartAnnouncement();
    if (!mounted) return;
    _startAnnouncementResolved = true;
    if (ann == null) {
      setState(() {});
      return;
    }
    annCtrl.markViewed(ann);
    setState(() => _startAnnouncement = ann);
  }

  void _dismissStartAnnouncement() {
    final ann = _startAnnouncement;
    if (ann == null) return;
    context.read<AnnouncementController>().dismiss(ann);
    setState(() => _startAnnouncement = null);
  }

  void _openStartAnnouncementAction() {
    final ann = _startAnnouncement;
    if (ann == null) return;
    context.read<AnnouncementController>().markClicked(ann);
    setState(() => _startAnnouncement = null);
    openAnnouncementAction(context, ann);
  }

  @override
  void dispose() {
    _homeController.removeListener(_onHomeControllerUpdated);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark status bar icons on the dark header
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final authController = context.watch<AuthController>();
    final userName = authController.currentUser?.fullName ?? 'Viajero';
    final avatarUrl = authController.currentUser?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              color: AppColors.background,
              // NestedScrollView shares its inner controller across the two tabs.
              // Desktop's automatic interactive Scrollbar requires exactly one
              // ScrollPosition, so keep that decoration off this subtree.
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Consumer<NotificationsController>(
                          builder: (context, notifications, _) =>
                              AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, _) => ExploreHero(
                                  showSearch: _tabController.index == 0,
                                  userName: userName,
                                  avatarUrl: avatarUrl,
                                  unreadCount: notifications.unreadCount,
                                  onProfile: () =>
                                      MainLayout.of(context)?.changeTab(3),
                                  onNotifications: () =>
                                      context.push('/notifications'),
                                  onSearch: () => context.push('/search'),
                                  onFilter: () =>
                                      context.push('/search?open_filters=true'),
                                ),
                              ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorPadding: EdgeInsets.zero,
                            splashBorderRadius: BorderRadius.circular(25),
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.transparent;
                              }
                              if (states.contains(WidgetState.hovered) ||
                                  states.contains(WidgetState.focused)) {
                                return Colors.black.withValues(alpha: 0.04);
                              }
                              return Colors.transparent;
                            }),
                            indicator: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: AppColors.textPrimary,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: AppTypography.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: AppTypography.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: const [
                              Tab(text: 'Explorar'),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(AppIcons.sparkles, size: 16),
                                    SizedBox(width: 7),
                                    Text('Para ti'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      HomeExploreContent(
                        onSwitchToForYou: () => _tabController.animateTo(1),
                      ),
                      const HomeForYouContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Quien ya tenía cuenta acepta una vez los textos legales vigentes.
          const TermsGateOverlay(),
          // Overlay del anuncio de inicio (sobre todo el contenido del home).
          if (_startAnnouncementResolved &&
              _startAnnouncement == null &&
              authController.currentUser?.acceptedTermsVersion == kLegalVersion)
            const LocationInvitation(),
          if (_startAnnouncement != null)
            AnnouncementModalOverlay(
              announcement: _startAnnouncement!,
              onClose: _dismissStartAnnouncement,
              onAction: _openStartAnnouncementAction,
            ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  static const double _headerHeight = AppSpace.field + 68;

  @override
  double get minExtent => _headerHeight;
  @override
  double get maxExtent => _headerHeight;

  static double _blurAt(double position) {
    final inv = (1.0 - position);
    if (inv <= 0.18) return 0.0;
    final t = ((inv - 0.18) / 0.82).clamp(0.0, 1.0);
    return 10.0 * t * t * (3 - 2 * t);
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      children: [
        // Eight bounded blur samples; avoid dozens of backdrop passes per frame.
        // Only blur when content actually scrolls behind the sticky control.
        if (overlapsContent)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    for (var band = 0; band < 8; band++)
                      Positioned(
                        top: constraints.maxHeight * band / 8,
                        left: 0,
                        right: 0,
                        height: constraints.maxHeight / 8,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _blurAt(band / 7),
                              sigmaY: _blurAt(band / 7),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        // Difuminado gradual a la inversa (de arriba hacia abajo) con AppColors.background
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.98),
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.background.withValues(alpha: 0.72),
                    AppColors.background.withValues(alpha: 0.40),
                    AppColors.background.withValues(alpha: 0.12),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.28, 0.52, 0.74, 0.90, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Cápsula flotante con padding interno para alinear exactamente el hover y el indicador
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.field, bottom: 8),
          child: Center(
            child: Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: tabBar,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
