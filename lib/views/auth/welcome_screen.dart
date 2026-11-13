import '../../core/localization/l10n.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/language_picker.dart';
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
      backgroundColor: _WelcomePalette.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackdrop(imagePath: AuthScenes.assets[_scene], crossfade: true),
          SafeArea(child: _buildWelcome(context)),
        ],
      ),
    ),
  );

  Widget _buildWelcome(BuildContext context) => _page(
    title: context.l10n.welcomeHeadline,
    description: context.l10n.welcomeDescription,
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _primaryButton(context.l10n.signIn, () => _open('/login')),
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
              child: Text(
                context.l10n.createAccount,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _page({
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
                if (context.watch<AppLanguage?>() != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: context.l10n.language,
                      onPressed: () => showLanguagePicker(context),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _WelcomePalette.ink.withValues(
                          alpha: .45,
                        ),
                      ),
                      icon: const Icon(Icons.language_rounded),
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: 110),
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
}

/// Scoped preview palette for the welcome screen.
abstract final class _WelcomePalette {
  static const gold = AppColors.accent;
  static const ink = Color(0xFF202020);
}
