import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../core/widgets/maps/destination_location.dart';
import '../../../core/widgets/maps/map_photo_pin.dart';
import '../../../core/widgets/maps/map_presentation.dart';
import '../../../core/widgets/maps/tourism_basemap.dart';

/// Real, geographically centered preview; vertical drags remain page scrolling.
class MapLocationPreview extends StatelessWidget {
  const MapLocationPreview({
    super.key,
    this.latitude,
    this.longitude,
    this.destinationId,
    this.destinationName,
    this.imageUrl,
    this.locationLabel,
  });
  final double? latitude, longitude;
  final String? destinationId, destinationName, imageUrl, locationLabel;
  bool get _hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  void _open(BuildContext context) => context.push(
    destinationId == null
        ? '/map'
        : '/map/destination/${Uri.encodeComponent(destinationId!)}',
  );

  Future<void> _external(BuildContext context) async {
    try {
      if (await launchUrl(
        googleMapsLocation(latitude!, longitude!),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir Google Maps. Inténtalo otra vez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Encuentra tu próxima parada',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      if (!_hasCoordinates)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Este destino aún no tiene coordenadas publicadas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        )
      else ...[
        if (locationLabel?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              locationLabel!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitude!, longitude!),
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                    onTap: (_, _) => _open(context),
                  ),
                  children: [
                    const TourismTileLayer(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude!, longitude!),
                          width: 72,
                          height: 84,
                          alignment: Alignment.topCenter,
                          child: MapPhotoPin(
                            imageUrl: imageUrl ?? '',
                            label: destinationName ?? 'Ver ubicación',
                            selected: true,
                            onTap: () => _open(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton.filled(
                    tooltip: 'Ampliar mapa del destino',
                    onPressed: () => _open(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    icon: const AppIcon(
                      AppIcons.externalLink,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Positioned(
                  left: 10,
                  bottom: 10,
                  child: TourismMapAttribution(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: DestinationLocation.shared,
          builder: (context, _) {
            final location = DestinationLocation.shared;
            final distance = location.distance(latitude, longitude);
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          AppIcons.mapPin,
                          size: 20,
                          color: AppColors.discovery,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            distance == null
                                ? '¿Qué tan cerca estás?'
                                : '${mapDistanceLabel(distance)} en línea recta',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (distance == null)
                          TextButton(
                            onPressed: location.busy
                                ? null
                                : () => location.locate(),
                            child: Text(
                              location.busy ? 'Ubicando…' : 'Activar ubicación',
                            ),
                          ),
                      ],
                    ),
                    if (location.error != null)
                      Text(
                        location.error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () => _open(context),
                          child: const Text('Explorar mapa'),
                        ),
                        TextButton.icon(
                          onPressed: () => _external(context),
                          icon: const AppIcon(
                            AppIcons.externalLink,
                            size: 16,
                            color: AppColors.discovery,
                          ),
                          label: const Text('Google Maps'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ],
  );
}
