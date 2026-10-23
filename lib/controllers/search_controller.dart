import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/seasonality_model.dart';
import '../integration/services/destination_service.dart';
import '../integration/local/local_storage_service.dart';

/// Texto comparable: minúsculas, sin tildes ni espacios extremos ("Líneas" == "lineas").
String normalizeForSearch(String text) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  final lower = text.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// Search filter criteria.
class SearchFilters {
  final String query;
  final String? region;
  final String? category;
  final int? minCompatibility;

  /// Clima favorable (>= 0.70 en la tesis) para esta preferencia: frio|templado|calido|seco.
  final String? climate;

  /// Afluencia del mes según la tesis: Bajo | Medio | Alto.
  final String? crowd;

  /// Mes (1-12) con el que se evalúan clima y afluencia. null = mes actual.
  final int? month;

  /// Nivel de costo estimado: bajo | medio | alto.
  final String? costLevel;

  const SearchFilters({
    this.query = '',
    this.region,
    this.category,
    this.minCompatibility,
    this.climate,
    this.crowd,
    this.month,
    this.costLevel,
  });

  bool get hasActiveFilters =>
      region != null ||
      category != null ||
      minCompatibility != null ||
      climate != null ||
      crowd != null ||
      costLevel != null;

  int get activeFilterCount {
    int count = 0;
    if (region != null) count++;
    if (category != null) count++;
    if (minCompatibility != null) count++;
    if (climate != null) count++;
    if (crowd != null) count++;
    if (costLevel != null) count++;
    return count;
  }

  SearchFilters copyWith({
    String? query,
    String? region,
    String? category,
    int? minCompatibility,
    String? climate,
    String? crowd,
    int? month,
    String? costLevel,
    bool clearRegion = false,
    bool clearCategory = false,
    bool clearCompatibility = false,
    bool clearClimate = false,
    bool clearCrowd = false,
    bool clearCost = false,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      region: clearRegion ? null : (region ?? this.region),
      category: clearCategory ? null : (category ?? this.category),
      minCompatibility: clearCompatibility
          ? null
          : (minCompatibility ?? this.minCompatibility),
      climate: clearClimate ? null : (climate ?? this.climate),
      crowd: clearCrowd ? null : (crowd ?? this.crowd),
      month: month ?? this.month,
      costLevel: clearCost ? null : (costLevel ?? this.costLevel),
    );
  }
}

/// Result item. La compatibilidad/label solo existen cuando el orden IA está
/// activo y hay perfil; en búsqueda normal son null (no se inventan scores).
class SearchResultItem {
  final DestinationModel destination;
  final int? compatibility;
  final double? contextualScore;
  final int? rankingPosition;
  final String? label; // la etiqueta que calculó el motor

  SearchResultItem({
    required this.destination,
    this.compatibility,
    this.contextualScore,
    this.rankingPosition,
    this.label,
  });
}

class SearchController extends ChangeNotifier {
  final DestinationService _destinationService;
  final LocalStorageService _storageService;
  bool isLoading = false;
  List<SearchResultItem> results = [];
  SearchFilters filters = const SearchFilters();
  String? error;

  // Unique values for filter options (populated from data)
  List<String> availableRegions = [];
  List<String> availableCostLevels = [];
  /// Si falló la carga del clima/afluencia del mes, aquí queda el aviso para mostrar.
  String? contextError;
  List<String> availableCategories = [];

  /// Orden por recomendación IA. Apagado por defecto: la búsqueda es normal.
  bool aiSortEnabled = false;

  /// True cuando se pidió orden IA pero el usuario no tiene perfil viajero.
  /// La UI muestra un aviso para completar el perfil; los resultados se
  /// mantienen en orden normal (sin inventar scores).
  bool aiBlockedNoProfile = false;

  SearchController(this._destinationService, this._storageService);

