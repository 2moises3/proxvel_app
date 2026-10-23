import 'package:flutter/material.dart';

/// Ambientaciones generadas para el acceso, independientes del catálogo real.
abstract final class AuthScenes {
  static const assets = [
    'assets/images/auth_andes_v1.png',
    'assets/images/auth_costa_v1.png',
    'assets/images/auth_selva_v1.png',
  ];
  static int selected = 0;
  static String get current => assets[selected];
}

final authRouteObserver = RouteObserver<ModalRoute<void>>();

class AuthBackdrop extends StatelessWidget {
  final String imagePath;
  final bool crossfade;
  const AuthBackdrop({
    super.key,
    required this.imagePath,
    this.crossfade = false,
  });
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      AnimatedSwitcher(
        duration: crossfade && !MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 1200)
            : Duration.zero,
        layoutBuilder: (child, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?child]),
        child: Image.asset(
          imagePath,
          key: ValueKey(imagePath),
          fit: BoxFit.cover,
          cacheWidth: 720,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF1A1F2E)),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .34, .62, 1],
            colors: [
              Color(0x10000000),
              Color(0x00000000),
              Color(0x65000000),
              Color(0xBB000000),
            ],
          ),
        ),
      ),
    ],
  );
}
