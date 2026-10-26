import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/models/favorite_model.dart';

class CountingFavoritesService extends FavoritesService {
  int calls = 0;
  final response = Completer<List<FavoriteModel>>();

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
}
