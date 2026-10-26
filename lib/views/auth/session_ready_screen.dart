import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/archive_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/auth_backdrop.dart';

/// Confirma una sesión ya autenticada mientras prepara la primera visita.
class SessionReadyScreen extends StatefulWidget {
  const SessionReadyScreen({super.key});

  @override
  State<SessionReadyScreen> createState() => _SessionReadyScreenState();
}

class _SessionReadyScreenState extends State<SessionReadyScreen> {
  final _background = AuthScenes.current;
  bool _canContinue = false;
  bool _leaving = false;
  Timer? _escapeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      context.go('/welcome');
      return;
    }
    if (!user.hasCompleteResidence) {
      context.go('/residence-gate');
      return;
    }
    final recommendations = context.read<RecommendationController>();
    final archives = context.read<ArchiveController>();
    _escapeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _canContinue = true);
    });
    try {
      // These requests can finish on Home; they should not hold the route open.
      unawaited(recommendations.loadRecommendations());
      unawaited(archives.loadArchives());
      // Keep a short readable confirmation while warming the local hero image.
      await Future.wait([
        HomeEntryCoordinator.prepareHomeForFirstPaint(context),
        Future<void>.delayed(const Duration(milliseconds: 850)),
      ]).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Los controladores conservan los errores para reintentar desde Inicio.
      // Un timeout no cancela las solicitudes: pueden terminar en segundo plano.
    }
    _enter();
  }

  void _enter() {
    if (!mounted || _leaving) return;
    _leaving = true;
    _escapeTimer?.cancel();
    if (context.read<AuthController>().currentUser == null) {
      context.go('/welcome');
    } else {
      context.go('/main');
    }
  }

  @override
  void dispose() {
    _escapeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: SessionWelcomeView(
      background: _background,
      onContinue: _canContinue ? _enter : null,
    ),
  );
}

/// Presentación sin dependencias de red; permite verificar diseño y accesibilidad.
class SessionWelcomeView extends StatelessWidget {
  const SessionWelcomeView({
    super.key,
    required this.background,
    this.onContinue,
  });

  final String background;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackdrop(imagePath: background),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xA6000000)],
                stops: [.25, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF202020),
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  'Ya estás dentro.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.style(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Sesión iniciada.\nEstamos preparando tu inicio y tus recomendaciones.',
                                textAlign: TextAlign.center,
                                style: AppTypography.style(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: 128,
                          child: LinearProgressIndicator(
                            // Indeterminado: las peticiones no reportan un porcentaje.
                            value: reduceMotion ? .5 : null,
                            semanticsLabel: 'Preparando contenido',
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.accent,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onContinue == null
                              ? 'Un momento para empezar.'
                              : 'Está tardando un poco más de lo habitual.',
                          textAlign: TextAlign.center,
                          style: AppTypography.style(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: onContinue == null
                              ? null
                              : TextButton(
                                  onPressed: onContinue,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Continuar al inicio'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
