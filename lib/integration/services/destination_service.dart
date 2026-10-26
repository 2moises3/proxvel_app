import '../../models/explanation_model.dart';
import 'package:flutter/foundation.dart';
import '../../models/destination_model.dart';
import '../../models/aspect_score_model.dart';
import '../../models/seasonality_model.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock/mock_destination_data_source.dart';
import '../mock/mock_aspect_data_source.dart';
import '../local/local_storage_service.dart';

/// Resultado del motor de recomendación para un destino.
class RankingInfo {
  final int percent;
  final double score;
  final double? climateScore;
  final double? crowdScore;
  final String? monthName;
  final int? rank;
  final ExplanationModel? explanation;
  final String?
  label; // 'Recomendado', 'Parcialmente recomendado', 'No recomendado'
  final List<String> topAspects;
  const RankingInfo({
    required this.percent,
    this.score = 0,
    this.climateScore,
    this.crowdScore,
    this.monthName,
    this.rank,
    this.explanation,
    this.label,
    this.topAspects = const [],
  });
}

/// Catálogo y medios desde PostgreSQL; ranking y explicación del usuario desde
/// el motor V3 autenticado. Los datos científicos pertenecen al snapshot validado.
class DestinationService {
  final ApiClient? _api;
  final LocalStorageService? storage;
  DestinationService({ApiClient? apiClient, this.storage}) : _api = apiClient;

  /// Etiquetas en español para los aspectos ABSA del backend.
  static const Map<String, String> _aspectLabels = {
    'atractivos': 'Atractivos turísticos',
    'costos': 'Valoración de precios',
    'seguridad': 'Seguridad',
    'accesibilidad': 'Accesibilidad',
    'limpieza': 'Limpieza',
    'atencion_servicio': 'Atención y servicio',
    'gastronomia': 'Gastronomía',
    'alojamiento': 'Alojamiento',
    'clima': 'Clima',
    'aforo_multitudes': 'Aforo / multitudes',
  };

  // Caches en memoria para evitar llamadas duplicadas por pantalla.
  // Detalle público por destino/mes; ranking privado por usuario, perfil y mes.
  final Map<String, Map<String, dynamic>> _detailCache = {};
  final Map<String, Map<String, Map<String, dynamic>>> _rankingByMonth = {};
  final Map<String, Future<void>> _rankingLoads = {};
  List<DestinationModel>? _catalogCache;
  Future<List<DestinationModel>>? _catalogLoad;
  int _catalogGeneration = 0;
  Map<String, String>? _tourismSearchIndex;

  /// El gesto de actualizar Inicio vuelve a consultar el catálogo público.
  void invalidateDestinationCatalog() {
    _catalogGeneration++;
    _catalogCache = null;
    _catalogLoad = null;
  }

  void clearPersonalizedCache() {
    _rankingByMonth.clear();
    _rankingLoads.clear();
  }

  /// Texto oficial del catálogo para encontrar actividades y descripciones.
  /// La lista general de destinos no contiene estos campos.
  Future<Map<String, String>> getTourismSearchIndex() async {
    if (_tourismSearchIndex != null) return _tourismSearchIndex!;
    if (_api == null) return {};
    final json = await _api.get('/tourism/catalog');
    final items = json['data'] as List? ?? const [];
    final index = <String, String>{};
    for (final item in items.whereType<Map<String, dynamic>>()) {
      final id = item['destination_id'] as String?;
      if (id == null || id.isEmpty) continue;
      index[id] = [
        item['description'],
        item['activities_summary'],
        item['visitor_info_summary'],
      ].whereType<String>().join(' ');
    }
    _tourismSearchIndex = index;
    return index;
  }

  Future<List<DestinationModel>> getDestinations() async {
    if (_catalogCache != null) return _catalogCache!;
    if (_catalogLoad != null) return _catalogLoad!;
    final generation = _catalogGeneration;
    final loading = _fetchDestinations();
    _catalogLoad = loading;
    try {
      final result = await loading;
      if (generation == _catalogGeneration && result.isNotEmpty) {
        _catalogCache = result;
      }
      return result;
    } finally {
      if (generation == _catalogGeneration) _catalogLoad = null;
    }
  }

  Future<List<DestinationModel>> _fetchDestinations() async {
    if (_api != null) {
      try {
        final json = await _api.get('/destinations');
        final items = json['data'] as List? ?? [];

        final parsedList = items
            .whereType<Map<String, dynamic>>()
            .map((item) => DestinationModel.fromApiCatalog(item))
            .toList();

        if (parsedList.isNotEmpty) {
          return parsedList;
        }
      } catch (e) {
        debugPrint(
          '[DestinationService] Falló getDestinations API, usando fallback: $e',
        );
        if (!ApiConfig.useMockFallback) rethrow;
      }
    }

    if (ApiConfig.useMockFallback) {
      debugPrint(
        '[DestinationService] Backend no disponible, usando MockDestinationDataSource como fallback.',
      );
      return MockDestinationDataSource.activeDestinations;
    }
    return [];
  }

