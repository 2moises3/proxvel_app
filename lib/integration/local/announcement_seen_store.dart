import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en el teléfono qué anuncios ya vio o cerró el viajero, para respetar
/// el límite de veces (como Firebase In-App Messaging: por dispositivo).
class AnnouncementSeenStore {
  static const _key = 'announcements_seen_v1';

  /// id → veces mostrado
  final Map<int, int> _views = {};

  /// Anuncios cerrados (banners) o confirmados (avisos importantes).
  final Set<int> _closed = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      (data['views'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is num) _views[id] = v.toInt();
      });
      for (final v in (data['closed'] as List? ?? const [])) {
        if (v is num) _closed.add(v.toInt());
      }
    } catch (e) {
      debugPrint('[AnnouncementSeenStore] no se pudo leer: $e');
    }
  }

  int viewsOf(int id) => _views[id] ?? 0;
  bool isClosed(int id) => _closed.contains(id);

  Future<void> addView(int id) async {
    _views[id] = viewsOf(id) + 1;
    await _save();
  }

  Future<void> close(int id) async {
    if (_closed.add(id)) await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'views': _views.map((k, v) => MapEntry('$k', v)),
          'closed': _closed.toList(),
        }),
      );
    } catch (e) {
      debugPrint('[AnnouncementSeenStore] no se pudo guardar: $e');
    }
  }
}
