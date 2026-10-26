import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_typography.dart';
import '../../../controllers/search_controller.dart' show SearchResultItem;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../core/widgets/common/app_icon.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.item, required this.onTap});
  final SearchResultItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final d = item.destination;
    final location = [
      d.city,
      d.region,
    ].where((s) => s.trim().isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBECEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 2.5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 92,
                    height: 108,
                    child: DestinationHero(
                      tag: 'search/${d.id}',
                      borderRadius: BorderRadius.circular(14),
                      child: AdaptiveDestinationImage(imagePath: d.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.compatibility != null) ...[
                        Text(
                          '✦ ${item.compatibility}% de afinidad',
                          style: AppTypography.style(
                            fontSize: 12,
                            color: AppColors.discovery,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ] else if (d.category.isNotEmpty) ...[
                        Text(
                          d.category,
                          style: AppTypography.style(
                            fontSize: 12,
                            color: AppColors.discovery,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(
                        d.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF202020),
                          height: 1.2,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          location,
                          style: AppTypography.style(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Consumer<FavoritesController>(
                  builder: (context, favorites, _) => IconButton(
                    tooltip: favorites.isFavorite(d.id)
                        ? 'Quitar de favoritos'
                        : 'Guardar en favoritos',
                    onPressed: () => favorites.toggleFavorite(d.id, d),
                    icon: AppIcon(
                      favorites.isFavorite(d.id)
                          ? AppIcons.heartFilled
                          : AppIcons.heartOutline,
                      size: 20,
                      color: favorites.isFavorite(d.id)
                          ? AppColors.discovery
                          : const Color(0xFF626870),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
