import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../core/widgets/legal/legal_links_row.dart';
import 'widgets/auth_backdrop.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver, RouteAware {
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
    child: Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackdrop(imagePath: AuthScenes.assets[_scene], crossfade: true),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, size) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: AppSpace.pageInsets,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpace.section),
                          Text(
                            'PROXVEL',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 200),
                          const Text(
                            'Tu próxima historia\nempieza en Perú.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingOnDark,
                          ),
                          const SizedBox(height: AppSpace.field),
                          const Text(
                            'Encuentra lugares que conecten con tu forma de viajar.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyOnDark,
                          ),
                          const SizedBox(height: AppSpace.group),
                          ProxvelButton(
                            text: 'Crear mi cuenta',
                            onPressed: () => _open('/register'),
                          ),
                          const SizedBox(height: AppSpace.related),
                          TextButton(
                            onPressed: () => _open('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Ya tengo cuenta · Iniciar sesión',
                            ),
                          ),
                          const SizedBox(height: AppSpace.related),
                          const LegalLinksRow(),
                          const SizedBox(height: AppSpace.field),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
