import 'package:flutter/material.dart';
import '../integration/local/announcement_seen_store.dart';
import '../integration/services/announcement_service.dart';
import '../models/announcement_model.dart';

/// Controla los anuncios internos visibles en la app.
///
/// - Cada ubicación (y destino, en el detalle) se carga y cachea por separado.
/// - Los banners cerrados y los avisos confirmados se recuerdan en el teléfono.
/// - El anuncio de inicio respeta su límite de veces (frequency_cap) por dispositivo.
/// - Vistas, clics y cierres se reportan al backend para las métricas del dashboard.
class AnnouncementController extends ChangeNotifier {
  final AnnouncementService _service;
  final AnnouncementSeenStore _store;
  AnnouncementController(this._service, {AnnouncementSeenStore? store})
      : _store = store ?? AnnouncementSeenStore();

  final Map<String, List<AnnouncementModel>> _byKey = {};
  final Set<String> _loadedKeys = <String>{};

  /// Vistas ya contadas en esta sesión (un carrusel no suma una vista en cada vuelta).
  final Set<int> _viewedThisSession = <int>{};
  bool _startShownThisSession = false;

  static String _key(String placement, String? destinationId) =>
      destinationId == null ? placement : '$placement|$destinationId';

  /// Anuncios visibles (no cerrados) de una ubicación, en orden de prioridad.
  List<AnnouncementModel> visibleFor(String placement, {String? destinationId}) {
    return (_byKey[_key(placement, destinationId)] ?? const <AnnouncementModel>[])
        .where((a) => !_store.isClosed(a.id))
        .toList(growable: false);
  }

  /// Compatibilidad: primer anuncio visible de una ubicación.
  AnnouncementModel? currentFor(String placement) {
    final list = visibleFor(placement);
    return list.isEmpty ? null : list.first;
  }

  Future<void> load({String placement = 'home_top', String? destinationId}) async {
    final key = _key(placement, destinationId);
    // Evita recargas innecesarias en cada rebuild.
    if (_loadedKeys.contains(key)) return;
    _loadedKeys.add(key);
    await _store.load();
    _byKey[key] = await _service.getActive(placement: placement, destinationId: destinationId);
    notifyListeners();
  }

  /// Fuerza una recarga (p. ej. pull-to-refresh).
  Future<void> refresh({String placement = 'home_top', String? destinationId}) async {
    _loadedKeys.remove(_key(placement, destinationId));
    await load(placement: placement, destinationId: destinationId);
  }

  /// Ventana a mostrar al abrir la app (una por sesión): primero un aviso importante
  /// no confirmado; si no hay, el anuncio de inicio que no haya llegado a su límite.
  Future<AnnouncementModel?> pickStartAnnouncement() async {
    if (_startShownThisSession) return null;
    await Future.wait([
      load(placement: 'global_modal'),
      load(placement: 'app_start'),
    ]);
    final important = visibleFor('global_modal');
    final promos = visibleFor('app_start').where((a) {
      final cap = a.frequencyCap ?? 0;
      return cap <= 0 || _store.viewsOf(a.id) < cap;
    });
    final pick = important.isNotEmpty ? important.first : (promos.isEmpty ? null : promos.first);
    if (pick != null) _startShownThisSession = true;
    return pick;
  }

  /// Registra que el anuncio se mostró (una vez por sesión).
  void markViewed(AnnouncementModel a) {
    if (!_viewedThisSession.add(a.id)) return;
    _store.addView(a.id);
    _service.reportEvent(a.id, 'impression');
  }

  /// El viajero tocó el botón del anuncio.
  void markClicked(AnnouncementModel a) {
    _service.reportEvent(a.id, 'click');
    // Un aviso importante se da por confirmado al usar su botón.
    if (a.placement == 'global_modal') _store.close(a.id);
  }

  /// El viajero cerró el anuncio.
  /// - Banner (Explorar / detalle) o aviso importante: no vuelve a aparecer.
  /// - Anuncio de inicio: se cierra ahora; su límite de veces decide si vuelve.
  void dismiss(AnnouncementModel a) {
    _service.reportEvent(a.id, 'dismiss');
    if (a.placement != 'app_start') _store.close(a.id);
    notifyListeners();
  }
}
