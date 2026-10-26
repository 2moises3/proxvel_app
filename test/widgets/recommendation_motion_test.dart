import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/archive_controller.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/integration/services/archive_service.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/recommendation_result_model.dart';
import 'package:proxvell_app/views/home/widgets/home_for_you_content.dart';
import 'package:proxvell_app/views/home/widgets/recommendation_motion.dart';

class _Service extends RecommendationService {
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

RecommendationResultModel result() => RecommendationResultModel(
  id: 'test',
  destination: DestinationModel.fromApiCatalog({
    'destination_id': 'test',
    'destination': 'Destino de prueba',
    'category': 'Naturaleza',
  }),
  compatibilityPercentage: 83,
  finalScore: .9,
  label: 'Recomendado',
  reasons: [],
  aspectScores: [],
  contextSignals: [],
);

void main() {
  testWidgets('cards enter alternately and settle without scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RecommendationArrival(index: 0, animate: true, child: Text('A')),
              RecommendationArrival(index: 1, animate: true, child: Text('B')),
            ],
          ),
        ),
      ),
    );
    final transforms = find.descendant(
      of: find.byType(RecommendationArrival),
      matching: find.byType(Transform),
    );
    expect(
      tester.widget<Transform>(transforms.at(0)).transform.getTranslation().x,
      lessThan(0),
    );
    expect(
      tester.widget<Transform>(transforms.at(1)).transform.getTranslation().x,
      greaterThan(0),
    );
    await tester.pumpAndSettle();
    for (final widget in tester.widgetList<Transform>(transforms)) {
      expect(widget.transform.getTranslation().x, 0);
    }
  });

  testWidgets(
    'reduced motion presents results and a static loading indicator',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  RecommendationWorkingState(),
                  RecommendationArrival(
                    index: 0,
                    animate: true,
                    child: Text('Resultado'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNotNull,
      );
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(RecommendationArrival),
          matching: find.byType(Transform),
        ),
      );
      expect(transform.transform.getTranslation().x, 0);
    },
  );

  testWidgets(
    'real month and profile requests drive loading and affinity output',
    (tester) async {
      final service = _Service();
      final controller = RecommendationController(service);
      final archives = ArchiveController(ArchiveService())..hasLoaded = true;
      final pending = controller.setMonth(7);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: controller),
            ChangeNotifierProvider.value(value: archives),
            ChangeNotifierProvider(
              create: (_) => FavoritesController(FavoritesService()),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeForYouContent())),
        ),
      );
      expect(find.byType(RecommendationWorkingState), findsOneWidget);
      expect(find.text('83% de afinidad'), findsNothing);
      service.requests.last.complete([result()]);
      await pending;
      await tester.pumpAndSettle();
      expect(find.byType(RecommendationWorkingState), findsNothing);
      expect(find.text('83% de afinidad'), findsOneWidget);
      final revision = controller.resultsRevision;
      controller.invalidate();
      final reload = controller.loadRecommendations(forceRefresh: true);
      await tester.pump();
      expect(find.byType(RecommendationWorkingState), findsOneWidget);
      service.requests.last.complete([result()]);
      await reload;
      await tester.pumpAndSettle();
      expect(controller.resultsRevision, greaterThan(revision));
      expect(find.byType(RecommendationWorkingState), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
