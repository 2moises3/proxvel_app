import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/visit_controller.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/states/content_skeleton.dart';
import '../../core/widgets/maps/destination_location.dart';
import '../../integration/services/tourism_map_service.dart';
import '../../models/map_marker_model.dart';
import '../../models/visit_model.dart';
import 'widgets/profile_page_bar.dart';

class AtlasNearbyScreen extends StatefulWidget {
  const AtlasNearbyScreen({super.key});
  @override
  State<AtlasNearbyScreen> createState() => _AtlasNearbyScreenState();
}

class _AtlasNearbyScreenState extends State<AtlasNearbyScreen> {
  bool loading = true;
  bool showAll = false;
  String? error;
  List<MapMarkerModel> results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final location = DestinationLocation.shared;
    await location.locate(requestPermission: true);
    if (!mounted) return;
    if (location.position == null) {
      setState(() {
        loading = false;
        error = location.message(
          context,
          fallback: context.l10n.enableLocationForNearby,
        );
      });
      return;
    }
    try {
      final markers = await context.read<TourismMapService>().getMapMarkers();
      if (!mounted) return;
      markers.sort(
        (a, b) => location
            .distance(a.latitude, a.longitude)!
            .compareTo(location.distance(b.latitude, b.longitude)!),
      );
      setState(() {
        results = markers;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = context.l10n.uiNoPudimosCompletarElEscaneoGps;
        });
      }
    }
  }

  void _select(MapMarkerModel marker) {
    if (context.read<VisitController>().activeVisit?.isInProgress == true) {
      context.pushReplacement('/profile/atlas/visit');
      return;
    }
    final distance = DestinationLocation.shared.distance(
      marker.latitude,
      marker.longitude,
    );
    context.read<VisitController>().setPendingDestination(
      PendingSealDestination(
        destinationId: marker.destinationId,
        destinationName: marker.destination,
        latitude: marker.latitude,
        longitude: marker.longitude,
        region: marker.region,
        coverImageUrl: marker.coverImageUrl,
        distanceMeters: distance,
        geofenceRadiusMeters: marker.geofenceRadiusMeters,
        minDwellMinutes: marker.minDwellMinutes,
      ),
    );
    context.pushReplacement('/profile/atlas/visit');
  }

  @override
  Widget build(BuildContext context) {
    final en = context.watch<AppLanguage>().languageCode == 'en';
    final activeVisit =
        context.watch<VisitController>().activeVisit?.isInProgress == true;
    final visible = showAll ? results : results.take(3).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, en ? 'Near you' : 'Cerca de ti'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              en ? 'Places near you' : 'Lugares cerca de ti',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              en
                  ? 'Straight-line GPS distance. The closest place appears first.'
                  : 'Distancia GPS aproximada en línea recta. El lugar más cercano aparece primero.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (activeVisit)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.timelapse_rounded),
                  title: Text(
                    en
                        ? 'A visit is already in progress'
                        : 'Ya tienes una visita en curso',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.pushReplacement('/profile/atlas/visit'),
                ),
              ),
            if (loading) const ContentSkeleton(SkeletonLayout.results),
            if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: Text(en ? 'Try again' : 'Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!loading && error == null && results.isEmpty)
              Text(
                en
                    ? 'No destinations with valid coordinates are available.'
                    : 'No hay destinos con coordenadas disponibles.',
              ),
            for (var i = 0; i < visible.length; i++)
              _PlaceCard(
                marker: visible[i],
                featured: i == 0,
                activeVisit: activeVisit,
                onSelect: () => _select(visible[i]),
              ),
            if (!showAll && results.length > 3)
              TextButton(
                onPressed: () => setState(() => showAll = true),
                child: Text(
                  en
                      ? 'See all ${results.length} places'
                      : 'Ver los ${results.length} lugares',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.marker,
    required this.featured,
    required this.activeVisit,
    required this.onSelect,
  });
  final MapMarkerModel marker;
  final bool featured;
  final bool activeVisit;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) {
    final en = context.watch<AppLanguage>().languageCode == 'en';
    final distance = DestinationLocation.shared.distance(
      marker.latitude,
      marker.longitude,
    );
    final inside = distance != null && distance <= marker.geofenceRadiusMeters;
    final distanceText = distance == null
        ? '—'
        : distance < 1000
        ? '${distance.round()} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: featured ? AppColors.accent : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (marker.coverImageUrl case final imageUrl?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: featured ? 132 : 96,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.accentSoft,
                      child: const Icon(
                        Icons.landscape_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (featured)
              Text(
                en ? 'CLOSEST MATCH' : 'EL MÁS CERCANO',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            Text(
              context.destinationTitle(
                marker.destinationId,
                marker.destination,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              [distanceText, marker.region, '${marker.minDwellMinutes} min']
                  .whereType<String>()
                  .where((part) => part.isNotEmpty)
                  .join(' · '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 5),
            Text(
              inside
                  ? (en ? 'Within visit radius' : 'Dentro del radio de visita')
                  : (en
                        ? 'Approach within ${marker.geofenceRadiusMeters} m to start'
                        : 'Acércate a ${marker.geofenceRadiusMeters} m para iniciar'),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/destination/${Uri.encodeComponent(marker.destinationId)}',
                    ),
                    child: Text(en ? 'Details' : 'Ver ficha'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: activeVisit ? null : onSelect,
                    child: Text(
                      activeVisit
                          ? (en ? 'Visit active' : 'Visita activa')
                          : (en ? 'Choose' : 'Elegir'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
