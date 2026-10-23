import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_marker_model.dart';
import '../integration/services/tourism_map_service.dart';

class TourismMapController extends ChangeNotifier {
  final TourismMapService _mapService;

  TourismMapController(this._mapService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MapMarkerModel> _markers = [];
  List<MapMarkerModel> get markers => _markers;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  MapMarkerModel? _selectedMarker;
  MapMarkerModel? get selectedMarker => _selectedMarker;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  double? _distanceKm;
  double? get distanceKm => _distanceKm;

  List<String> get availableCategories {
    final categories = _markers.map((m) => m.category).whereType<String>().toSet().toList();
    categories.sort();
    return categories;
  }

  List<MapMarkerModel> get filteredMarkers {
    if (_selectedCategory == null) {
      return _markers;
    }
    return _markers.where((m) => m.category == _selectedCategory).toList();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadMarkers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _markers = await _mapService.getMapMarkers();
    } catch (e) {
      _errorMessage = 'No pudimos cargar el mapa. Intenta de nuevo.';
      _markers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// true si el viajero prefirió no compartir su ubicación: no se calcula la distancia.
  bool locationDeclined = false;

  /// [useLocation]=false selecciona el destino sin pedir permiso ni calcular distancia.
  Future<void> selectDestination(MapMarkerModel marker, {bool useLocation = true}) async {
    _selectedMarker = marker;
    _errorMessage = null;
    _userLocation = null;
    _distanceKm = null;
    locationDeclined = !useLocation;
    notifyListeners();
    if (!useLocation) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = "Los servicios de ubicación están deshabilitados.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = "Permiso de ubicación denegado.";
          notifyListeners();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = "Los permisos de ubicación están denegados permanentemente.";
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
          
      _userLocation = LatLng(position.latitude, position.longitude);
      
      const Distance distance = Distance();
      final double meter = distance(
          _userLocation!,
          LatLng(marker.latitude, marker.longitude)
      );
      _distanceKm = meter / 1000;
      
    } catch (e) {
      _errorMessage = 'No pudimos obtener tu ubicación. Puedes ver el destino sin compartirla.';
    }
    
    notifyListeners();
  }

  void clearSelection() {
    _selectedMarker = null;
    _userLocation = null;
    _distanceKm = null;
    locationDeclined = false;
    _errorMessage = null;
    notifyListeners();
  }
}
