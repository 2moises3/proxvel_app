import '../integration/api/api_client.dart';
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
  int _mutationRevision = 0;
  final _pendingIds = <String>{};
  List<DestinationModel> favorites = [];
  Set<String> favoriteDestinationIds = {};
  String? error;
  bool connectionUnavailable = false;

  FavoritesController(this._favoritesService);

  Future<void> ensureFavoritesLoaded() =>
      hasLoaded ? Future.value() : loadFavorites();

  Future<void> loadFavorites() =>
      _pendingLoad ??= _loadFavorites(_sessionGeneration);

  Future<void> _loadFavorites(int generation) async {
    final revision = _mutationRevision;
    isLoading = true;
    error = null;
    connectionUnavailable = false;
    notifyListeners();

    try {
      final favModels = await _favoritesService.getFavorites();
      if (generation != _sessionGeneration ||
          revision != _mutationRevision ||
          _pendingIds.isNotEmpty) {
        return;
      }
      favorites = favModels
          .map((f) => DestinationModel.fromFavoriteModel(f))
          .toList();
      favoriteDestinationIds = favorites.map((d) => d.id).toSet();
      hasLoaded = true;
    } catch (e) {
      if (generation != _sessionGeneration) return;
      connectionUnavailable = e is ApiException && e.statusCode == 0;
      error = 'No pudimos cargar tus favoritos. Intenta nuevamente.';
    } finally {
      if (generation == _sessionGeneration) {
        _pendingLoad = null;
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Marca/desmarca un favorito. Optimista en UI, persiste en backend.
  bool isSaving(String id) => _pendingIds.contains(id);

  Future<bool?> toggleFavorite(String id, [DestinationModel? model]) async {
    if (!_pendingIds.add(id)) return null;
    final generation = _sessionGeneration;
    _mutationRevision++;
    final isFav = isFavorite(id);
    final previousIndex = favorites.indexWhere((d) => d.id == id);
    final previous = previousIndex < 0 ? model : favorites[previousIndex];
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
      final saved = isFav
          ? await _favoritesService.removeFavorite(id)
          : await _favoritesService.addFavorite(id);
      if (!saved) throw StateError('Favorite update rejected');
      return generation == _sessionGeneration ? true : null;
    } catch (_) {
      if (generation != _sessionGeneration) return null;
      // Revertir cambio optimista
      if (isFav) {
        favoriteDestinationIds.add(id);
        if (previous != null && !favorites.any((d) => d.id == id)) {
          favorites.insert(previousIndex.clamp(0, favorites.length), previous);
        }
      } else {
        favoriteDestinationIds.remove(id);
        favorites.removeWhere((d) => d.id == id);
      }
      return false;
    } finally {
      if (generation == _sessionGeneration) {
        _pendingIds.remove(id);
        notifyListeners();
      }
    }
  }

  bool isFavorite(String id) => favoriteDestinationIds.contains(id);

  /// Limpia todo el estado en memoria. Llamar al logout/cambio de usuario.
  void clearState() {
    _sessionGeneration++;
    _pendingIds.clear();
    _pendingLoad = null;
    hasLoaded = false;
    favorites = [];
    favoriteDestinationIds = {};
    error = null;
    connectionUnavailable = false;
    isLoading = false;
    notifyListeners();
  }
}
