import 'widgets/auth_progress_indicator.dart';
import '../../core/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';
import '../../core/widgets/legal/legal_links_row.dart';
import 'widgets/auth_backdrop.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final PageController _pageController = PageController();
  int _step = 0;
  Timer? _timer;
  int _scene = AuthScenes.selected;
  bool _covered = false;
  bool _active = true;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      authRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) authRouteObserver.subscribe(this, route);
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_covered || !_active || MediaQuery.disableAnimationsOf(context)) return;
    _preloadNext();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        _scene = (_scene + 1) % AuthScenes.assets.length;
        AuthScenes.selected = _scene;
      });
      _preloadNext();
    });
  }

  void _preloadNext() {
    unawaited(
      precacheImage(
        ResizeImage(
          AssetImage(
            AuthScenes.assets[(_scene + 1) % AuthScenes.assets.length],
          ),
          width: 720,
        ),
        context,
        onError: (_, _) {},
      ),
    );
  }

  @override
  void didPushNext() {
    _covered = true;
    _timer?.cancel();
  }

  @override
  void didPopNext() {
    _covered = false;
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _schedule();
  }

  Future<void> _open(String path) async {
    _covered = true;
    _timer?.cancel();
    AuthScenes.selected = _scene;
    await context.push(path);
    if (mounted) {
      _covered = false;
      _schedule();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    authRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          _goToStep(0);
        }
      },
      child: Scaffold(
        backgroundColor: _WelcomePalette.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AuthBackdrop(imagePath: AuthScenes.assets[_scene], crossfade: true),
            SafeArea(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _step = i);
                },
                children: [_buildStepOne(context), _buildStepTwo(context)],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _goToStep(int step) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(step);
      return;
    }
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildStepOne(BuildContext context) => _page(
    step: 0,
    title: 'Tu próxima historia\nempieza en Perú.',
    description: 'Descubre lugares que conectan con tu forma de viajar.',
    actions: [_adventureButton()],
  );

  Widget _buildStepTwo(BuildContext context) => _page(
    step: 1,
    title: 'A tu ritmo.\nA tu manera.',
    description:
        'Explora destinos, descubre recomendaciones para ti y guarda tus favoritos.',
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _primaryButton('Iniciar sesión', () => _open('/login')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _open('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _WelcomePalette.ink.withValues(alpha: 0.4),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                shape: const StadiumBorder(),
                textStyle: AppTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Crear cuenta', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _adventureButton() => FilledButton(
    onPressed: () => _goToStep(1),
    style: FilledButton.styleFrom(
      backgroundColor: _WelcomePalette.ink.withValues(alpha: 0.45),
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(58),
      padding: const EdgeInsets.fromLTRB(22, 6, 6, 6),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      elevation: 0,
      textStyle: AppTypography.style(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    child: Row(
      children: [
        const Expanded(child: Text('Comenzar aventura')),
        const SizedBox(width: 16),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _WelcomePalette.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: _WelcomePalette.ink,
            size: 22,
          ),
        ),
      ],
    ),
  );

  Widget _page({
    required int step,
    required String title,
    required String description,
    required List<Widget> actions,
  }) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (step == 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: 'Volver',
                      onPressed: () => _goToStep(0),
                      style: IconButton.styleFrom(
                        backgroundColor: _WelcomePalette.ink.withValues(
                          alpha: 0.45,
                        ),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: 110),
                _buildPageIndicator(step),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: AppTypography.style(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.12,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: AppTypography.style(
                    fontSize: 15,
                    color: const Color(0xE6FFFFFF),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ...actions,
                const SizedBox(height: 16),
                const Center(child: LegalLinksRow()),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _primaryButton(String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _WelcomePalette.gold,
        foregroundColor: _WelcomePalette.ink,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: AppTypography.style(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );

  Widget _buildPageIndicator(int step) =>
      AuthProgressIndicator(step: step, count: 2);
}

/// Scoped preview palette for the two welcome pages.
abstract final class _WelcomePalette {
  static const gold = AppColors.accent;
  static const ink = Color(0xFF202020);
}
