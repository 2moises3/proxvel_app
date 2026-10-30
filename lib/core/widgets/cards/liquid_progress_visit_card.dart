import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../../models/visit_model.dart';

/// Card animada de visita en progreso con efecto de llenado de agua:
/// La card comienza en escala de grises y se va pintando a todo color
/// de abajo hacia arriba como líquido subiendo a medida que transcurre el tiempo.
class LiquidProgressVisitCard extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback? onVerify;
  final bool isVerifying;

  const LiquidProgressVisitCard({
    super.key,
    required this.visit,
    this.onVerify,
    this.isVerifying = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = visit.progress.clamp(0.0, 1.0);
    final isCompleted = progress >= 1.0;
    final destName = visit.destinationName ?? 'Destino Turístico';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppColors.accent : AppColors.primary).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── 1. Capa Base: Desaturada / Gris (Visita aún no cargada) ──
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: _buildCardContent(
                  destName: destName,
                  isColored: false,
                ),
              ),
            ),

            // Tinte frío sobre la parte gris
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),

            // ── 2. Capa Líquida: Color que sube desde abajo ──
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                if (animatedProgress <= 0.005) return const SizedBox.shrink();

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: animatedProgress,
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      children: [
                        // Contenido a todo color
                        Positioned.fill(
                          child: _buildCardContent(
                            destName: destName,
                            isColored: true,
                          ),
                        ),

                        // Efecto de línea de superficie de agua / resplandor superior
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.9),
                                  Colors.cyanAccent.withValues(alpha: 0.95),
                                  AppColors.accent.withValues(alpha: 0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── 3. Overlays de información y cronómetro ──
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge superior
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.water_drop_rounded,
                                size: 14,
                                color: isCompleted ? AppColors.accent : Colors.cyanAccent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCompleted
                                    ? '¡Permanencia completada!'
                                    : 'Cargando visita en tu Atlas...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Porcentaje
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Título del destino
                    Text(
                      destName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Fila de estado y acción
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isCompleted
                                ? 'Tiempo mínimo alcanzado (${visit.minDwellMinutes} min). ¡Ya puedes certificar!'
                                : 'Faltan ${visit.remainingMinutes} min de permanencia para sellar.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                        if (isCompleted && onVerify != null)
                          ElevatedButton.icon(
                            onPressed: isVerifying ? null : onVerify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: isVerifying
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.workspace_premium_rounded, size: 16),
                            label: Text(
                              isVerifying ? 'Sellando...' : 'Sellar Visita',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required String destName,
    required bool isColored,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isColored
              ? [
                  AppColors.primary.withValues(alpha: 0.6),
                  AppColors.primaryDark,
                ]
              : [
                  Colors.blueGrey.shade800,
                  Colors.blueGrey.shade900,
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.explore_rounded,
          size: 72,
          color: isColored
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
