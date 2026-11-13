import 'package:flutter/material.dart';
import '../../localization/l10n.dart';
import '../../theme/app_colors.dart';

/// Loader contextual para la sección "Para Ti" mientras el motor de IA
/// recalcula las recomendaciones. Reemplaza el CircularProgressIndicator genérico
/// con retroalimentación visual que indica qué está ocurriendo.
class AiRankingLoader extends StatefulWidget {
  const AiRankingLoader({super.key});

  @override
  State<AiRankingLoader> createState() => _AiRankingLoaderState();
}

class _AiRankingLoaderState extends State<AiRankingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  int _textIndex = 0;

  static const _messageCount = 3;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Rotar texto cada 2.5 segundos.
    _startTextRotation();
  }

  void _startTextRotation() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _textIndex = (_textIndex + 1) % _messageCount);
      _startTextRotation();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono IA con pulso suave.
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = 1.0 + (_pulseCtrl.value * 0.08);
                final opacity = 0.6 + (_pulseCtrl.value * 0.4);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Texto rotativo con fade.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                [
                  context.l10n.uiRecopilandoTusAspectos,
                  context.l10n.uiProporcionandoTusMejoresDestinos,
                  context.l10n.uiAnalizandoPerfilViajero,
                ][_textIndex],
                key: ValueKey<int>(_textIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