  Future<List<DestinationModel>> getRecentSearches() async {
    if (ApiConfig.useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockDestinationDataSource.recentSearches;
    }
    return [];
  }

  /// Detalle de un destino. API-first (slug del backend), fallback mock.
  Future<DestinationModel?> getDestinationById(String id, {int? month}) async {
    try {
      final detail = await _fetchDetail(id, month: month);
      if (detail != null) {
        final dest = DestinationModel.fromApiDetail(detail);
        return dest;
      }
    } catch (e) {
      if (!ApiConfig.useMockFallback) rethrow;
    }

    if (ApiConfig.useMockFallback) {
      // Fallback: buscar en mocks por id (slug)
      try {
        return MockDestinationDataSource.destinations.firstWhere(
          (d) => d.id == id,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Scores ABSA por aspecto (matriz normalizada de la Fase 2 / notebooks).
  Future<List<AspectScoreModel>> getAspectScores(
    String destinationId, {
    int? month,
  }) async {
    try {
      final detail = await _fetchDetail(destinationId, month: month);
      final aspectMap = detail?['aspect_scores'] as Map<String, dynamic>?;
      if (aspectMap != null) {
        final scores = <AspectScoreModel>[];
        _aspectLabels.forEach((key, label) {
          // clima y aforo_multitudes NO son aspectos ABSA de reseñas: son señales
          // contextuales (Fase 4, datos reales del mes). Se excluyen de la lista
          // ABSA y se muestran aparte vía getDestinationContext().
          if (!const [
            'costos',
            'atencion_servicio',
            'atractivos',
          ].contains(key)) {
            return;
          }
          final value = aspectMap[key];
          if (value is num) {
            scores.add(
              AspectScoreModel(aspect: label, score: value.toDouble()),
            );
          }
        });
        if (scores.isNotEmpty) return scores;
      }
    } catch (e) {
      if (!ApiConfig.useMockFallback) rethrow;
    }

    if (ApiConfig.useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 300));
      return MockAspectDataSource.getAspectScores(destinationId);
    }
    return [];
  }

  /// Explicación del ranking contextual (explicacion_final de la Fase 4).
  Future<String> getExplanation(String destinationId, {int? month}) async {
    try {
      final entry = await _rankingEntry(destinationId, month: month);
      // El motor V1 manda explanation.summary; se usa eso (con respaldos).
      final exp = entry?['explanation'];
      if (exp is Map &&
          exp['summary'] is String &&
          (exp['summary'] as String).isNotEmpty) {
        return exp['summary'] as String;
      }
      final short = entry?['short_explanation'];
      if (short is String && short.isNotEmpty) return short;
    } catch (e) {
      if (!ApiConfig.useMockFallback) rethrow;
    }

    if (ApiConfig.useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockAspectDataSource.getExplanation(destinationId);
    }
    return 'Aún no hay explicación personalizada disponible para este destino.';
  }

  /// Lo que el motor dice de este destino para el usuario, o null si el destino
  /// no está entre sus recomendaciones (fuera del motor, sin perfil, sin conexión).
  /// Los fallos de carga se propagan: el detalle puede aislarlos y la búsqueda los informa.
  Future<RankingInfo?> getRankingInfo(
    String destinationId, {
    int? month,
  }) async {
    try {
      final entry = await _rankingEntry(destinationId, month: month);
      if (entry == null) return null;
      final compat =
          entry['compatibility_percent'] ?? entry['compatibility_percentage'];
      if (compat is! num) return null;
      final label = entry['label'];
      return RankingInfo(
        percent: compat.round(),
        score: (entry['compatibility_score'] as num?)?.toDouble() ?? 0,
        climateScore: (entry['climate_score'] as num?)?.toDouble(),
        crowdScore: (entry['crowd_score'] as num?)?.toDouble(),
        monthName: entry['month_name'] as String?,
        rank: entry['ranking_position'] as int?,
        explanation: entry['explanation'] is Map<String, dynamic>
            ? ExplanationModel.fromJson(entry['explanation'])
            : null,
        label: (label is String && label.isNotEmpty) ? label : null,
        topAspects: [
          for (final item
              in ((entry['explanation'] as Map?)?['top_aspects'] as List? ??
                  const []))
            if (item is Map && item['aspect'] is String)
              _aspectLabels[item['aspect']] ?? item['aspect'] as String,
        ],
      );
    } catch (e) {
      debugPrint(
        '[DestinationService] Sin recomendación para $destinationId: $e',
      );
      rethrow;
    }
  }

  final Map<int, Map<String, MonthContext>> _monthContextCache = {};

  /// Clima y afluencia de todos los destinos en un mes (filtros del buscador).
  Future<Map<String, MonthContext>> getMonthContext(int month) async {
    final cached = _monthContextCache[month];
    if (cached != null) return cached;
    if (_api == null) return {};
    final json = await _api.get(
      '/destinations/month-context',
      queryParams: {'month': '$month'},
    );
    final items = json['data'] as List? ?? [];
    final map = {
      for (final item in items.whereType<Map<String, dynamic>>())
        (item['destination_id'] ?? '') as String: MonthContext.fromJson(item),
    };
    _monthContextCache[month] = map;
    return map;
  }

  /// Calendario de 12 meses de un destino con clima y aforo según el perfil del usuario.
  /// Devuelve null si no hay datos; los fallos de conexión se muestran en la vista.
  Future<DestinationCalendar?> getCalendar(
    String destinationId, {
    String? clima,
    String? tolerancia,
  }) async {
    if (_api == null) return null;
    final json = await _api.get(
      '/destinations/$destinationId/calendar',
      queryParams: {
        if (clima != null && clima.isNotEmpty) 'clima': clima,
        if (tolerancia != null && tolerancia.isNotEmpty)
          'tolerancia': tolerancia,
      },
    );
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    final calendar = DestinationCalendar.fromJson(data);
    return calendar.hasAnyData ? calendar : null;
  }

  /// Afinidad relativa de Fase 3; no es el puntaje contextual ni una probabilidad.
  Future<int> getCompatibility(String destinationId, {int? month}) async {
    try {
      final entry = await _rankingEntry(destinationId, month: month);
      // El motor V1 manda compatibility_percent (con respaldo al nombre largo).
      final compat =
          entry?['compatibility_percent'] ?? entry?['compatibility_percentage'];
      if (compat is num) return compat.round();
    } catch (e) {
      if (!ApiConfig.useMockFallback) rethrow;
    }

    if (ApiConfig.useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 100));
      return MockAspectDataSource.getCompatibility(destinationId);
    }
    return 0;
  }

