import 'package:flutter/material.dart';
import '../../../models/map_marker_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../core/widgets/maps/map_presentation.dart';

class MapPlaceCard extends StatelessWidget {
  const MapPlaceCard({
    super.key,
    required this.place,
    required this.onOpen,
    required this.onGoogleMaps,
    required this.onLocate,
    this.distanceMeters,
    this.onClose,
    this.locationBusy = false,
  });
  final MapMarkerModel place;
  final VoidCallback onOpen, onGoogleMaps, onLocate;
  final VoidCallback? onClose;
  final double? distanceMeters;
  final bool locationBusy;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (place.category?.isNotEmpty == true)
                Expanded(
                  child: Text(
                    place.category!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.discovery,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (onClose != null)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    tooltip: 'Cerrar selección',
                    padding: EdgeInsets.zero,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ),
            ],
          ),
          Text(
            place.destination,
            maxLines: largeText ? 4 : 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              height: 1.12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (place.locationLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              place.locationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (place.recommendedDuration?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const AppIcon(
                  AppIcons.clock,
                  size: 15,
                  color: AppColors.discovery,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.recommendedDuration!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (place.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              place.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Descubrir destino',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Ver detalle de ${place.destination}',
                onPressed: onOpen,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const AppIcon(
                  AppIcons.externalLink,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (largeText) ...[
              AdaptiveDestinationImage(
                imagePath: place.coverImageUrl ?? '',
                width: double.infinity,
                height: 112,
                cacheWidth: 600,
              ),
              content,
            ] else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 106,
                      child: GestureDetector(
                        onTap: onOpen,
                        child: AdaptiveDestinationImage(
                          imagePath: place.coverImageUrl ?? '',
                          cacheWidth: 320,
                        ),
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  TextButton.icon(
                    onPressed: distanceMeters == null && !locationBusy
                        ? onLocate
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      disabledForegroundColor: AppColors.textSecondary,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const AppIcon(
                      AppIcons.mapPin,
                      size: 16,
                      color: AppColors.discovery,
                    ),
                    label: Text(
                      locationBusy
                          ? 'Ubicando…'
                          : distanceMeters == null
                          ? 'Ver mi distancia'
                          : '${mapDistanceLabel(distanceMeters!)} en línea recta',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onGoogleMaps,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.discovery,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const AppIcon(
                      AppIcons.externalLink,
                      size: 15,
                      color: AppColors.discovery,
                    ),
                    label: const Text('Google Maps'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
