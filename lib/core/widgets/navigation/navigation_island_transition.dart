import 'package:flutter/material.dart';
import 'proxvel_bottom_navigation.dart';

final navigationIsland = NavigationIslandController();
final navigationIslandObserver = NavigationIslandObserver(navigationIsland);

class NavigationIslandController extends ChangeNotifier {
  bool visible = false;
  int index = 0;
  ValueChanged<int>? onTap;
  ModalRoute<dynamic>? mainRoute;

  void attach({
    required ModalRoute<dynamic> route,
    required int index,
    required ValueChanged<int> onTap,
  }) {
    mainRoute = route;
    update(visible: route.isCurrent, index: index, onTap: onTap);
  }

  void update({bool? visible, int? index, ValueChanged<int>? onTap}) {
    this.visible = visible ?? this.visible;
    this.index = index ?? this.index;
    this.onTap = onTap ?? this.onTap;
    notifyListeners();
  }

  void detach(ValueChanged<int> owner) {
    if (onTap != owner) return;
    onTap = null;
    mainRoute = null;
    visible = false;
    notifyListeners();
  }
}

class NavigationIslandObserver extends NavigatorObserver {
  NavigationIslandObserver(this.controller);
  final NavigationIslandController controller;
  Route<dynamic>? _top;
  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _top = topRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_top == topRoute) {
        controller.update(visible: identical(topRoute, controller.mainRoute));
      }
    });
  }
}

/// Above the Navigator: covering pages cannot obscure the exit animation.
class NavigationIslandHost extends StatefulWidget {
  const NavigationIslandHost({
    super.key,
    required this.controller,
    required this.child,
  });
  final NavigationIslandController controller;
  final Widget child;
  @override
  State<NavigationIslandHost> createState() => _NavigationIslandHostState();
}

class _NavigationIslandHostState extends State<NavigationIslandHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
    reverseDuration: const Duration(milliseconds: 680),
    value: 1,
  );
  late final OverlayEntry _layer = OverlayEntry(builder: _buildLayers);

  @override
  void didUpdateWidget(covariant NavigationIslandHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
      _update();
    }
    _layer.markNeedsBuild();
  }

  static final _travel = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -9.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -9.0,
        end: 190.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 72,
    ),
  ]);
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  void _update() {
    if (!mounted) return;
    final show = widget.controller.visible && widget.controller.onTap != null;
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = show ? 0 : 1;
    } else if (show) {
      _motion.reverse();
    } else {
      _motion.forward();
    }
    _layer.markNeedsBuild();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_layer]);

  Widget _buildLayers(BuildContext context) => Stack(
    children: [
      widget.child,
      AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          if (_motion.value == 1 || widget.controller.onTap == null) {
            return const SizedBox.shrink();
          }
          final displacement = _travel.transform(_motion.value);
          final backdrop = displacement.clamp(0.0, double.infinity);
          return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !widget.controller.visible || _motion.isAnimating,
              child: ExcludeSemantics(
                excluding: !widget.controller.visible || _motion.isAnimating,
                child: ProxvelBottomNavigation(
                  currentIndex: widget.controller.index,
                  onTap: (i) => widget.controller.onTap?.call(i),
                  islandOffset: displacement,
                  backdropOffset: backdrop,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
