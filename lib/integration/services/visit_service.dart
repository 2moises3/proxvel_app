import '../../models/visit_model.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class VisitService {
  final ApiClient _apiClient;

  VisitService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Registra el inicio o retoma de visita con coordenadas GPS
  Future<VisitModel> checkIn({
    required String destinationId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.visits}/check-in',
        {
          'destination_id': destinationId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response['success'] == true && response['data'] != null) {
        return VisitModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'No se pudo iniciar el check-in');
    } catch (e) {
      throw Exception('Error al registrar check-in: $e');
    }
  }

  /// Sella la visita tras cumplir el tiempo mínimo de permanencia
  Future<VisitModel> verifyVisit({
    required String visitId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.visits}/verify',
        {
          'visit_id': visitId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response['success'] == true && response['data'] != null) {
        return VisitModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'No se pudo verificar la visita');
    } catch (e) {
      throw Exception('Error al certificar visita: $e');
    }
  }

  /// Consulta la visita actualmente activa en curso si existe
  Future<VisitModel?> getActiveVisit() async {
    try {
      final response = await _apiClient.get('${ApiConfig.visits}/active');
      if (response['success'] == true && response['data'] != null) {
        return VisitModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el Atlas de Visitas completo del usuario
  Future<AtlasSummaryModel> getAtlas() async {
    try {
      final response = await _apiClient.get('${ApiConfig.visits}/atlas');
      if (response['success'] == true && response['data'] != null) {
        return AtlasSummaryModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      return AtlasSummaryModel(totalVerifiedVisits: 0, regionsVisited: 0, visits: []);
    } catch (e) {
      throw Exception('Error al cargar Atlas de visitas: $e');
    }
  }
}
