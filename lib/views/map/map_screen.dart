import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/maps/animated_map_marker.dart';
import '../../controllers/tourism_map_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourismMapController>().loadMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa Turístico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TourismMapController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.filteredMarkers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpace.field),
                    const Text(
                      'No pudimos cargar los destinos en el mapa. Verifica tu conexión e intenta nuevamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpace.section),
                    ElevatedButton.icon(
                      onPressed: () => controller.loadMarkers(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Determinar marcadores a mostrar: TODOS los destinos
          List<Marker> markers = controller.filteredMarkers.map((m) {
            return Marker(
              point: LatLng(m.latitude, m.longitude),
              width: 50,
              height: 50,
              child: AnimatedMapMarker(
                color: AppColors.primary,
                onTap: () => context.push('/destination/${m.destinationId}'),
              ),
            );
          }).toList();

          return Column(
            children: [
              _buildCategoryFilters(context, controller),
              Expanded(
                child: FlutterMap(
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
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, TourismMapController controller) {
    final categories = controller.availableCategories;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.related),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = controller.selectedCategory == null;
            return FilterChip(
              label: const Text('Todos'),
              selected: isSelected,
              onSelected: (_) => controller.setCategory(null),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }
          final category = categories[index - 1];
          final isSelected = controller.selectedCategory == category;
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => controller.setCategory(category),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primary,
          );
        },
      ),
    );
  }
}