  /// [aiSort] activa/desactiva el orden por IA.
  /// [hasProfile] indica si el usuario tiene perfil viajero (lo pasa la vista
  /// leyendo ProfileController), necesario para poder ordenar por IA.
  Future<void> search({
    SearchFilters? newFilters,
    bool? aiSort,
    bool hasProfile = false,
  }) async {
    if (newFilters != null) filters = newFilters;
    if (aiSort != null) aiSortEnabled = aiSort;
    isLoading = true;
    error = null;
    aiBlockedNoProfile = false;
    notifyListeners();

    try {
      final all = await _destinationService.getDestinations();

      // Opciones de filtro con los datos reales (se descartan los vacíos).
      availableRegions = all
          .map((d) => d.region)
          .where((r) => r.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => normalizeForSearch(a).compareTo(normalizeForSearch(b)));
      availableCategories = all
          .map((d) => d.category)
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => normalizeForSearch(a).compareTo(normalizeForSearch(b)));

      availableCostLevels = [
        for (final level in kCostOptions.keys)
          if (all.any((d) => d.costLevel == level)) level,
      ];

      // Clima y afluencia del mes (datos de la tesis) solo si hay filtro de ese tipo.
      Map<String, MonthContext>? monthContext;
      contextError = null;
      if (filters.climate != null || filters.crowd != null) {
        try {
          monthContext = await _destinationService
              .getMonthContext(filters.month ?? DateTime.now().month);
        } catch (e) {
          contextError =
              'No pudimos cargar el clima y la afluencia de ese mes. Intenta de nuevo.';
          error = contextError;
          results = [];
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Apply text + faceted filters (sin filtros sobre datos inexistentes).
      final q = normalizeForSearch(filters.query);
      final tourismText = q.isEmpty
          ? <String, String>{}
          : await _destinationService.getTourismSearchIndex();
      if (q.isNotEmpty) _storageService.addRecentSearch(filters.query.trim());
      final filtered = all.where((d) {
        if (q.isNotEmpty) {
          final matches = [
            d.name,
            d.city,
            d.region,
            d.category,
            tourismText[d.id] ?? '',
          ]
              .any((field) => normalizeForSearch(field).contains(q));
          if (!matches) return false;
        }
        if (filters.region != null && d.region != filters.region) return false;
        if (filters.costLevel != null && d.costLevel != filters.costLevel) {
          return false;
        }
        if (monthContext != null) {
          final c = monthContext[d.id];
          if (c == null) return false; // sin datos del mes: no se puede afirmar nada
          if (filters.climate != null && !c.climateFavorable(filters.climate!)) {
            return false;
          }
          if (filters.crowd != null && c.aforoNivel != filters.crowd) {
            return false;
          }
        }
        if (filters.category != null && d.category != filters.category) {
          return false;
        }
        return true;
      }).toList();

      if (aiSortEnabled && hasProfile) {
        // ── Orden IA: enriquecer con lo que dice el motor y ordenar desc. ──
        // Un destino que el motor no recomienda (fuera del motor) queda sin
        // porcentaje ni etiqueta y va al final: no se inventa un 0 %.
        final enriched = <SearchResultItem>[];
        for (final d in filtered) {
          final info = await _destinationService.getRankingInfo(d.id, month: filters.month);
          enriched.add(SearchResultItem(
            destination: d,
            compatibility: info?.percent,
            contextualScore: info?.score,
            rankingPosition: info?.rank,
            label: info?.label,
          ));
        }
        final compatFiltered = filters.minCompatibility != null
            ? enriched
                .where((r) =>
                    r.compatibility != null &&
                    r.compatibility! >= filters.minCompatibility!)
                .toList()
            : enriched;
        compatFiltered.sort(
            (a, b) {
              if (a.rankingPosition != null && b.rankingPosition != null) return a.rankingPosition!.compareTo(b.rankingPosition!);
              return (b.contextualScore ?? -double.infinity).compareTo(a.contextualScore ?? -double.infinity);
            });
        results = compatFiltered;
      } else {
        // ── Orden normal: alfabético. Sin scores IA inventados. ──
        if (aiSortEnabled && !hasProfile) {
          aiBlockedNoProfile = true;
        }
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        results = filtered
            .map((d) => SearchResultItem(destination: d))
            .toList();
      }
    } catch (e) {
      error = 'No pudimos buscar destinos. Revisa tu conexión e intenta de nuevo.';
      results = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void clearFilters() {
    filters = SearchFilters(query: filters.query);
    search(
      aiSort: aiSortEnabled,
      hasProfile: _storageService.getProfile()?.isRecommendationReady == true,
    );
  }
}
