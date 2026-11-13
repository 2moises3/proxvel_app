import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_marker_model.dart';
import '../integration/services/tourism_map_service.dart';

/// Controlador del mapa turístico de PROXVEL.
/// Gestiona la carga de marcadores en sesión, selección de destinos y cálculo de distancia GPS.
class TourismMapController extends ChangeNotifier {
  TourismMapController(this._mapService);

  final TourismMapService _mapService;

  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;
  bool get detailsUnavailable => _mapService.detailsUnavailable;

  List<MapMarkerModel> markers = [];
  Future<void>? _pending;
  String? _loadedLanguage;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  MapMarkerModel? _selectedMarker;
  MapMarkerModel? get selectedMarker => _selectedMarker;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  double? _distanceKm;
  double? get distanceKm => _distanceKm;

  /// true si el viajero prefirió no compartir su ubicación: no se calcula la distancia.
  bool locationDeclined = false;

  List<String> get availableCategories {
    final categories = markers
        .map((m) => m.category)
        .whereType<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<MapMarkerModel> get filteredMarkers {
    if (_selectedCategory == null) {
      return markers;
    }
    return markers.where((m) => m.category == _selectedCategory).toList();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadMarkers({bool refresh = false}) async {
    final pending = _pending;
    if (pending != null) {
      await pending;
      if (_loadedLanguage != _mapService.catalogLanguage &&
          errorMessage == null) {
        await loadMarkers();
      }
      return;
    }
    final language = _mapService.catalogLanguage;
    if (hasLoaded && !refresh && _loadedLanguage == language) return;
    _pending = _load(language).whenComplete(() => _pending = null);
    await _pending;
  }

  Future<void> _load(String language) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      markers = await _mapService.getMapMarkers();
      _loadedLanguage = language;
      hasLoaded = true;
    } catch (_) {
      errorMessage =
          'No pudimos cargar los destinos. Revisa tu conexión y vuelve a intentar.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// [useLocation]=false selecciona el destino sin pedir permiso ni calcular distancia.
  Future<void> selectDestination(
    MapMarkerModel marker, {
    bool useLocation = true,
  }) async {
    _selectedMarker = marker;
    errorMessage = null;
    _userLocation = null;
    _distanceKm = null;
    locationDeclined = !useLocation;
    notifyListeners();
    if (!useLocation) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = 'Los servicios de ubicación están deshabilitados.';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = 'Permiso de ubicación denegado.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            'Los permisos de ubicación están denegados permanentemente.';
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);

      const distance = Distance();
      final double meter = distance(
        _userLocation!,
        LatLng(marker.latitude, marker.longitude),
      );
      _distanceKm = meter / 1000;
    } catch (_) {
      errorMessage =
          'No pudimos obtener tu ubicación. Puedes ver el destino sin compartirla.';
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedMarker = null;
    _userLocation = null;
    _distanceKm = null;
    locationDeclined = false;
    errorMessage = null;
    notifyListeners();
  }
}
