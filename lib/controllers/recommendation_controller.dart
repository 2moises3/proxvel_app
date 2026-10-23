import 'package:flutter/material.dart';
import '../models/recommendation_result_model.dart';
import '../integration/services/recommendation_service.dart';
import '../integration/api/api_client.dart';

class RecommendationController extends ChangeNotifier {
  final RecommendationService _recommendationService;
  bool isLoading = false;
  bool profileIncomplete = false;
  List<RecommendationResultModel> recommendations = [];
  List<RecommendationResultModel> globalRecommendations = [];
  String? error;
  int? selectedMonth;
  String? selectedRegion;
  bool _isStale = false;
  int _generation = 0;
  RecommendationController(this._recommendationService);
  void invalidate() {
    _generation++;
    _isStale = true;
    recommendations = [];
    globalRecommendations = [];
    error = null;
    notifyListeners();
  }

  Future<void> setMonth(int? month) async {
    if (selectedMonth == month) return;
    selectedMonth = month;
    await loadRecommendations(forceRefresh: true);
  }

  Future<void> setRegion(String? region) async {
    if (selectedRegion == region) return;
    selectedRegion = region;
    await loadRecommendations(forceRefresh: true);
  }

  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    if (!forceRefresh && !_isStale && (isLoading || recommendations.isNotEmpty)) {
      return;
    }
    final generation = ++_generation;
    isLoading = true;
    profileIncomplete = false;
    recommendations = [];
    globalRecommendations = [];
    error = null;
    notifyListeners();
    try {
      final full = await _recommendationService.getMyRecommendations(
        limit: 100,
        month: selectedMonth,
      );
      if (generation != _generation) return;
      globalRecommendations = full;
      // El filtro de región no cambia los puntajes ni su orden relativo.
      recommendations = selectedRegion == null
          ? full
          : full.where((r) => r.destination.region == selectedRegion).toList();
      _isStale = false;
    } catch (e) {
      if (generation != _generation) return;
      profileIncomplete =
          e is ApiException &&
          (e.code == 'TRAVELER_PROFILE_INCOMPLETE' ||
              (e.statusCode == 400 &&
                  e.message.contains('no cuenta con un perfil de viaje')));
      error = profileIncomplete
          ? 'Completa tu estilo de viajero y preferencias para recibir recomendaciones.'
          : e is ApiException && (e.statusCode == 400 || e.statusCode == 422)
          ? 'No pudimos procesar la solicitud de recomendaciones. Intenta nuevamente.'
          : 'No pudimos cargar tus recomendaciones. Revisa tu conexión e intenta de nuevo.';
    }
    if (generation != _generation) return;
    isLoading = false;
    notifyListeners();
  }

  void clearState() {
    _generation++;
    recommendations = [];
    globalRecommendations = [];
    profileIncomplete = false;
    error = null;
    _isStale = false;
    isLoading = false;
    selectedMonth = null;
    selectedRegion = null;
    notifyListeners();
  }
}
