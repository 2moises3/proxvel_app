import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/maps/animated_map_marker.dart';
import '../../controllers/tourism_map_controller.dart';
import '../../models/map_marker_model.dart';
import '../../core/widgets/maps/location_consent.dart';
import 'package:url_launcher/url_launcher.dart';

class DestinationMapScreen extends StatefulWidget {
  final String destinationId;
  const DestinationMapScreen({super.key, required this.destinationId});

  @override
  State<DestinationMapScreen> createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  final MapController _mapController = MapController();

  final LatLng _initialCenter = const LatLng(-9.1900, -75.0152);
  final double _initialZoom = 5.0;
  
  MapMarkerModel? _lastSelectedMarker;
  LatLng? _lastUserLocation;
  bool _destinationUnavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndSelect());
  }

  Future<void> _loadAndSelect() async {
    final controller = context.read<TourismMapController>();
    setState(() => _destinationUnavailable = false);
    await controller.loadMarkers();
    if (!mounted || controller.errorMessage != null) return;
    MapMarkerModel? marker;
    for (final item in controller.markers) {
      if (item.destinationId == widget.destinationId) {
        marker = item;
        break;
      }
    }
    if (marker == null) {
      setState(() => _destinationUnavailable = true);
      return;
    }
    await _selectWithConsent(controller, marker);
  }

  /// Explica para qué se usa el GPS antes de pedir el permiso; sin consentimiento solo se muestra el destino.
  Future<void> _selectWithConsent(TourismMapController controller, MapMarkerModel marker) async {
    final allowed = await ensureLocationConsent(context);
    if (!mounted) return;
    await controller.selectDestination(marker, useLocation: allowed);
  }

  void _handleStateChanges(TourismMapController controller) {
    if (controller.selectedMarker != null &&
        (controller.selectedMarker != _lastSelectedMarker ||
            controller.userLocation != _lastUserLocation)) {
      _lastSelectedMarker = controller.selectedMarker;
      _lastUserLocation = controller.userLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.selectedMarker == null) return;
        final marker = controller.selectedMarker!;
        if (controller.userLocation == null) {
          _mapController.move(LatLng(marker.latitude, marker.longitude), 12);
        } else {
          _mapController.fitCamera(CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([
              controller.userLocation!,
              LatLng(marker.latitude, marker.longitude),
            ]),
            padding: const EdgeInsets.all(50),
          ));
        }
      });
    } else if (controller.selectedMarker == null && _lastSelectedMarker != null) {
      _lastSelectedMarker = null;
      _lastUserLocation = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_initialCenter, _initialZoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubicación del Destino',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<TourismMapController>().clearSelection();
            context.pop();
          },
        ),
      ),
      body: Consumer<TourismMapController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_destinationUnavailable) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_outlined,
                        size: 44, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpace.field),
                    const Text(
                      'Este destino aún no tiene una ubicación disponible en el mapa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.field),
                    TextButton(onPressed: _loadAndSelect,
                        child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }

          if (controller.errorMessage != null && controller.selectedMarker == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpace.field),
                    const Text(
                      'No pudimos cargar la ubicación del destino en el mapa. Verifica tu conexión e intenta nuevamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpace.section),
                    ElevatedButton.icon(
                      onPressed: _loadAndSelect,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          _handleStateChanges(controller);

          // Determinar marcadores a mostrar
          List<Marker> markers = [];
          List<Polyline> polylines = [];

          if (controller.selectedMarker != null) {
            // Mostrar solo el destino seleccionado y el usuario
            final m = controller.selectedMarker!;
            markers.add(
              Marker(
                point: LatLng(m.latitude, m.longitude),
                width: 50,
                height: 50,
                child: const AnimatedMapMarker(color: AppColors.primary),
              ),
            );

            if (controller.userLocation != null) {
              markers.add(
                Marker(
                  point: controller.userLocation!,
                  width: 50,
                  height: 50,
                  child: const AnimatedMapMarker(color: Colors.blue, icon: Icons.person_pin_circle),
                ),
              );

              polylines.add(
                Polyline(
                  points: [controller.userLocation!, LatLng(m.latitude, m.longitude)],
                  strokeWidth: 4.0,
                  color: Colors.blueAccent.withValues(alpha: 0.7),
                ),
              );
            }
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(-9.1900, -75.0152),
                  initialZoom: 5.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.m3biznovatech.proxvel',
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),
              if (controller.selectedMarker != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildDistanceOverlay(context, controller),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDistanceOverlay(BuildContext context, TourismMapController controller) {
    final m = controller.selectedMarker!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.shade50,
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              m.destination,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.related),
            Text(
              [m.city, m.region].whereType<String>().where((p) => p.trim().isNotEmpty).join(', '),
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.field),
            if (controller.distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_car, color: AppColors.primary),
                    const SizedBox(width: AppSpace.related),
                    Text(
                      'Distancia estimada: ${controller.distanceKm!.toStringAsFixed(1)} km',
                      style: AppTextStyles.cardTitle,
                    ),
                  ],
                ),
              )
            else if (controller.locationDeclined)
              OutlinedButton.icon(
                onPressed: () => _selectWithConsent(controller, m),
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Calcular distancia desde mi ubicación'),
              )
            else if (controller.errorMessage == null)
              const Center(child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              )),
          ],
        ),
      ),
    );
  }
}
