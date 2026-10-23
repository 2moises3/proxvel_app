import 'package:flutter/material.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../theme/app_layout.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/recommendation_result_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/archive_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../images/adaptive_destination_image.dart';

/// Card showing a personalized recommendation with a ranking badge.
class DestinationRecommendationCard extends StatelessWidget {
  final RecommendationResultModel recommendation;
  final VoidCallback onTap;
  final int index;

  const DestinationRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dest = recommendation.destination;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        width: double.infinity,
        height: (MediaQuery.sizeOf(context).height * .62).clamp(390.0, 480.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          // Borde sutil para darle volumen sin usar blur (glass edge)
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppRadius.card,
          ), // Ligeramente menor por el borde
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Background Image ──
              DestinationHero(
                tag: 'recommendation/${dest.id}',
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: AdaptiveDestinationImage(imagePath: dest.imageUrl),
              ),

              // ── 2. Deep Cinematic Gradient ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: 0.3,
                      ), // Top shadow for badges
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: 0.95,
                      ), // Deep bottom shadow
                    ],
                    stops: const [0.0, 0.3, 0.5, 1.0],
                  ),
                ),
              ),

              // ── 3. Top Floating Badges (Solid & Crisp) ──
              Positioned(
                top: 24,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ranking Badge (Solid White)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpace.micro),
                          Text(
                            '#${recommendation.rankingPosition ?? index + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Archivar + Favorito (botones sólidos blancos)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Archivar: lo saca de "Para Ti" y Explorar (se gestiona en Perfil → Archivados)
                        GestureDetector(
                          onTap: () => context
                              .read<ArchiveController>()
                              .toggleArchive(dest.id, dest),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.archive_outlined,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Favorito
                        Consumer<FavoritesController>(
                          builder: (context, favCtrl, child) {
                            final isFav = favCtrl.isFavorite(dest.id);
                            return GestureDetector(
                              onTap: () =>
                                  favCtrl.toggleFavorite(dest.id, dest),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? const Color(0xFFFF4B4B)
                                      : Colors.black,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 4. Bottom Information Overlay ──
              Positioned(
                bottom: 28,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category (Editorial Typography, No Background)
                    if (dest.category.isNotEmpty) ...[
                      Text(
                        dest.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing:
                              3.0, // Amplio tracking para look premium
                        ),
                      ),
                      const SizedBox(height: AppSpace.related),
                    ],

                    Text(
                      dest.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.content),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dest.city,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // ── Etiqueta cualitativa + mejor mes (en vez del % crudo) ──
                    const SizedBox(height: AppSpace.content),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                recommendation.label,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((recommendation.bestMonthName ?? '')
                            .isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: AppSpace.micro),
                          Text(
                            'Mejor mes: ${_cap(recommendation.bestMonthName!)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    if ((recommendation.contextStatus ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        recommendation.monthName == null
                            ? 'Clima y afluencia considerados'
                            : 'Para ${recommendation.monthName} · clima y afluencia considerados',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
