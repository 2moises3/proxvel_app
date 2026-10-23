import 'package:flutter/material.dart';
import 'button_content.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';

class ShimmerButton extends StatelessWidget {
  final AnimationController shimmer;
  final Color baseColor;
  final Color hoverColor;
  final VoidCallback onPressed;
  final String text;
  final bool isLoading;

  const ShimmerButton({
    super.key,
    required this.shimmer,
    required this.baseColor,
    required this.hoverColor,
    required this.onPressed,
    this.text = 'Comenzar',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.button),
      child: IntrinsicHeight(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Stack(
              children: [
                // Botón base
                ElevatedButton(
                  onPressed: isLoading ? null : onPressed,
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: baseColor,
                        disabledBackgroundColor: baseColor,
                        foregroundColor: AppColors
                            .textPrimary, // Dark text is standard for amber button
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(
                          double.infinity,
                          AppSizing.button,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          hoverColor.withValues(alpha: 0.25),
                        ),
                      ),
                  child: ButtonContent(text: text, isLoading: isLoading),
                ),

                // Shimmer sweep (no intercepta toques)
                if (!isLoading && !MediaQuery.disableAnimationsOf(context))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: shimmer,
                        builder: (_, child) {
                          final t = shimmer.value;
                          final sweepX = -0.4 + t * 1.8;
                          return SizedBox.expand(
                            child: CustomPaint(
                              painter: _SweepPainter(position: sweepX),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double position; // 0.0 = izquierda, 1.0 = derecha

  const _SweepPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final x = position * size.width;
    final sweepWidth = size.width * 0.38;

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(x - sweepWidth / 2, 0, sweepWidth, size.height),
          );

    // Inclina el sweep ~20°
    final path = Path()
      ..moveTo(x - sweepWidth / 2 - 8, 0)
      ..lineTo(x + sweepWidth / 2 + 8, 0)
      ..lineTo(x + sweepWidth / 2 - 8, size.height)
      ..lineTo(x - sweepWidth / 2 - 24, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.position != position;

  @override
  bool hitTest(Offset position) => false;
}
