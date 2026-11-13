import 'package:flutter/foundation.dart';
import '../../models/tourism_catalog_model.dart';
import '../api/api_client.dart';

class TourismService {
  final ApiClient? _api;
  final String Function()? languageCode;

  TourismService({ApiClient? apiClient, this.languageCode}) : _api = apiClient;

  Future<TourismCatalogModel?> getTourismCatalog(String destinationId) async {
    if (_api == null) return null;

    try {
      final language = languageCode?.call();
      final response = await _api.get(
        '/tourism/catalog/${Uri.encodeComponent(destinationId)}',
        queryParams: language == 'en' ? const {'lang': 'en'} : null,
      );
      final data = response['data'] as Map<String, dynamic>?;

      if (data != null) {
        return TourismCatalogModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint(
        '[TourismService] Error obteniendo catálogo para $destinationId: $e',
      );
      throw Exception('Información oficial no disponible.');
    }
  }
}
