import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/maps/destination_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/destination_model.dart';

class NearbyDestinationsSection extends StatefulWidget {
  const NearbyDestinationsSection({
    super.key,
    required this.destinations,
    required this.onOpen,
  });
  final List<DestinationModel> destinations;
  final ValueChanged<DestinationModel> onOpen;
  @override
  State<NearbyDestinationsSection> createState() =>
      _NearbyDestinationsSectionState();
}

class _NearbyDestinationsSectionState extends State<NearbyDestinationsSection> {
  final _location = DestinationLocation.shared;
  Position? get _position => _location.position;
  bool get _busy => _location.busy;
  String? get _message => _location.error;
  @override
  void initState() {
    super.initState();
    _location.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _location.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _locate() => _location.locate();

  @override
  Widget build(BuildContext context) {
    final nearby = <({DestinationModel destination, double km})>[];
    final position = _position;
    if (position != null) {
      for (final d in widget.destinations) {
        final lat = d.latitude;
        final lon = d.longitude;
        if (lat == null ||
            lon == null ||
            !lat.isFinite ||
            !lon.isFinite ||
            lat.abs() > 90 ||
            lon.abs() > 180) {
          continue;
        }
        final km =
            Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lon,
            ) /
            1000;
        if (km <= 100) nearby.add((destination: d, km: km));
      }
      nearby.sort((a, b) => a.km.compareTo(b.km));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cerca de mí',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.near_me_outlined,
                color: AppColors.discovery,
                size: 30,
              ),
              const SizedBox(height: 12),
              Text(
                _message ??
                    (position == null
                        ? 'Tu próxima escapada podría estar más cerca de lo que piensas.'
                        : nearby.isEmpty
                        ? 'Aún no hay destinos del catálogo a menos de 100 km de ti.'
                        : '${nearby.length} destinos a menos de 100 km.'),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                position == null
                    ? 'Usaremos tu ubicación al pulsar el botón. También puedes explorar sin compartirla.'
                    : 'Distancias en línea recta; no representan el recorrido por carretera.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _locate,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _busy
                      ? 'Buscando ubicación…'
                      : position == null
                      ? 'Ver cercanos'
                      : 'Actualizar ubicación',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.discovery,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
        if (nearby.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final item in nearby.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => widget.onOpen(item.destination),
              title: Text(item.destination.name),
              subtitle: Text(
                '${item.km.toStringAsFixed(1)} km · ${item.destination.region}',
              ),
              trailing: const Icon(Icons.north_east_rounded, size: 20),
            ),
        ],
      ],
    );
  }
}
