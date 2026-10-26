import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../../models/recommendation_result_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/archive_controller.dart';
import '../images/adaptive_destination_image.dart';
import '../common/app_icon.dart';

/// Photographic invitation; recommendation explanations belong in the detail.
class DestinationRecommendationCard extends StatelessWidget {
  const DestinationRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });
  final RecommendationResultModel recommendation;
  final VoidCallback onTap;

  Future<void> _hide(BuildContext context) async {
    final archives = context.read<ArchiveController>();
    final messenger = ScaffoldMessenger.of(context);
    final dest = recommendation.destination;
    if (archives.isArchived(dest.id)) return;
    await archives.toggleArchive(dest.id, dest);
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          archives.error ??
              'Destino oculto de Explorar y Para ti. Puedes recuperarlo en Archivados.',
        ),
        action: archives.error == null
            ? SnackBarAction(
                label: 'Deshacer',
                onPressed: () {
                  if (archives.isArchived(dest.id)) {
                    archives.toggleArchive(dest.id, dest);
                  }
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = recommendation.destination;
    final location = [
      d.city,
      d.region,
    ].where((v) => v.trim().isNotEmpty).toSet().join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Semantics(
        container: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DestinationHero(
                    tag: 'recommendation/${d.id}',
                    borderRadius: BorderRadius.circular(30),
                    child: AdaptiveDestinationImage(
                      imagePath: d.imageUrl,
                      cacheWidth:
                          (MediaQuery.sizeOf(context).width *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round()
                              .clamp(720, 1440),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .35, .65, 1],
                        colors: [
                          Color(0x18000000),
                          Colors.transparent,
                          Color(0x45000000),
                          Color(0xDB000000),
                        ],
                      ),
                    ),
                  ),
                ),
                // The content sets the minimum height, and can grow for large text.
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 200),
                        if (recommendation
                            .compatibilityPercentage
                            .isFinite) ...[
                          Tooltip(
                            message:
                                'Afinidad calculada por el motor según tu perfil. No es una probabilidad.',
                            child: Row(
                              children: [
                                const AppIcon(
                                  AppIcons.sparkles,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${recommendation.compatibilityPercentage.round()}% de afinidad',
                                  style: AppTypography.style(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (d.category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .35),
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              d.category,
                              style: AppTypography.style(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          d.name,
                          style: AppTypography.style(
                            fontSize: 27,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            location,
                            style: AppTypography.style(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Descubrir destino',
                                style: AppTypography.style(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.accent,
                              child: Icon(
                                Icons.north_east_rounded,
                                color: Color(0xFF202020),
                                size: 23,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Consumer<FavoritesController>(
                        builder: (context, favorites, _) => IconButton.filled(
                          tooltip: favorites.isFavorite(d.id)
                              ? 'Quitar de favoritos'
                              : 'Guardar en favoritos',
                          onPressed: () => favorites.toggleFavorite(d.id, d),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: favorites.isFavorite(d.id)
                                ? AppColors.discovery
                                : const Color(0xFF202020),
                            minimumSize: const Size(48, 48),
                          ),
                          icon: AppIcon(
                            favorites.isFavorite(d.id)
                                ? AppIcons.heartFilled
                                : AppIcons.heartOutline,
                            color: favorites.isFavorite(d.id)
                                ? AppColors.discovery
                                : const Color(0xFF202020),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: PopupMenuButton<String>(
                          tooltip: 'Opciones del destino',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onSelected: (_) => _hide(context),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'hide',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 20),
                                  SizedBox(width: 10),
                                  Text('Ocultar destino'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ),
                    ],
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
