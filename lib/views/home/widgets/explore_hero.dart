import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common/app_icon.dart';

/// Content-sized header: no fixed banner height or separate search section.
class ExploreHero extends StatefulWidget {
  const ExploreHero({
    super.key,
    required this.userName,
    this.showSearch = true,
    this.avatarUrl,
    required this.unreadCount,
    required this.onProfile,
    required this.onNotifications,
    required this.onSearch,
    this.onFilter,
  });

  final String userName;
  final bool showSearch;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;
  final VoidCallback? onFilter;

  @override
  State<ExploreHero> createState() => _ExploreHeroState();
}

class _ExploreHeroState extends State<ExploreHero>
    with SingleTickerProviderStateMixin {
  final _searchExtent = GlobalKey();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.showSearch ? 1 : 0,
  );
  bool get showSearch => widget.showSearch;
  String get userName => widget.userName;
  String? get avatarUrl => widget.avatarUrl;
  int get unreadCount => widget.unreadCount;
  VoidCallback get onProfile => widget.onProfile;
  VoidCallback get onNotifications => widget.onNotifications;
  VoidCallback get onSearch => widget.onSearch;
  VoidCallback? get onFilter => widget.onFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ExploreHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSearch != showSearch) _syncMotion();
  }

  void _syncMotion() {
    final target = showSearch ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = target;
    } else {
      _reveal.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _reveal,
    builder: (context, child) => _HeroViewport(
      reveal: _reveal.value,
      searchExtent: _searchExtent,
      child: child!,
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/home_andes_lagoon.webp',
            fit: BoxFit.cover,
            alignment: const Alignment(.2, .25),
            excludeFromSemantics: true,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .20),
                  Colors.black.withValues(alpha: .48),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Abrir perfil de $userName',
                        child: InkWell(
                          onTap: onProfile,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child:
                                        avatarUrl != null &&
                                            avatarUrl!.trim().isNotEmpty
                                        ? Image.network(
                                            avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _avatar(),
                                          )
                                        : _avatar(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    userName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.style(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedNotificationBell(
                      onTap: onNotifications,
                      unreadCount: unreadCount,
                      size: 21,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Descubre destinos increíbles y vive experiencias inolvidables en Perú.',
                  style: AppTypography.style(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 1.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  excluding: !showSearch,
                  child: IgnorePointer(
                    ignoring: !showSearch,
                    child: FadeTransition(
                      opacity: _reveal,
                      child: _SearchExtent(
                        key: _searchExtent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Hero(
                                    tag: 'home_search_bar_hero',
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(99),
                                      child: InkWell(
                                        onTap: onSearch,
                                        borderRadius: BorderRadius.circular(99),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              const AppIcon(
                                                AppIcons.search,
                                                size: 20,
                                                color: Color(0xFF626870),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '¿A dónde quieres ir?',
                                                  style: AppTypography.style(
                                                    fontSize: 14,
                                                    color: const Color(
                                                      0xFF626870,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Hero(
                                  tag: 'home_filter_button_hero',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: IconButton.filled(
                                      tooltip: 'Buscar y filtrar destinos',
                                      onPressed: onFilter ?? onSearch,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: const Color(
                                          0xFF202020,
                                        ),
                                        minimumSize: const Size(52, 52),
                                      ),
                                      icon: const AppIcon(
                                        AppIcons.sliders,
                                        size: 20,
                                        color: Color(0xFF202020),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _avatar() => const ColoredBox(
    color: Color(0x33FFFFFF),
    child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
  );
}

/// Layout the full hero once at its natural size, then crop only the search
/// extent. The image's cover rect and the title position never follow the crop.
class _HeroViewport extends SingleChildRenderObjectWidget {
  const _HeroViewport({
    required this.reveal,
    required this.searchExtent,
    required super.child,
  });
  final double reveal;
  final GlobalKey searchExtent;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeroViewport(reveal, searchExtent);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHeroViewport renderObject,
  ) {
    renderObject.reveal = reveal;
  }
}

class _RenderHeroViewport extends RenderProxyBox {
  _RenderHeroViewport(this._reveal, this.searchExtent);
  double _reveal;
  final GlobalKey searchExtent;
  set reveal(double value) {
    if (_reveal == value) return;
    _reveal = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    final search = searchExtent.currentContext?.findRenderObject();
    final extent = search is _RenderSearchExtent ? search.measuredHeight : 0.0;
    size = constraints.constrain(
      Size(child!.size.width, child!.size.height - extent * (1 - _reveal)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
    );
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => Offset.zero & size;
}

class _SearchExtent extends SingleChildRenderObjectWidget {
  const _SearchExtent({super.key, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSearchExtent();
}

class _RenderSearchExtent extends RenderProxyBox {
  double measuredHeight = 0;
  @override
  void performLayout() {
    super.performLayout();
    measuredHeight = size.height;
  }
}
