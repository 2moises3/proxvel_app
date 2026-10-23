import 'package:flutter/material.dart';
import '../../models/destination_model.dart';

/// Vista previa procedente de la tarjeta real; nunca sustituye la carga de la API.
class DestinationOpening {
  final DestinationModel destination;
  final String origin;
  const DestinationOpening(this.destination, this.origin);
  String get tag => '$origin/${destination.id}';
}

class DestinationHero extends StatelessWidget {
  final String? tag;
  final Widget child;
  final BorderRadius borderRadius;
  const DestinationHero({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });
  @override
  Widget build(BuildContext context) {
    if (tag == null || MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag!,
      transitionOnUserGestures: true,
      child: ClipRRect(borderRadius: borderRadius, child: child),
      flightShuttleBuilder: (_, animation, direction, from, to) {
        final start = (from.widget as Hero).child as ClipRRect;
        final end = (to.widget as Hero).child as ClipRRect;
        return AnimatedBuilder(
          animation: animation,
          builder: (_, child) {
            final t = direction == HeroFlightDirection.push
                ? animation.value
                : 1 - animation.value;
            return ClipRRect(
              borderRadius: BorderRadius.lerp(
                start.borderRadius as BorderRadius,
                end.borderRadius as BorderRadius,
                t,
              )!,
              child: child,
            );
          },
          child: SizedBox.expand(
            child: direction == HeroFlightDirection.push
                ? end.child
                : start.child,
          ),
        );
      },
    );
  }
}
