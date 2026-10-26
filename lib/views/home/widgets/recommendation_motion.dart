import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecommendationWorkingState extends StatelessWidget {
  const RecommendationWorkingState({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Semantics(
      liveRegion: true,
      label: 'Motor de recomendaciones trabajando',
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: MediaQuery.disableAnimationsOf(context) ? .65 : null,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: AppColors.accent,
                    backgroundColor: AppColors.discovery.withValues(alpha: .10),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.discovery,
                  size: 26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Buscando destinos para ti',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'El motor está combinando tus preferencias con el contexto del viaje.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Each result enters once per ranking, when the lazy list brings it on screen.
class RecommendationArrival extends StatelessWidget {
  const RecommendationArrival({
    super.key,
    required this.index,
    required this.animate,
    required this.child,
  });
  final int index;
  final bool animate;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate && !reduceMotion ? 0 : 1, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child: RepaintBoundary(child: child),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
            (index.isEven ? -64 : 64) * (1 - value),
            6 * (1 - value),
          ),
          child: child,
        ),
      ),
    );
  }
}
