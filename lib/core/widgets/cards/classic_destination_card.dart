import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_layout.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/destination_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/archive_controller.dart';
import '../../theme/app_colors.dart';
import '../images/adaptive_destination_image.dart';
import 'ai_compatibility_badge.dart';

/// Card de catálogo abierto (pestaña Explorar).
/// Muestra solo datos reales: portada (o placeholder honesto), nombre,
/// ubicación, categoría y favorito. NO muestra precio, rating, distancia
/// ni duración inventados.
///
/// [compatibility] es opcional y solo se pinta cuando el backend entregó un
/// porcentaje real y la preferencia de IA aplica (dato secundario y discreto).
class ClassicDestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback onTap;
  final int? compatibility;

  const ClassicDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.compatibility,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      destination.city,
      destination.region,
    ].where((s) => s.trim().isNotEmpty).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // IntrinsicHeight acota la altura del Row (anclada por la imagen de
        // 118px) para que CrossAxisAlignment.stretch funcione dentro de un
        // scroll vertical. Sin esto, el Row recibe altura infinita y revienta
        // el layout de toda la pantalla.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Imagen ──
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width < 360 ? 80 : 100,
                    height: 100,
                    child: AdaptiveDestinationImage(
                      imagePath: destination.imageUrl,
                    ),
                  ),
                ),
              ),

              // ── Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        destination.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpace.micro),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (destination.category.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                destination.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          if (compatibility != null) ...[
                            AiCompatibilityBadge(
                              compatibility: compatibility!,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Acciones (Favorito y Archivar) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Favorito
                    Consumer<FavoritesController>(
                      builder: (context, favCtrl, _) {
                        final isFav = favCtrl.isFavorite(destination.id);
                        return IconButton(
                          tooltip: isFav
                              ? 'Quitar de favoritos'
                              : 'Guardar en favoritos',
                          onPressed: () => favCtrl.toggleFavorite(
                            destination.id,
                            destination,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isFav
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.background,
                          ),
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? AppColors.error
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpace.related),
                    // Archivar
                    Consumer<ArchiveController>(
                      builder: (context, arcCtrl, _) {
                        final isArc = arcCtrl.isArchived(destination.id);
                        return IconButton(
                          tooltip: isArc
                              ? 'Quitar de archivados'
                              : 'Archivar destino',
                          onPressed: () => arcCtrl.toggleArchive(
                            destination.id,
                            destination,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isArc
                                ? AppColors.textMuted.withValues(alpha: 0.1)
                                : AppColors.background,
                          ),
                          icon: Icon(
                            isArc
                                ? Icons.archive_rounded
                                : Icons.archive_outlined,
                            color: isArc
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
