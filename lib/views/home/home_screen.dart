import 'package:go_router/go_router.dart';
import '../../core/theme/app_layout.dart';
import '../../controllers/notifications_controller.dart';
import '../main/main_layout.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'widgets/home_for_you_content.dart';

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
  AnnouncementModel? _startAnnouncement;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _homeController = context.read<HomeController>();
    _homeController.addListener(_onHomeControllerUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_homeController.destinations.isEmpty) {
        _homeController.loadDestinations();
      }
      context.read<RecommendationController>().loadRecommendations();
      context.read<FavoritesController>().loadFavorites();
      context.read<ArchiveController>().loadArchives();
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
    final accepted = context.read<AuthController>().currentUser?.acceptedTermsVersion == kLegalVersion;
    if (!accepted) return;
    _startModalShown = true;
    final annCtrl = context.read<AnnouncementController>();
    final ann = await annCtrl.pickStartAnnouncement();
    if (!mounted || ann == null) return;
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
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CustomHomeHeaderDelegate(
                        safeAreaTop: MediaQuery.of(context).padding.top,
                        userName: userName,
                        avatarUrl: avatarUrl,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.all(6),
                          indicator: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Explorar'),
                            Tab(text: 'Para ti'),
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
          // Quien ya tenía cuenta acepta una vez los textos legales vigentes.
          const TermsGateOverlay(),
          // Overlay del anuncio de inicio (sobre todo el contenido del home).
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

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _CustomHomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double safeAreaTop;
  final String userName;
  final String? avatarUrl;

  _CustomHomeHeaderDelegate({
    required this.safeAreaTop,
    required this.userName,
    this.avatarUrl,
  });

  @override
  double get minExtent => safeAreaTop + 60 + 32; // App bar height + curve height
  @override
  double get maxExtent => 280;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Avatar Interpolation
    final avatarRadius = ui.lerpDouble(22, 18, progress)!;
    final avatarTop = ui.lerpDouble(safeAreaTop + 16, safeAreaTop + 12, progress)!;
    final avatarLeft = 24.0;

    // Notification Interpolation

    // Name Interpolation
    final nameTopExpanded = maxExtent - 32 - 40 - 35; // maxExtent - curve - nameHeight - padding
    final nameTopCollapsed = safeAreaTop + 18.0;
    final nameTop = ui.lerpDouble(nameTopExpanded, nameTopCollapsed, progress)!;

    final nameLeftExpanded = 24.0;
    final nameLeftCollapsed = avatarLeft + (avatarRadius * 2) + 12.0; // Next to avatar
    final nameLeft = ui.lerpDouble(nameLeftExpanded, nameLeftCollapsed, progress)!;

    final nameFontSize = ui.lerpDouble(28, 18, progress)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background layer: Deep slate base
        Container(color: const Color(0xFF0F172A)),
        
        // Background layer: Image that parallax scrolls
        Positioned(
          top: -shrinkOffset * 0.5,
          left: 0,
          right: 0,
          height: maxExtent,
          child: Image.asset('assets/images/hero-sky.webp', fit: BoxFit.cover),
        ),
        Positioned(
          top: -shrinkOffset * 0.2,
          left: 0,
          right: 0,
          height: maxExtent,
          child: Image.asset('assets/images/hero-montanas.webp', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
        ),

        // Solid background that fades in when collapsing (acts as standard AppBar background)
        Opacity(
          opacity: progress,
          child: Container(color: const Color(0xFF0F172A)),
        ),

        // Gradient overlay for text readability when expanded
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F172A).withValues(alpha: 0.5 * (1 - progress)), // Top shadow for icons
                Colors.transparent,
                const Color(0xFF0B142E).withValues(alpha: 0.8 * (1 - progress)), // Starts getting dark midway
                const Color(0xFF0B142E).withValues(alpha: 1.0 * (1 - progress)), // Solid darkness at bottom
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // The permanent white curve at the bottom
        Positioned(
          bottom: -2,
          left: 0,
          right: 0,
          child: Container(
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            ),
          ),
        ),

        // Avatar (abre la pestaña Perfil)
        Positioned(
          top: avatarTop,
          left: avatarLeft,
          child: GestureDetector(
            onTap: () => MainLayout.of(context)?.changeTab(3),
            child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null 
                  ? Icon(Icons.person, color: Colors.white, size: avatarRadius * 1.2)
                  : null,
            ),
            ),
          ),
        ),

        // Campana: abre el centro de notificaciones (anuncios + avisos personales)
        Positioned(
          top: avatarTop,
          right: 24,
          child: GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Consumer<NotificationsController>(
              builder: (context, notifications, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(
                      notifications.hasUnread
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none,
                      color: Colors.white,
                      size: avatarRadius,
                    ),
                  ),
                  if (notifications.hasUnread)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          notifications.unreadCount > 9 ? '9+' : '${notifications.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // User Name
        Positioned(
          top: nameTop,
          left: nameLeft,
          child: Text(
            userName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: nameFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // "Usuario" subtitle (only visible when expanded)
        Positioned(
          top: nameTop + 36,
          left: nameLeft,
          child: Opacity(
            opacity: 1.0 - progress,
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Usuario',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _CustomHomeHeaderDelegate oldDelegate) {
    return safeAreaTop != oldDelegate.safeAreaTop || userName != oldDelegate.userName || avatarUrl != oldDelegate.avatarUrl;
  }
}
