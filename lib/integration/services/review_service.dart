import 'package:flutter/foundation.dart';
import '../../models/review_model.dart';
import '../api/api_client.dart';

class ReviewService {
  final ApiClient? _api;

  ReviewService({ApiClient? apiClient}) : _api = apiClient;

  /// Reporta una reseña (ofensiva, falsa, spam, datos personales u otro).
  Future<void> reportReview(String reviewId, String reason) async {
    final api = _api;
    if (api == null) throw Exception('Servicio no disponible.');
    await api.post('/reviews/$reviewId/report', {'reason': reason});
  }

  Future<List<ReviewModel>> getReviewsForDestination(String destinationId) async {
    if (_api == null) return [];

    try {
      final response = await _api.get('/reviews/destination/$destinationId');
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[ReviewService] Error obteniendo reseñas para $destinationId: $e');
      throw Exception('No se pudieron cargar las opiniones.');
    }
  }

  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    if (_api == null) return [];

    try {
      final response = await _api.get('/reviews/user/$userId');
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[ReviewService] Error obteniendo reseñas del usuario $userId: $e');
      throw Exception('No se pudieron cargar tus reseñas. Inténtalo nuevamente.');
    }
  }
}