  /// Contexto REAL del mes (clima + aforo), NO de reseñas. Viene de
  /// GET /destinations/{id}?month= en `context` / `weather_detail`.
  /// Devuelve scores 0-1 (alto = mejor) y etiquetas legibles.
  Future<Map<String, dynamic>> getDestinationContext(
    String destinationId, {
    int? month,
  }) async {
    try {
      final detail = await _fetchDetail(destinationId, month: month);
      final ctx = detail?['context'] as Map<String, dynamic>?;
      final wd = detail?['weather_detail'] as Map<String, dynamic>?;
      if (ctx != null) {
        return {
          'clima_score': (ctx['weather_score'] as num?)?.toDouble(),
          'clima_label': ctx['weather_category'] as String?,
          'aforo_score': (ctx['crowd_score'] as num?)?.toDouble(),
          'aforo_label': ctx['crowd_level'] as String?,
          'month_name': wd?['month_name'] as String?,
        };
      }
    } catch (e) {
      if (!ApiConfig.useMockFallback) rethrow;
    }
    return {};
  }

  // ── Internos ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchDetail(
    String destinationId, {
    int? month,
  }) async {
    if (_api == null) return null;
    final mes = month ?? DateTime.now().month;
    final cacheKey = '$destinationId|$mes';
    if (_detailCache.containsKey(cacheKey)) {
      return _detailCache[cacheKey];
    }
    final json = await _api.get(
      '/destinations/$destinationId',
      queryParams: {'month': '$mes'},
    );
    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      _detailCache[cacheKey] = data;
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _rankingEntry(
    String destinationId, {
    int? month,
  }) async {
    if (_api == null) return null;
    final mes =
        month ?? DateTime.now().month; // 0 = mes actual (lo decide el backend)
    final userId = storage?.getUser()?.id ?? 'no-user';
    final profileKey =
        storage?.getProfile()?.toApiJson().toString() ?? 'no-profile';
    final cacheKey = 'tesis-v3-20261022|$userId|$profileKey|$mes';
    if (!_rankingByMonth.containsKey(cacheKey)) {
      final load = _rankingLoads.putIfAbsent(cacheKey, () async {
        final json = await _api.get(
          '/recommendations/me',
          queryParams: {'limit': '100', 'month': '$mes'},
        );
        final items = json['data'] as List? ?? [];
        _rankingByMonth[cacheKey] = {
          for (final item in items.whereType<Map<String, dynamic>>())
            (item['destination_id'] ?? '') as String: item,
        };
      });
      try {
        await load;
      } finally {
        _rankingLoads.remove(cacheKey);
      }
    }
    return _rankingByMonth[cacheKey]?[destinationId];
  }
}
