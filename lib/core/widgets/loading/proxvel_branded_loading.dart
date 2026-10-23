import 'dart:math' as math;
import '../../theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ProxvelLoadingVariant { splash, compact }

class ProxvelBrandedLoading extends StatefulWidget {
  final ProxvelLoadingVariant variant;
  final String? customMessage;
  final String? customTip;
  final bool isReady;

  const ProxvelBrandedLoading({
    super.key,
    this.variant = ProxvelLoadingVariant.splash,
    this.customMessage,
    this.customTip,
    this.isReady = false,
  });

  @override
  State<ProxvelBrandedLoading> createState() => _ProxvelBrandedLoadingState();
}

class ProxvelSplashRingsPainter extends CustomPainter {
  final double animationValue;

  ProxvelSplashRingsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 + (0.05 * animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxRadius = size.height > size.width ? size.height : size.width;
    
    for (int i = 1; i <= 5; i++) {
      final radius = (maxRadius / 5) * i;
      canvas.drawCircle(center, radius + (15 * animationValue), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ProxvelSplashRingsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Aguja temporal elegante y minimalista.
class ProxvelTemporaryNeedlePainter extends CustomPainter {
  final double rotationAngle;
  final double opacity;

  ProxvelTemporaryNeedlePainter({required this.rotationAngle, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Dimensiones de la aguja temporal: 76px de alto total, 18px de ancho total.
    const double needleLength = 38.0; 
    const double needleWidth = 9.0;   

    final path = Path()
      ..moveTo(0, -needleLength) // Punta norte
      ..lineTo(needleWidth, 0)   // Centro derecha
      ..lineTo(0, needleLength)  // Punta sur
      ..lineTo(-needleWidth, 0)  // Centro izquierda
      ..close();

    canvas.drawPath(path, paint);

    // Punto central sutil para mayor elegancia
    final dotPaint = Paint()
      ..color = const Color(0xFFFDBA00).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3.5, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ProxvelTemporaryNeedlePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle || oldDelegate.opacity != opacity;
  }
}

class _ProxvelBrandedLoadingState extends State<ProxvelBrandedLoading>
    with TickerProviderStateMixin {
  late final AnimationController _ringsAnimCtrl;
  late final AnimationController _needleAnimCtrl;
  late final AnimationController _finishAnimCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _needleRotationAnim;
  
  late final Animation<double> _maskOpacityAnim;
  late Animation<double> _needleAlignAnim;

  @override
  void initState() {
    super.initState();
    _ringsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ringsAnimCtrl, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ringsAnimCtrl, curve: Curves.easeInOut),
    );

    _needleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _needleRotationAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _needleAnimCtrl, curve: Curves.linear),
    );

    _finishAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _maskOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _finishAnimCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void didUpdateWidget(covariant ProxvelBrandedLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReady && !oldWidget.isReady) {
      _triggerReadyTransition();
    }
  }

  void _triggerReadyTransition() {
    _needleAnimCtrl.stop();
    
    final currentAngle = _needleRotationAnim.value;
    // Desaceleración: la aguja da media vuelta más suavemente antes de desaparecer
    final targetAngle = currentAngle + math.pi;
    
    _needleAlignAnim = Tween<double>(begin: currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _finishAnimCtrl, curve: Curves.easeOutCubic),
    );

    _finishAnimCtrl.forward();
  }

  @override
  void dispose() {
    _ringsAnimCtrl.dispose();
    _needleAnimCtrl.dispose();
    _finishAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == ProxvelLoadingVariant.compact) {
      return Center(
        child: AnimatedBuilder(
          animation: _ringsAnimCtrl,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFFFDBA00),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDBA00), // Amarillo dorado vivo
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fondo con círculos sutiles
          AnimatedBuilder(
            animation: _ringsAnimCtrl,
            builder: (context, child) {
              return CustomPaint(
                painter: ProxvelSplashRingsPainter(_ringsAnimCtrl.value),
              );
            },
          ),
          
          // 2. Contenido Central
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 5),
                
                // 3. Composición del Logo
                AnimatedBuilder(
                  animation: _ringsAnimCtrl,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // El logo original fiel debajo de todo
                      SvgPicture.asset(
                        'assets/branding/proxvel_logo.svg', 
                        width: 154, // Ligeramente más grande y elegante
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      
                      // Máscara temporal que oculta solo el centro del logo
                      AnimatedBuilder(
                        animation: _finishAnimCtrl,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _maskOpacityAnim.value,
                            child: Container(
                              width: 76, // Diámetro suficiente para tapar el centro, sin comerse el aro
                              height: 76,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFDBA00),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Aguja temporal limpia y simétrica superpuesta
                      AnimatedBuilder(
                        animation: Listenable.merge([_needleAnimCtrl, _finishAnimCtrl]),
                        builder: (context, child) {
                          final angle = _finishAnimCtrl.isAnimating || _finishAnimCtrl.isCompleted
                              ? _needleAlignAnim.value
                              : _needleRotationAnim.value;
                              
                          return CustomPaint(
                            size: const Size(80, 80),
                            painter: ProxvelTemporaryNeedlePainter(
                              rotationAngle: angle,
                              // Fade out junto con la máscara
                              opacity: _maskOpacityAnim.value, 
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 4),

                // Footer: Powered by Biznovatech
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 20, height: 1, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: AppSpace.related),
                        Text(
                          'Powered by',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: AppSpace.related),
                        Container(width: 20, height: 1, color: Colors.white.withValues(alpha: 0.5)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.content),
                    SvgPicture.asset(
                      'assets/branding/bnt_logo.svg',
                      width: 130,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.group),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
