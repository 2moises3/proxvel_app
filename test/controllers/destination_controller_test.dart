import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/destination_controller.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/review_service.dart';
import 'package:proxvell_app/integration/services/tourism_service.dart';
import 'package:proxvell_app/models/aspect_score_model.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/review_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';

DestinationModel destination(String id) => DestinationModel(
      id: id,
      name: id,
      city: '',
      region: '',
      category: '',
      description: '',
      imageUrl: '',
      averageCost: 0,
      climate: '',
      crowdLevel: '',
      rating: 0,
      aspects: const [],
    );

class FakeDestinationService extends DestinationService {
  final Future<DestinationModel?> Function(String id) load;
  FakeDestinationService(this.load);

  @override
  Future<DestinationModel?> getDestinationById(String id, {int? month}) =>
      load(id);

  @override
  Future<List<AspectScoreModel>> getAspectScores(String id, {int? month}) async =>
      [];

  @override
  Future<String> getExplanation(String id, {int? month}) async => '';

  @override
  Future<RankingInfo?> getRankingInfo(String id, {int? month}) async => null;

  @override
  Future<Map<String, dynamic>> getDestinationContext(String id,
          {int? month}) async =>
      {};
}

class FakeTourismService extends TourismService {
  @override
  Future<TourismCatalogModel?> getTourismCatalog(String id) async => null;
}

class FakeReviewService extends ReviewService {
  @override
  Future<List<ReviewModel>> getReviewsForDestination(String id) async => [];
}

void main() {
  test('un destino inexistente borra la ficha anterior', () async {
    final controller = DestinationController(
      FakeDestinationService((id) async =>
          id == 'existente' ? destination(id) : null),
      FakeTourismService(),
      FakeReviewService(),
    );
    await controller.loadDestination('existente');
    expect(controller.destination?.id, 'existente');

    await controller.loadDestination('inexistente');
    expect(controller.isLoading, isFalse);
    expect(controller.destination, isNull);
    expect(controller.error, 'No encontramos este destino.');
  });

  test('una respuesta tardía no sustituye el destino abierto', () async {
    final first = Completer<DestinationModel?>();
    final controller = DestinationController(
      FakeDestinationService((id) =>
          id == 'primero' ? first.future : Future.value(destination(id))),
      FakeTourismService(),
      FakeReviewService(),
    );

    final oldLoad = controller.loadDestination('primero');
    await controller.loadDestination('segundo');
    first.complete(destination('primero'));
    await oldLoad;

    expect(controller.destination?.id, 'segundo');
    expect(controller.error, isNull);
  });
}
