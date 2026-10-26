import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';

/// Rutas canónicas a los íconos unificados del ecosistema PROXVEL (Lucide / MIT).
class AppIcons {
  static const externalLink = 'assets/icons/app/external-link.svg';
  static const info = 'assets/icons/app/info.svg';
  static const route = 'assets/icons/app/route.svg';
  static const accessibility = 'assets/icons/app/accessibility.svg';
  static const wallet = 'assets/icons/app/wallet.svg';
  static const mountain = 'assets/icons/app/mountain.svg';
  static const clock = 'assets/icons/app/clock.svg';
  static const navHome = 'assets/icons/app/nav_home.svg';
  static const navMap = 'assets/icons/app/nav_map.svg';
  static const navHeart = 'assets/icons/app/nav_heart.svg';
  static const navProfile = 'assets/icons/app/nav_profile.svg';
  static const bell = 'assets/icons/app/bell.svg';
  static const search = 'assets/icons/app/search.svg';
  static const sliders = 'assets/icons/app/sliders.svg';
  static const sparkles = 'assets/icons/app/sparkles.svg';
  static const compass = 'assets/icons/app/compass.svg';
  static const calendar = 'assets/icons/app/calendar.svg';
  static const heartOutline = 'assets/icons/app/heart_outline.svg';
  static const heartFilled = 'assets/icons/app/heart_filled.svg';
  static const star = 'assets/icons/app/star.svg';
  static const starFilled = 'assets/icons/app/star_filled.svg';
  static const mapPin = 'assets/icons/app/map_pin.svg';
  static const edit = 'assets/icons/app/edit.svg';
  static const lock = 'assets/icons/app/lock.svg';
  static const logOut = 'assets/icons/app/log_out.svg';
  static const chevronRight = 'assets/icons/app/chevron_right.svg';
}

/// Widget para renderizar cualquier ícono SVG de la app de forma estandarizada.
class AppIcon extends StatelessWidget {
  const AppIcon(this.assetPath, {super.key, this.size = 22, this.color});

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Campana de notificaciones interactiva con micro-animación de balanceo/vibración
/// periódica cuando existen notificaciones sin leer.
class AnimatedNotificationBell extends StatefulWidget {
  const AnimatedNotificationBell({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
    this.size = 22,
    this.color = const Color(0xFF202020),
    this.backgroundColor = Colors.white,
  });

  final VoidCallback onTap;
  final int unreadCount;
  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  State<AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Animación de péndulo en el primer 20% del ciclo (0 a 640ms), luego reposo
    _angleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -0.22,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.22,
          end: 0.22,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.22,
          end: -0.15,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.15,
          end: 0.12,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.12,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      // Reposo durante el 74% restante
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 26),
    ]).animate(_controller);

    if (widget.unreadCount > 0) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > 0 && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.unreadCount <= 0 && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.unreadCount > 0
          ? 'Notificaciones: ${widget.unreadCount} sin leer'
          : 'Notificaciones',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton.filled(
            tooltip: 'Notificaciones',
            onPressed: widget.onTap,
            style: IconButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.color,
              minimumSize: const Size(44, 44),
            ),
            icon: AnimatedBuilder(
              animation: _angleAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _angleAnimation.value,
                  alignment: const Alignment(
                    0,
                    -0.7,
                  ), // Pivote en la punta superior de la campana
                  child: child,
                );
              },
              child: AppIcon(
                AppIcons.bell,
                size: widget.size,
                color: widget.color,
              ),
            ),
          ),
          if (widget.unreadCount > 0)
            Positioned(
              top: 9,
              right: 11,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.discovery,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
