import '../../models/favorite_model.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class FavoritesService {
  final ApiClient _apiClient;

  FavoritesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final response = await _apiClient.get(ApiConfig.favorites);
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => FavoriteModel.fromJson(json)).toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error al cargar favoritos: $e');
    }
  }

  Future<bool> addFavorite(String destinationId) async {
    try {
      final response = await _apiClient.post('${ApiConfig.favorites}/$destinationId');
      if (response['success'] == true) {
        return response['data']['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error al agregar favorito: $e');
    }
  }

  Future<bool> removeFavorite(String destinationId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.favorites}/$destinationId');
      if (response['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Error al eliminar favorito: $e');
    }
  }

  Future<bool> checkFavorite(String destinationId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.favorites}/check/$destinationId');
      if (response['success'] == true) {
        return response['data']['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
