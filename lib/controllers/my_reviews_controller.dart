import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../integration/services/review_service.dart';

class MyReviewsController extends ChangeNotifier {
  final ReviewService _reviewService;

  bool isLoading = false;
  List<ReviewModel> reviews = [];
  String? error;
  int _generation = 0;
  String? _userId;

  MyReviewsController(this._reviewService);

  Future<void> loadUserReviews(UserModel? currentUser) async {
    if (isLoading && _userId == currentUser?.id) return;
    final generation = ++_generation;
    if (_userId != currentUser?.id) reviews = [];
    _userId = currentUser?.id;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (currentUser == null) {
        error =
            'No se encontró un usuario activo. Regístrate o inicia sesión para continuar.';
        reviews = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      String userId = currentUser.id;

      final fetched = await _reviewService.getReviewsByUser(userId);
      if (generation != _generation) return;
      reviews = fetched;
    } catch (e) {
      if (generation != _generation) return;
      error = 'No se pudieron cargar tus reseñas. Inténtalo nuevamente.';
      debugPrint('[MyReviewsController] Error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  /// Limpia todo el estado en memoria. Llamar al logout/cambio de usuario.
  void clearState() {
    _generation++;
    _userId = null;
    reviews = [];
    error = null;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
