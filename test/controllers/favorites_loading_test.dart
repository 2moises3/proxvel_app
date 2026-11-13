import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/models/favorite_model.dart';

class CountingFavoritesService extends FavoritesService {
  int calls = 0;
  int addCalls = 0;
  final mutation = Completer<bool>();
  final response = Completer<List<FavoriteModel>>();

  @override
  Future<bool> addFavorite(String destinationId) {
    addCalls++;
    return mutation.future;
  }

  @override
  Future<List<FavoriteModel>> getFavorites() {
    calls++;
    return response.future;
  }
}

void main() {
  test('Home and Favorites share one request and reuse its result', () async {
    final service = CountingFavoritesService();
    final controller = FavoritesController(service);
    addTearDown(controller.dispose);

    final homeLoad = controller.ensureFavoritesLoaded();
    final favoritesLoad = controller.ensureFavoritesLoaded();
    expect(service.calls, 1);

    service.response.complete([]);
    await Future.wait([homeLoad, favoritesLoad]);
    await controller.ensureFavoritesLoaded();
    expect(service.calls, 1);
    expect(controller.hasLoaded, isTrue);
  });
  test(
    'favorite changes optimistically and rolls back a rejected request',
    () async {
      final service = CountingFavoritesService();
      final controller = FavoritesController(service);
      addTearDown(controller.dispose);

      final saving = controller.toggleFavorite('d1');
      expect(controller.isFavorite('d1'), isTrue);
      expect(await controller.toggleFavorite('d1'), isNull);
      expect(service.addCalls, 1);

      service.mutation.complete(false);
      expect(await saving, isFalse);
      expect(controller.isFavorite('d1'), isFalse);
      expect(controller.isSaving('d1'), isFalse);
    },
  );
}
