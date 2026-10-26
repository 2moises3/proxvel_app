import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../integration/services/favorites_service.dart';

/// Favoritos BACKEND-ONLY: la fuente de verdad es PostgreSQL.
/// No se almacenan favoritos en SharedPreferences.
/// Si el backend falla, se muestra error/empty state, nunca datos locales.
class FavoritesController extends ChangeNotifier {
  final FavoritesService _favoritesService;

  bool isLoading = false;
  bool hasLoaded = false;
  Future<void>? _pendingLoad;
  int _sessionGeneration = 0;
  List<DestinationModel> favorites = [];
  Set<String> favoriteDestinationIds = {};
  String? error;

  FavoritesController(this._favoritesService);

  Future<void> ensureFavoritesLoaded() =>
      hasLoaded ? Future.value() : loadFavorites();

  Future<void> loadFavorites() =>
      _pendingLoad ??= _loadFavorites(_sessionGeneration);

  Future<void> _loadFavorites(int generation) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final favModels = await _favoritesService.getFavorites();
      if (generation != _sessionGeneration) return;
      favorites = favModels
          .map((f) => DestinationModel.fromFavoriteModel(f))
          .toList();
      favoriteDestinationIds = favorites.map((d) => d.id).toSet();
      hasLoaded = true;
    } catch (e) {
      if (generation != _sessionGeneration) return;
      error = 'No pudimos cargar tus favoritos. Intenta nuevamente.';
      favorites = [];
      favoriteDestinationIds = {};
    } finally {
      if (generation == _sessionGeneration) {
        _pendingLoad = null;
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Marca/desmarca un favorito. Optimista en UI, persiste en backend.
  Future<void> toggleFavorite(String id, [DestinationModel? model]) async {
    final isFav = isFavorite(id);
    if (isFav) {
      favoriteDestinationIds.remove(id);
      favorites.removeWhere((d) => d.id == id);
    } else {
      favoriteDestinationIds.add(id);
      if (model != null && !favorites.any((d) => d.id == id)) {
        favorites.add(model);
      }
    }
    notifyListeners();

    // Sincroniza con backend. Si falla, revertimos.
    try {
      if (isFav) {
        await _favoritesService.removeFavorite(id);
      } else {
        await _favoritesService.addFavorite(id);
      }
    } catch (_) {
      // Revertir cambio optimista
      if (isFav) {
        favoriteDestinationIds.add(id);
        if (model != null) favorites.add(model);
      } else {
        favoriteDestinationIds.remove(id);
        favorites.removeWhere((d) => d.id == id);
      }
      notifyListeners();
    }
  }

  bool isFavorite(String id) => favoriteDestinationIds.contains(id);

  /// Limpia todo el estado en memoria. Llamar al logout/cambio de usuario.
  void clearState() {
    _sessionGeneration++;
    _pendingLoad = null;
    hasLoaded = false;
    favorites = [];
    favoriteDestinationIds = {};
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
