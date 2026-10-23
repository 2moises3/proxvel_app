import 'package:flutter/foundation.dart';
import '../../models/announcement_model.dart';
import '../api/api_client.dart';

/// Servicio de anuncios internos.
/// Consume GET /announcements/active y reporta vistas/clics/cierres.
/// Nunca usa mock: si el backend falla devuelve lista vacía (no crashea).
class AnnouncementService {
  final ApiClient? _api;
  AnnouncementService({ApiClient? apiClient}) : _api = apiClient;

  /// Obtiene anuncios activos para una ubicación (placement) dada.
  /// El backend ya filtra por activos, rango de fechas y ordena por prioridad.
  Future<List<AnnouncementModel>> getActive({
    String placement = 'home_top',
    String? destinationId,
  }) async {
    final api = _api;
    if (api == null) return const [];
    try {
      final json = await api.get(
        '/announcements/active',
        queryParams: {
          'placement': placement,
          'destination_id': ?destinationId,
        },
      );
      final items = json['data'] as List? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementModel.fromApiJson)
          .where((a) => a.hasContent)
          .toList();
    } catch (e) {
      // Falla suave: la app no debe romperse por un anuncio.
      debugPrint('[AnnouncementService] getActive falló (placement=$placement): $e');
      return const [];
    }
  }

  /// Reporta 'impression' | 'click' | 'dismiss'. No bloquea ni lanza errores.
  Future<void> reportEvent(int announcementId, String event) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.post('/announcements/$announcementId/events', {'event': event});
    } catch (e) {
      debugPrint('[AnnouncementService] reportEvent($event) falló: $e');
    }
  }
}
