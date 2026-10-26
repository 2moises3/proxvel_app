import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/my_reviews_controller.dart';
import 'package:proxvell_app/integration/services/review_service.dart';
import 'package:proxvell_app/models/review_model.dart';
import 'package:proxvell_app/models/user_model.dart';

class PendingReviews extends ReviewService {
  final requests = <String, Completer<List<ReviewModel>>>{};
  int calls = 0;
  @override
  Future<List<ReviewModel>> getReviewsByUser(String id) {
    calls++;
    return (requests[id] = Completer<List<ReviewModel>>()).future;
  }
}

void main() {
  final ana = UserModel(id: 'a', name: 'Ana', email: 'a@example.test');
  final bea = UserModel(id: 'b', name: 'Bea', email: 'b@example.test');
  ReviewModel review(String id) =>
      ReviewModel(ratingGeneral: 4, reviewText: 'Prueba', userId: id);

  test(
    'concurrent profile and reviews entry only request once for the same account',
    () async {
      final service = PendingReviews();
      final controller = MyReviewsController(service);
      final loading = controller.loadUserReviews(ana);
      await controller.loadUserReviews(ana);
      expect(service.calls, 1);
      service.requests['a']!.complete([review('a')]);
      await loading;
      expect(controller.reviews.single.userId, 'a');
      controller.dispose();
    },
  );

  test('late response after clear cannot restore private reviews', () async {
    final service = PendingReviews();
    final controller = MyReviewsController(service);
    final loading = controller.loadUserReviews(ana);
    controller.clearState();
    service.requests['a']!.complete([review('a')]);
    await loading;
    expect(controller.reviews, isEmpty);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test(
    'late error from previous account cannot overwrite the new account',
    () async {
      final service = PendingReviews();
      final controller = MyReviewsController(service);
      final first = controller.loadUserReviews(ana);
      final second = controller.loadUserReviews(bea);
      service.requests['b']!.complete([review('b')]);
      await second;
      service.requests['a']!.completeError(StateError('offline'));
      await first;
      expect(controller.reviews.single.userId, 'b');
      expect(controller.error, isNull);
      controller.dispose();
    },
  );
}
