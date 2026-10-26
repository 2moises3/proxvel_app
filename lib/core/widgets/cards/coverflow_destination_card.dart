import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../navigation/destination_opening.dart';
import '../../../models/destination_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../images/adaptive_destination_image.dart';
import '../common/app_icon.dart';

class CoverflowDestinationCard extends StatelessWidget {
  const CoverflowDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });
  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DestinationHero(
            tag: 'coverflow/${destination.id}',
            borderRadius: BorderRadius.circular(28),
            child: ColorFiltered(
              // Subtle saturation/contrast lift; keep destination photos natural.
              colorFilter: const ColorFilter.matrix([
                1.1383,
                -.0893,
                -.0090,
                0,
                -5.1,
                -.0265,
                1.0755,
                -.0090,
                0,
                -5.1,
                -.0265,
                -.0893,
                1.1558,
                0,
                -5.1,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: AdaptiveDestinationImage(
                imagePath: destination.imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 1000,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xD9000000),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Semantics(
                button: true,
                label: 'Ver ${destination.name}',
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Consumer<FavoritesController>(
              builder: (context, favorites, _) {
                final saved = favorites.isFavorite(destination.id);
                return IconButton.filled(
                  tooltip: saved
                      ? 'Quitar de favoritos'
                      : 'Guardar en favoritos',
                  onPressed: () =>
                      favorites.toggleFavorite(destination.id, destination),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: .28),
                    foregroundColor: saved ? AppColors.accent : Colors.white,
                  ),
                  icon: AppIcon(
                    saved ? AppIcons.heartFilled : AppIcons.heartOutline,
                    color: saved ? AppColors.accent : Colors.white,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: IconButton.filled(
              tooltip: 'Ver destino',
              onPressed: onTap,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF202020),
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.north_east_rounded),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      destination.city,
                      destination.region,
                    ].where((part) => part.trim().isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (destination.category.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .20),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        destination.category,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
