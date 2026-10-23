import 'dart:async';
import 'package:flutter/material.dart';
import '../integration/services/notification_service.dart';
import '../models/notification_model.dart';

/// Estado del centro de notificaciones: lista, punto de no leídos y sondeo periódico.
class NotificationsController extends ChangeNotifier {
  final NotificationService _service;
  NotificationsController(this._service);

  List<AppNotification> items = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;

  Timer? _poll;
  static const Duration _pollEvery = Duration(seconds: 90);

  bool get hasUnread => unreadCount > 0;

  /// Carga la lista completa (pantalla de notificaciones, pull-to-refresh).
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final feed = await _service.getFeed();
      items = feed.items;
      unreadCount = feed.unreadCount;
    } catch (e) {
      error = 'No pudimos cargar tus notificaciones. Verifica tu conexión e intenta de nuevo.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Actualiza solo el número (punto de la campana).
  Future<void> refreshCount() async {
    final count = await _service.getUnreadCount();
    if (count != null && count != unreadCount) {
      unreadCount = count;
      notifyListeners();
    }
  }

  /// Revisa novedades cada 90 s mientras la app está abierta en el Home.
  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollEvery, (_) => refreshCount());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// Marca una como leída al instante (optimista) y avisa al backend.
  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    final before = items;
    final beforeCount = unreadCount;
    items = [for (final i in items) i.id == n.id ? i.copyWith(isRead: true) : i];
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
    try {
      await _service.markRead(n.id);
    } catch (_) {
      items = before;
      unreadCount = beforeCount;
      error = 'No pudimos marcar el aviso como leído. Intenta de nuevo.';
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0 && items.every((i) => i.isRead)) return;
    final before = items;
    final beforeCount = unreadCount;
    items = [for (final i in items) i.copyWith(isRead: true)];
    unreadCount = 0;
    notifyListeners();
    try {
      await _service.markAllRead();
    } catch (e) {
      // Si falla, se restaura lo que había.
      items = before;
      unreadCount = beforeCount;
      notifyListeners();
    }
  }

  /// Limpia todo el estado en memoria. Llamar al logout/cambio de usuario.
  void clearState() {
    stopPolling();
    items = [];
    unreadCount = 0;
    error = null;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
