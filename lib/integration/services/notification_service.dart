import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import '../api/api_client.dart';

/// Resultado de la lista de notificaciones.
class NotificationFeed {
  final List<AppNotification> items;
  final int unreadCount;
  const NotificationFeed(this.items, this.unreadCount);
}

/// Servicio del centro de notificaciones (campana del Home).
class NotificationService {
  final ApiClient? _api;
  NotificationService({ApiClient? apiClient}) : _api = apiClient;

  /// Lista unificada (anuncios + avisos personales) ordenada por llegada.
  /// Lanza si falla, para que la pantalla pueda mostrar el error y reintentar.
  Future<NotificationFeed> getFeed() async {
    final api = _api;
    if (api == null) return const NotificationFeed([], 0);
    final json = await api.get('/notifications', queryParams: {'limit': '50'});
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    return NotificationFeed(items, (data['unread_count'] as num?)?.toInt() ?? 0);
  }

  /// Solo el número para el punto de la campana. Falla suave (devuelve null).
  Future<int?> getUnreadCount() async {
    final api = _api;
    if (api == null) return null;
    try {
      final json = await api.get('/notifications/unread-count');
      return (json['data']?['unread_count'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[NotificationService] unread-count falló: $e');
      return null;
    }
  }

  Future<void> markRead(String id) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.post('/notifications/$id/read');
    } catch (e) {
      debugPrint('[NotificationService] markRead($id) falló: $e');
    }
  }

  Future<void> markAllRead() async {
    final api = _api;
    if (api == null) return;
    await api.post('/notifications/read-all');
  }
}
