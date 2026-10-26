import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/destination_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../core/navigation/destination_opening.dart';

/// Tarjeta fotográfica editorial para la pantalla de Favoritos.
/// Admite dos disposiciones:
/// - [isGrid] = false: Tarjeta amplia (Full-Width) estilo revista de viajes.
/// - [isGrid] = true: Tarjeta esbelta para cuadrícula de 2 columnas (3:4).
class FavoriteDestinationCard extends StatelessWidget {
  const FavoriteDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    required this.onRemove,
    this.isGrid = false,
  });

  final DestinationModel destination;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool isGrid;

  // Matriz de color para realzar contraste y saturación natural
  static const _vibrantColorMatrix = <double>[
    1.12, -0.07, -0.01, 0, -4.0,
    -0.02, 1.08, -0.01, 0, -4.0,
    -0.02, -0.07, 1.14, 0, -4.0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(isGrid ? 20 : 24);
    final cityName = destination.city.trim();
    final regionName = destination.region.trim();
    final categoryName = destination.category.trim();
    final destName = destination.name.trim();
    final imageUrl = destination.imageUrl.trim();

    final locationParts = <String>[];
    if (cityName.isNotEmpty) locationParts.add(cityName);
    if (regionName.isNotEmpty) locationParts.add(regionName);
    final location = locationParts.join(', ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEBECEF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fotografía con tratamiento natural ──
            DestinationHero(
              tag: 'fav_${isGrid ? "g" : "l"}_${destination.id}',
              borderRadius: radius,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(_vibrantColorMatrix),
                child: AdaptiveDestinationImage(
                  imagePath: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── Gradiente de lectura oscuro inferior ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: isGrid ? const [0.0, 0.40, 1.0] : const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: isGrid ? 0.85 : 0.78),
                    ],
                  ),
                ),
              ),
            ),

            // ── Toque principal para abrir el destino ──
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Semantics(
                    button: true,
                    label: 'Ver detalles de $destName',
                  ),
                ),
              ),
            ),

            // ── Badge de Categoría (Arriba a la izquierda) ──
            if (categoryName.trim().isNotEmpty)
              Positioned(
                top: isGrid ? 10 : 14,
                left: isGrid ? 10 : 14,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isGrid ? 8 : 12,
                          vertical: isGrid ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          categoryName.toUpperCase(),
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: isGrid ? 9 : 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Botón de Corazón (Arriba a la derecha) ──
            Positioned(
              top: isGrid ? 8 : 12,
              right: isGrid ? 8 : 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.20),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Semantics(
                    button: true,
                    label: 'Quitar $destName de favoritos',
                    child: Container(
                      width: isGrid ? 38 : 44,
                      height: isGrid ? 38 : 44,
                      alignment: Alignment.center,
                      child: AppIcon(
                        AppIcons.heartFilled,
                        size: isGrid ? 18 : 21,
                        color: AppColors.discovery,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Información Inferior ──
            Positioned(
              left: isGrid ? 10 : 16,
              right: isGrid ? 10 : 16,
              bottom: isGrid ? 12 : 16,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destName.isNotEmpty ? destName : 'Destino',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        color: Colors.white,
                        fontSize: isGrid ? 14 : 18,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isGrid ? 4 : 6),
                    Row(
                      children: [
                        const AppIcon(
                          AppIcons.mapPin,
                          size: 13,
                          color: AppColors.discovery,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isGrid ? (cityName.isNotEmpty ? cityName : location) : (location.isNotEmpty ? location : cityName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.style(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: isGrid ? 11.5 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!isGrid && destination.rating > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(
                                  AppIcons.starFilled,
                                  size: 11,
                                  color: Color(0xFFFFB800),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  destination.rating.toStringAsFixed(1),
                                  style: AppTypography.style(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
