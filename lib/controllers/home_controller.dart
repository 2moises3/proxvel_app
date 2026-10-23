import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../integration/services/destination_service.dart';
import '../integration/local/local_storage_service.dart';

/// Controla la pestaña Explorar (catálogo abierto).
/// Solo expone datos reales del backend. No fabrica "trending", "cerca de ti"
/// ni "escapadas" a partir de campos inexistentes.
class HomeController extends ChangeNotifier {
  final DestinationService _service;
  final LocalStorageService _storageService;

  bool isLoading = false;
  String? error;
  List<DestinationModel> destinations = [];
  List<DestinationModel> recentSearches = [];

  /// Permite solicitar a HomeScreen que cambie de pestaña (0: Explorar, 1: Para ti)
  int requestedTabIndex = -1;

  HomeController(this._service, this._storageService);

  void requestTabChange(int index) {
    requestedTabIndex = index;
    notifyListeners();
  }

  void resetTabRequest() {
    requestedTabIndex = -1;
  }

  /// Todos los destinos reales del catálogo.
  List<DestinationModel> get allDestinations => destinations;

  /// Destacados para el carrusel hero: los primeros del catálogo real.
  /// No se basa en banderas inventadas; resalta los primeros activos.
  List<DestinationModel> get featuredDestinations =>
      destinations.take(5).toList();

  /// Categorías reales presentes en el catálogo (para chips).
  List<String> get categories {
    final set = <String>{};
    for (final d in destinations) {
      if (d.category.trim().isNotEmpty) set.add(d.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> loadDestinations() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      destinations = await _service.getDestinations();

      // Cargar búsquedas recientes desde almacenamiento local.
      await _storageService.init();
      final recentNames = _storageService.getRecentSearches();
      final loadedRecents = <DestinationModel>[];
      for (final name in recentNames) {
        try {
          final match = destinations.firstWhere((d) => d.name == name);
          loadedRecents.add(match);
        } catch (_) {}
      }
      recentSearches = loadedRecents;
    } catch (e) {
      error = 'No pudimos cargar los destinos. Revisa tu conexión e intenta de nuevo.';
      destinations = [];
    }
    isLoading = false;
    notifyListeners();
  }
}
