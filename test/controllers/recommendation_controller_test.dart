import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:proxvell_app/models/recommendation_result_model.dart';
import 'package:proxvell_app/models/destination_model.dart';

class DelayedRecommendations extends RecommendationService {
  final requests = <Completer<List<RecommendationResultModel>>>[];
  @override
  Future<List<RecommendationResultModel>> getMyRecommendations({
    int limit = 10,
    int? month,
    String? region,
  }) {
    final request = Completer<List<RecommendationResultModel>>();
    requests.add(request);
    return request.future;
  }
}

RecommendationResultModel recommendation(String id) =>
    RecommendationResultModel(
      id: id,
      destination: DestinationModel(
        id: id,
        name: id,
        city: '',
        region: 'Cusco',
        category: '',
        description: '',
        imageUrl: '',
        averageCost: 0,
        climate: '',
        crowdLevel: '',
        rating: 0,
        aspects: [],
      ),
      compatibilityPercentage: 80,
      finalScore: 1.02,
      label: 'Recomendado',
      reasons: [],
      aspectScores: [],
      contextSignals: [],
    );

void main() {
  test(
    'una respuesta del mes anterior no sustituye el mes elegido después',
    () async {
      final service = DelayedRecommendations();
      final controller = RecommendationController(service);
      final january = controller.setMonth(1);
      final july = controller.setMonth(7);
      service.requests[1].complete([recommendation('julio')]);
      await july;
      service.requests[0].complete([recommendation('enero')]);
      await january;
      expect(controller.selectedMonth, 7);
      expect(controller.recommendations.single.id, 'julio');
    },
  );

  test('cerrar sesión descarta una respuesta pendiente', () async {
    final service = DelayedRecommendations();
    final controller = RecommendationController(service);
    final pending = controller.loadRecommendations();
    controller.clearState();
    service.requests.single.complete([recommendation('privado')]);
    await pending;
    expect(controller.recommendations, isEmpty);
    expect(controller.globalRecommendations, isEmpty);
  });
}
