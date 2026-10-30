import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/tourism_map_controller.dart';
import '../../controllers/visit_controller.dart';
import '../../models/map_marker_model.dart';
import '../../models/visit_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/widgets/common/app_icon.dart';
import '../../core/widgets/images/adaptive_destination_image.dart';
import '../../core/widgets/maps/destination_location.dart';
import '../../core/widgets/maps/map_photo_pin.dart';
import '../../core/widgets/maps/map_presentation.dart';
import '../../core/widgets/maps/tourism_basemap.dart';
import 'widgets/map_place_card.dart';

/// One map experience for the atlas and a focused destination. Selection, search
/// and camera belong to this route, so opening a detail cannot reset the atlas.
class TourismMapView extends StatefulWidget {
  const TourismMapView({
    super.key,
    this.destinationId,
    this.embedded = false,
    this.tileProvider,
    this.location,
  });
  final String? destinationId;
  final bool embedded;
  final TileProvider? tileProvider;
  final DestinationLocation? location;
  @override
  State<TourismMapView> createState() => _TourismMapViewState();
}

class _TourismMapViewState extends State<TourismMapView>
    with SingleTickerProviderStateMixin {
  final _map = MapController();
  final _search = TextEditingController();
  late final _location = widget.location ?? DestinationLocation.shared;
  late final _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  String? _category, _selectedId, _pinnedDestinationId;
  bool _ready = false, _refreshScheduled = false, _tilesFailed = false;
  bool _centeredOnUser = false;
  Timer? _cameraRefresh;
  bool _showSearchResults = false;
  LatLng? _from, _to;
  int _tileRevision = 0;
  double _fromZoom = 5, _toZoom = 5;
  bool get _focused => widget.destinationId != null;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.destinationId;
    _flight.addListener(_advanceCamera);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant TourismMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationId != widget.destinationId) {
      _selectedId = widget.destinationId;
      _category = null;
      _search.clear();
      _showSearchResults = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted) return;
    final controller = context.read<TourismMapController>();
    if (_location.position == null && !_location.busy) {
      // Resolve an existing permission alongside the catalogue request.
      unawaited(
        _location.locate(requestPermission: false).then((_) {
          if (mounted) _centerOnKnownUser();
        }),
      );
    }
    await controller.loadMarkers(refresh: refresh);
    if (!mounted) return;
    if (_focused || !_centeredOnUser) _fitPlaces(_places(controller));
    _centerOnKnownUser();
  }

  void _centerOnKnownUser() {
    if (_focused || !_ready || _centeredOnUser) return;
    final position = _location.position;
    if (position == null) return;
    _centeredOnUser = true;
    _fly(LatLng(position.latitude, position.longitude), 10);
  }

  List<MapMarkerModel> _places(TourismMapController c) => _focused
      ? c.markers.where((m) => m.destinationId == widget.destinationId).toList()
      : filterMapPlaces(c.markers, query: _search.text, category: _category);

  @override
  void dispose() {
    _cameraRefresh?.cancel();
    _flight.dispose();
    _map.dispose();
    _search.dispose();
    super.dispose();
  }

  void _advanceCamera() {
    if (!_ready || _from == null || _to == null) return;
    final t = Curves.easeInOutCubic.transform(_flight.value);
    _map.move(
      LatLng(
        _from!.latitude + (_to!.latitude - _from!.latitude) * t,
        _from!.longitude + (_to!.longitude - _from!.longitude) * t,
      ),
      _fromZoom + (_toZoom - _fromZoom) * t,
    );
  }

  void _fly(LatLng point, double zoom) {
    if (!_ready) return;
    _flight.stop();
    _from = _map.camera.center;
    _to = point;
    if (_selectedId != null) {
      final height = MediaQuery.sizeOf(context).height;
      final upper = MediaQuery.paddingOf(context).top + (_focused ? 105 : 160);
      final lower =
          height - (widget.embedded ? 112 : 20) - math.min(height * .49, 350);
      final desiredY = (upper + lower) / 2;
      final offset = Offset(0, (desiredY - height / 2).clamp(-height * .3, 0));
      _to = _map.camera.unprojectAtZoom(
        _map.camera.projectAtZoom(point, zoom) - offset,
        zoom,
      );
    }
    _fromZoom = _map.camera.zoom;
    _toZoom = zoom.clamp(3, 18);
    if (MediaQuery.disableAnimationsOf(context)) {
      _map.move(_to!, _toZoom);
    } else {
      _flight.forward(from: 0);
    }
  }

  void _fitPlaces(List<MapMarkerModel> places) {
    if (!_ready || places.isEmpty) return;
    _flight.stop();
    if (places.length == 1) {
      _fly(LatLng(places.first.latitude, places.first.longitude), 13);
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(
          places.map((m) => LatLng(m.latitude, m.longitude)).toList(),
        ),
        padding: EdgeInsets.fromLTRB(
          65,
          _focused ? 125 : 200,
          65,
          widget.embedded ? 220 : 130,
        ),
        maxZoom: 15,
      ),
    );
  }

  void _cameraChanged(MapCamera camera, bool gesture) {
    if (gesture) _flight.stop();
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    // flutter_map moves its own layers; regrouping photo pins does not need a
    // rebuild on every animation frame or touch movement.
    _cameraRefresh = Timer(const Duration(milliseconds: 100), () {
      _refreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _select(MapMarkerModel place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedId = place.destinationId;
      _showSearchResults = false;
    });
    // The selected point stays above the floating card, not hidden behind it.
    _fly(
      LatLng(place.latitude, place.longitude),
      math.max(_map.camera.zoom, 12),
    );
  }

  Future<void> _locate({bool center = true}) async {
    FocusScope.of(context).unfocus();
    await _location.locate(requestPermission: true);
    if (!mounted) return;
    final point = _location.position;
    if (point != null && center) {
      _fly(LatLng(point.latitude, point.longitude), 13);
    } else if (_location.error != null) {
      _message(_location.error!);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(20, 0, 20, widget.embedded ? 120 : 20),
    ),
  );

  Future<void> _googleMaps(MapMarkerModel place) async {
    try {
      final opened = await launchUrl(
        googleMapsLocation(place.latitude, place.longitude),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _message('No pudimos abrir Google Maps. Inténtalo otra vez.');
      }
    } catch (_) {
      if (mounted) {
        _message('No pudimos abrir Google Maps. Inténtalo otra vez.');
      }
    }
  }

  void _open(MapMarkerModel place) => context.push(
    '/destination/${Uri.encodeComponent(place.destinationId)}?source=map',
  );

  Future<void> _listPlaces(
    List<MapMarkerModel> places, {
    String title = 'Elige tu próxima parada',
  }) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<MapMarkerModel>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: places.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = places[i];
                    return Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context, p),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AdaptiveDestinationImage(
                                  imagePath: p.coverImageUrl ?? '',
                                  width: 64,
                                  height: 72,
                                  cacheWidth: 180,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.destination,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (p.locationLabel.isNotEmpty)
                                      Text(
                                        p.locationLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const AppIcon(
                                AppIcons.chevronRight,
                                size: 18,
                                color: AppColors.discovery,
                              ),
                            ],
                          ),
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
    );
    if (mounted && selected != null) _select(selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: const Color(0xFFE5EAE5),
    body: Consumer<TourismMapController>(
      builder: (context, controller, _) => ListenableBuilder(
        listenable: _location,
        builder: (context, _) => LayoutBuilder(
          builder: (context, bounds) {
            final places = _places(controller);
            final selected = places
                .where((m) => m.destinationId == _selectedId)
                .firstOrNull;
            final bottom =
                (widget.embedded ? 112.0 : 20.0) +
                MediaQuery.viewPaddingOf(context).bottom;
            final compact = bounds.maxHeight < 600;
            final user = _location.position;
            final groups = _ready
                ? groupMapPhotos(
                    places,
                    _map.camera.latLngToScreenOffset,
                    selectedId: _selectedId,
                  )
                : <MapPhotoGroup>[];
            final categories =
                controller.markers
                    .map((m) => m.category)
                    .whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
            final pinnedPlace = _pinnedDestinationId == null
                ? null
                : (places
                          .where((p) => p.destinationId == _pinnedDestinationId)
                          .firstOrNull ??
                      controller.markers
                          .where((p) => p.destinationId == _pinnedDestinationId)
                          .firstOrNull);
            return Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: const LatLng(-9.19, -75.0152),
                      initialZoom: 5,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        _ready = true;
                        _fitPlaces(places);
                        _centerOnKnownUser();
                        setState(() {});
                      },
                      onPositionChanged: _cameraChanged,
                      onTap: (_, _) {
                        FocusScope.of(context).unfocus();
                        if (!_focused) {
                          setState(() {
                            _selectedId = null;
                            _showSearchResults = false;
                          });
                        }
                      },
                    ),
                    children: [
                      TourismTileLayer(
                        key: ValueKey(_tileRevision),
                        tileProvider: widget.tileProvider,
                        onError: () {
                          if (!_tilesFailed) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _tilesFailed = true);
                            });
                          }
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          for (final group in groups)
                            Marker(
                              point: group.point,
                              alignment: Alignment.topCenter,
                              width: 72,
                              height: 84,
                              child: MapPhotoPin(
                                imageUrl: group.items.first.coverImageUrl ?? '',
                                label: group.items.length > 1
                                    ? '${group.items.length} destinos cercanos'
                                    : group.items.first.destination,
                                count: group.items.length,
                                selected:
                                    group.items.first.destinationId ==
                                    _selectedId,
                                pinned: group.items.any(
                                  (item) =>
                                      item.destinationId ==
                                      _pinnedDestinationId,
                                ),
                                onTap: () {
                                  if (group.items.length == 1) {
                                    _select(group.items.first);
                                  } else if (_map.camera.zoom >= 16) {
                                    _listPlaces(
                                      group.items,
                                      title: 'Muy cerca, historias distintas',
                                    );
                                  } else {
                                    _fitPlaces(group.items);
                                  }
                                },
                              ),
                            ),
                          // Paint the traveler above photo pins when they overlap.
                          if (user != null)
                            Marker(
                              point: LatLng(user.latitude, user.longitude),
                              width: 36,
                              height: 36,
                              child: Semantics(
                                label: 'Tu ubicación aproximada',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.discovery.withValues(
                                      alpha: .18,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.discovery,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // A light veil keeps the floating search readable without boxing in the map.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _focused ? 120 : 200,
                  child: const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 16,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        children: [
                          _searchBar(),
                          if (!_focused && categories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 46,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length + 1,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final category = i == 0
                                      ? null
                                      : categories[i - 1];
                                  return ChoiceChip(
                                    label: Text(category ?? 'Todos'),
                                    selected: _category == category,
                                    showCheckmark: false,
                                    selectedColor: AppColors.accent,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: _category == category
                                          ? AppColors.accent
                                          : Colors.white,
                                    ),
                                    shape: const StadiumBorder(),
                                    labelStyle: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _category = category;
                                        _selectedId = null;
                                      });
                                      _fitPlaces(_places(controller));
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_showSearchResults && !_focused) ...[
                            const SizedBox(height: 10),
                            _searchResults(places),
                          ],
                          if (controller.isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top:
                      MediaQuery.paddingOf(context).top +
                      (_focused ? 100 : 152),
                  child: Column(
                    children: [
                      _control(
                        'Mi ubicación',
                        null,
                        _location.busy ? null : () => _locate(),
                        active: user != null,
                        icon: Icons.my_location_rounded,
                        loading: _location.busy,
                      ),
                      const SizedBox(height: 8),
                      _control(
                        _focused
                            ? 'Centrar destino'
                            : 'Ver todos los resultados',
                        AppIcons.compass,
                        () => _fitPlaces(places),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        _control(
                          'Acercar mapa',
                          null,
                          () => _fly(_map.camera.center, _map.camera.zoom + 1),
                          icon: Icons.add_rounded,
                        ),
                        const SizedBox(height: 8),
                        _control(
                          'Alejar mapa',
                          null,
                          () => _fly(_map.camera.center, _map.camera.zoom - 1),
                          icon: Icons.remove_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: bottom,
                  right: 20,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: AnimatedSize(
                        duration: AppMotion.duration(context),
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: bounds.maxHeight * (compact ? .48 : .49),
                          ),
                          child: SingleChildScrollView(
                            child: _bottomPanel(controller, places, selected),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top:
                      MediaQuery.paddingOf(context).top + (_focused ? 84 : 132),
                  child: const TourismMapAttribution(),
                ),
                if (pinnedPlace != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    top:
                        MediaQuery.paddingOf(context).top +
                        (_focused ? 84 : 140),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _pinnedBanner(pinnedPlace),
                      ),
                    ),
                  ),
                if (_tilesFailed)
                  Positioned(
                    left: 20,
                    right: 80,
                    top:
                        MediaQuery.paddingOf(context).top +
                        (_focused ? 92 : 150),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'El fondo del mapa no pudo cargar. Tus destinos siguen disponibles.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Reintentar mapa',
                              onPressed: () => setState(() {
                                _tilesFailed = false;
                                _tileRevision++;
                              }),
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _searchBar() => Material(
    color: Colors.white,
    elevation: 8,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(28),
    child: Row(
      children: [
        if (!widget.embedded)
          IconButton(
            tooltip: 'Volver',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const Padding(
            padding: EdgeInsets.only(left: 18),
            child: AppIcon(
              AppIcons.search,
              size: 21,
              color: AppColors.discovery,
            ),
          ),
        Expanded(
          child: _focused
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 17),
                  child: Text(
                    'Ubicación del destino',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Destino, ciudad o región',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 17,
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    _selectedId = null;
                    _showSearchResults = _search.text.trim().isNotEmpty;
                  }),
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    setState(() => _showSearchResults = false);
                    _fitPlaces(_places(context.read<TourismMapController>()));
                  },
                ),
        ),
        if (!_focused && _search.text.isNotEmpty)
          IconButton(
            tooltip: 'Limpiar búsqueda',
            onPressed: () {
              setState(() {
                _search.clear();
                _selectedId = null;
                _showSearchResults = false;
              });
              _fitPlaces(_places(context.read<TourismMapController>()));
            },
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        const SizedBox(width: 8),
      ],
    ),
  );

  Widget _searchResults(List<MapMarkerModel> places) => Material(
    color: Colors.white,
    elevation: 8,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: places.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No encontramos coincidencias. Prueba con otra región o destino.',
            ),
          )
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.min(210, MediaQuery.sizeOf(context).height * .28),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(6),
              itemCount: places.length,
              itemBuilder: (context, i) {
                final place = places[i];
                return ListTile(
                  onTap: () => _select(place),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AdaptiveDestinationImage(
                      imagePath: place.coverImageUrl ?? '',
                      width: 46,
                      height: 46,
                      cacheWidth: 120,
                    ),
                  ),
                  title: Text(
                    place.destination,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: place.locationLabel.isEmpty
                      ? null
                      : Text(
                          place.locationLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                  trailing: const AppIcon(
                    AppIcons.chevronRight,
                    size: 17,
                    color: AppColors.discovery,
                  ),
                );
              },
            ),
          ),
  );

  Widget _control(
    String label,
    String? asset,
    VoidCallback? onTap, {
    bool active = false,
    IconData? icon,
    bool loading = false,
  }) => Material(
    color: active ? AppColors.accent : Colors.white,
    elevation: 5,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(18),
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.discovery,
              ),
            )
          : asset == null
          ? Icon(icon, size: 22, color: AppColors.textPrimary)
          : AppIcon(asset, color: AppColors.textPrimary),
    ),
  );

  Widget _bottomPanel(
    TourismMapController controller,
    List<MapMarkerModel> places,
    MapMarkerModel? selected,
  ) {
    if (selected != null) {
      return MapPlaceCard(
        key: ValueKey(selected.destinationId),
        place: selected,
        distanceMeters: _location.distance(
          selected.latitude,
          selected.longitude,
        ),
        locationBusy: _location.busy,
        isPinned: selected.destinationId == _pinnedDestinationId,
        onTogglePin: () {
          final nextPinned = (_pinnedDestinationId == selected.destinationId)
              ? null
              : selected.destinationId;
          setState(() {
            _pinnedDestinationId = nextPinned;
          });
          try {
            final visitCtrl = Provider.of<VisitController?>(
              context,
              listen: false,
            );
            if (visitCtrl != null) {
              if (nextPinned != null) {
                visitCtrl.setPendingDestination(
                  PendingSealDestination(
                    destinationId: selected.destinationId,
                    destinationName: selected.destination,
                    latitude: selected.latitude,
                    longitude: selected.longitude,
                    region: selected.region,
                    geofenceRadiusMeters: selected.geofenceRadiusMeters,
                    minDwellMinutes: selected.minDwellMinutes,
                  ),
                );
              } else {
                visitCtrl.clearPendingDestination();
              }
            }
          } catch (_) {}
        },
        onLocate: () => _locate(center: false),
        onGoogleMaps: () => _googleMaps(selected),
        onOpen: () => _open(selected),
        onClose: _focused ? null : () => setState(() => _selectedId = null),
      );
    }
    final failed = controller.errorMessage != null;
    final empty = places.isEmpty && !controller.isLoading;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 6,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const AppIcon(
                  AppIcons.compass,
                  size: 25,
                  color: AppColors.discovery,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.isLoading
                        ? 'Preparando tu mapa…'
                        : failed
                        ? 'Volvamos a intentarlo'
                        : empty
                        ? _focused
                              ? 'Ubicación no disponible'
                              : 'Probemos otra búsqueda'
                        : '${places.length} lugares, muchas historias',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!empty && !failed && !controller.isLoading)
                  IconButton(
                    tooltip: 'Ver lista de destinos',
                    onPressed: () => _listPlaces(places),
                    icon: const AppIcon(
                      AppIcons.chevronRight,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              failed
                  ? controller.errorMessage!
                  : empty
                  ? _focused
                        ? 'Este destino aún no tiene coordenadas publicadas.'
                        : 'Cambia el nombre o elige otra categoría.'
                  : controller.detailsUnavailable
                  ? 'Las ubicaciones están listas. No pudimos cargar las fotos y descripciones.'
                  : 'Toca una foto para descubrir el lugar. Amplía los grupos para ver cada destino.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (failed || controller.detailsUnavailable || (_focused && empty))
              TextButton(
                onPressed: () => _load(refresh: true),
                child: const Text('Reintentar'),
              ),
            if (empty && !_focused && !failed)
              TextButton(
                onPressed: () {
                  setState(() {
                    _search.clear();
                    _category = null;
                    _selectedId = null;
                    _showSearchResults = false;
                  });
                  _fitPlaces(controller.markers);
                },
                child: const Text('Ver todos los destinos'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pinnedBanner(MapMarkerModel pinnedPlace) {
    final distanceMeters = _location.distance(
      pinnedPlace.latitude,
      pinnedPlace.longitude,
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () {
          _fly(LatLng(pinnedPlace.latitude, pinnedPlace.longitude), 14);
          _select(pinnedPlace);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.push_pin_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            pinnedPlace.destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Fijado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      distanceMeters != null
                          ? '${mapDistanceLabel(distanceMeters)} en línea recta'
                          : 'Toca para enfocar en mapa',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Builder(
                builder: (context) {
                  VisitController? visitCtrl;
                  try {
                    visitCtrl = context.watch<VisitController>();
                  } catch (_) {
                    visitCtrl = null;
                  }
                  if (visitCtrl == null) return const SizedBox.shrink();
                  final ctrl = visitCtrl;

                  final active = ctrl.activeVisit;
                  final isVisitingThis =
                      active != null &&
                      active.destinationId == pinnedPlace.destinationId &&
                      active.isInProgress;

                  if (isVisitingThis) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.water_drop_rounded,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${active.remainingMinutes} min',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final isInside =
                      distanceMeters != null &&
                      distanceMeters <= pinnedPlace.geofenceRadiusMeters;
                  if (isInside) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isActionLoading
                            ? null
                            : () async {
                                await _location.locate(requestPermission: true);
                                final position = _location.position;
                                if (position == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _location.error ??
                                              'Activa tu ubicación para iniciar la visita.',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                final ok = await ctrl.startCheckIn(
                                  destinationId: pinnedPlace.destinationId,
                                  latitude: position.latitude,
                                  longitude: position.longitude,
                                );
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '📍 ¡Check-in iniciado en ${pinnedPlace.destination}! Cargando en tu Atlas.',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ctrl.error ??
                                            'No pudimos iniciar la visita.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.location_on_rounded, size: 14),
                        label: const Text(
                          'Check-in',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              IconButton(
                tooltip: 'Desfijar destino',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _pinnedDestinationId = null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
