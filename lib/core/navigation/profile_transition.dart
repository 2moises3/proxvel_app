import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A short editorial transition; text does not zoom and reduced motion is respected.
Page<void> profileTransition(BuildContext context, LocalKey key, Widget child) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return NoTransitionPage<void>(key: key, child: child);
  }
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondary, child) {
      final motion = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: motion,
        child: SlideTransition(
          position: motion.drive(
            Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero),
          ),
          child: child,
        ),
      );
    },
  );
}
