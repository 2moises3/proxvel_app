import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/aspect_score_model.dart';
import '../models/tourism_catalog_model.dart';
import '../models/review_model.dart';
import '../integration/services/destination_service.dart';
import '../integration/services/tourism_service.dart';
import '../integration/services/review_service.dart';
import '../integration/api/api_client.dart';

class DestinationController extends ChangeNotifier {
  final DestinationService _destinationService;
  final TourismService _tourismService;
  final ReviewService _reviewService;

  bool isLoading = false;
  bool isRecommendationLoading = false;
  bool isTourismLoading = false;
  bool isReviewsLoading = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }

  DestinationModel? destination;
  TourismCatalogModel? tourismInfo;
  List<ReviewModel> reviews = [];
  double averageRating = 0.0;
  bool hasReviewsError = false;
  bool hasTourismError = false;

  List<AspectScoreModel> aspectScores = [];
  String explanation = '';
  int compatibility = 0;
  RankingInfo? rankingInfo;

  /// El motor incluyó este destino entre las recomendaciones del usuario.
  bool hasRecommendation = false;

  /// Etiqueta que calculó el motor (la misma que ven las tarjetas de «Para ti»).
  String? recommendationLabel;
  List<String> recommendationTopAspects = [];
  String? error;

  // Contexto REAL del mes (clima + aforo), NO de reseñas. score 0-1, alto = mejor.
  double? climaContextScore;
  String? climaContextLabel;
  double? aforoContextScore;
  String? aforoContextLabel;
  String? contextMonthName;
  int _loadGeneration = 0;

  DestinationController(
    this._destinationService,
    this._tourismService,
    this._reviewService,
  );

  /// Refreshes only reviews so returning from the editor preserves the photo and scroll.
  Future<void> refreshReviews() async {
    final id = destination?.id;
    final generation = _loadGeneration;
    if (id == null) return;
    try {
      final loaded = await _reviewService.getReviewsForDestination(id);
      if (generation != _loadGeneration || destination?.id != id) return;
      reviews = loaded;
      averageRating = reviews.isEmpty
          ? 0
          : reviews.fold<double>(0, (sum, item) => sum + item.ratingGeneral) /
                reviews.length;
      hasReviewsError = false;
    } catch (_) {
      if (generation != _loadGeneration) return;
      hasReviewsError = true;
    }
    notifyListeners();
  }

  /// Ejecuta una carga opcional: si falla (p. ej. sin perfil viajero) devuelve [fallback]
  /// en vez de tumbar toda la pantalla de detalle.
  Future<T> _safe<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('[DestinationController] carga opcional falló: $e');
      return fallback;
    }
  }

  Future<void> loadDestination(String id, {int? month}) async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    isLoading = true;
    isRecommendationLoading = true;
    isTourismLoading = true;
    isReviewsLoading = true;
    error = null;
    destination = null;
    tourismInfo = null;
    reviews = [];
    averageRating = 0;
    hasReviewsError = false;
    hasTourismError = false;
    aspectScores = [];
    explanation = '';
    compatibility = 0;
    rankingInfo = null;
    hasRecommendation = false;
    recommendationLabel = null;
    recommendationTopAspects = [];
    climaContextScore = null;
    climaContextLabel = null;
    aforoContextScore = null;
    aforoContextLabel = null;
    contextMonthName = null;
    notifyListeners();
    try {
      final loadedDestination = await _destinationService.getDestinationById(
        id,
        month: month,
      );
      if (generation != _loadGeneration) return;
      if (loadedDestination == null) {
        error = 'No encontramos este destino.';
        isRecommendationLoading = false;
        isTourismLoading = false;
        isReviewsLoading = false;
        isLoading = false;
        notifyListeners();
        return;
      }
      destination = loadedDestination;

      // Publish the base record before optional requests finish.
      isLoading = false;
      notifyListeners();

      Future<void> loadRecommendation() async {
        final results = await Future.wait([
          _safe(
            () => _destinationService.getAspectScores(id, month: month),
            <AspectScoreModel>[],
          ),
          _safe(() => _destinationService.getExplanation(id, month: month), ''),
          _safe(
            () => _destinationService.getRankingInfo(id, month: month),
            null as RankingInfo?,
          ),
          _safe(
            () => _destinationService.getDestinationContext(id, month: month),
            <String, dynamic>{},
          ),
        ]);
        if (generation != _loadGeneration) return;
        aspectScores = results[0] as List<AspectScoreModel>;
        explanation = results[1] as String;
        final ranking = results[2] as RankingInfo?;
        rankingInfo = ranking;
        hasRecommendation = ranking != null;
        compatibility = ranking?.percent ?? 0;
        recommendationLabel = ranking?.label;
        recommendationTopAspects = ranking?.topAspects ?? [];

        final ctx = results[3] as Map<String, dynamic>;
        climaContextScore =
            ranking?.climateScore ?? (ctx['clima_score'] as num?)?.toDouble();
        climaContextLabel = ranking == null
            ? ctx['clima_label'] as String?
            : null;
        aforoContextScore =
            ranking?.crowdScore ?? (ctx['aforo_score'] as num?)?.toDouble();
        aforoContextLabel = ranking == null
            ? ctx['aforo_label'] as String?
            : null;
        contextMonthName = ranking?.monthName ?? ctx['month_name'] as String?;

        isRecommendationLoading = false;
        notifyListeners();
      }

      Future<void> loadTourism() async {
        try {
          final info = await _tourismService.getTourismCatalog(id);
          if (generation != _loadGeneration) return;
          tourismInfo = info;
        } catch (e) {
          debugPrint('Error loading tourism catalog: $e');
          if (generation != _loadGeneration) return;
          tourismInfo = null;
          hasTourismError = true;
        }

        if (generation != _loadGeneration) return;
        isTourismLoading = false;
        notifyListeners();
      }

      Future<void> loadReviews() async {
        try {
          final loadedReviews = await _reviewService.getReviewsForDestination(
            id,
          );
          if (generation != _loadGeneration) return;
          reviews = loadedReviews;
          if (reviews.isNotEmpty) {
            final total = reviews.fold(
              0.0,
              (sum, item) => sum + item.ratingGeneral,
            );
            averageRating = total / reviews.length;
          } else {
            averageRating = 0.0;
          }
        } catch (e) {
          debugPrint('Error loading reviews: $e');
          if (generation != _loadGeneration) return;
          reviews = [];
          averageRating = 0.0;
          hasReviewsError = true;
        }
        if (generation != _loadGeneration) return;
        isReviewsLoading = false;
        notifyListeners();
      }

      await Future.wait([
        _safe<void>(loadRecommendation, null).whenComplete(() {
          if (generation != _loadGeneration) return;
          isRecommendationLoading = false;
          notifyListeners();
        }),
        loadTourism(),
        loadReviews(),
      ]);
    } catch (e) {
      if (generation != _loadGeneration) return;
      error = e is ApiException && e.statusCode == 404
          ? 'No encontramos este destino.'
          : 'No pudimos cargar el destino. Revisa tu conexión e intenta de nuevo.';
      destination = null;
    }
    if (generation == _loadGeneration) {
      isLoading = false;
      isRecommendationLoading = false;
      isTourismLoading = false;
      isReviewsLoading = false;
      notifyListeners();
    }
  }
}
