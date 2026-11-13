import '../../localization/l10n.dart';
import '../../../core/widgets/cards/favorite_feedback.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/destination_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../images/adaptive_destination_image.dart';

/// Versatile destination card with image overlay.
/// Used in "Cerca de ti" and general listing contexts.
class DestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback onTap;
  final bool showFavoriteButton;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 155 / 200,
        child: Container(
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Image ──
              AdaptiveDestinationImage(imagePath: destination.imageUrl),

              // ── Gradient ──
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),

              // ── Distance badge ──
              if (destination.distanceKm != null)
                Positioned(
                  bottom: 52,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDistance(destination.distanceKm!),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // ── Name ──
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: Text(
                  context.destinationTitle(destination.id, destination.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),

              // ── Favorite Button ──
              if (showFavoriteButton)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesController>(
                    builder: (context, favCtrl, child) {
                      final isFav = favCtrl.isFavorite(destination.id);
                      return GestureDetector(
                        onTap: () => toggleFavoriteWithFeedback(context, favCtrl, destination.id, destination),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.error : Colors.white,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 100) return '${km.round()} km';
    return '${km.round()} km';
  }
}
