import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/archive_controller.dart';
import 'package:proxvell_app/controllers/home_controller.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/archive_service.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:proxvell_app/models/archive_model.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/recommendation_result_model.dart';
import 'package:proxvell_app/core/widgets/cards/destination_recommendation_card.dart';
import 'package:proxvell_app/core/widgets/carousels/coverflow_carousel.dart';
import 'package:proxvell_app/views/home/widgets/home_explore_content.dart';
import 'package:proxvell_app/views/home/widgets/home_for_you_content.dart';

class _Service extends ArchiveService {
  final requests = <Completer<List<ArchiveModel>>>[];
  @override
  Future<List<ArchiveModel>> getArchives() {
    final next = Completer<List<ArchiveModel>>();
    requests.add(next);
    return next.future;
  }
}

void main() {
  final destination = DestinationModel.fromApiCatalog({
    'destination_id': 'hidden',
    'destination': 'Destino oculto',
    'category': 'Naturaleza',
  });

  testWidgets(
    'For you never renders excluded card during load, failure or retry',
    (tester) async {
      final service = _Service();
      final archives = ArchiveController(service);
      final recommendations = RecommendationController(RecommendationService())
        ..recommendations = [
          RecommendationResultModel(
            id: 'hidden',
            destination: destination,
            compatibilityPercentage: 80,
            finalScore: .8,
            label: 'Recomendado',
            reasons: [],
            aspectScores: [],
            contextSignals: [],
          ),
        ];
      final loading = archives.loadArchives();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: archives),
            ChangeNotifierProvider.value(value: recommendations),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeForYouContent())),
        ),
      );
      expect(find.byType(DestinationRecommendationCard), findsNothing);
      expect(find.text('Preparando tus destinos…'), findsOneWidget);
      service.requests.first.completeError(StateError('offline'));
      await loading;
      await tester.pump();
      expect(find.byType(DestinationRecommendationCard), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(service.requests.length, 2);
      expect(find.byType(DestinationRecommendationCard), findsNothing);
      service.requests.last.complete([
        ArchiveModel(destinationId: 'hidden', name: 'Destino oculto'),
      ]);
      await tester.pump();
      expect(archives.hasLoaded, true);
      expect(find.byType(DestinationRecommendationCard), findsNothing);
      expect(
        find.text(
          'Has ocultado estos destinos. Puedes recuperarlos desde Archivados.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explore with a ready catalog waits for exclusions and offers retry',
    (tester) async {
      final service = _Service();
      final archives = ArchiveController(service);
      final home = HomeController(DestinationService(), LocalStorageService())
        ..destinations = [destination];
      final loading = archives.loadArchives();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: archives),
            ChangeNotifierProvider.value(value: home),
          ],
          child: MaterialApp(
            home: Scaffold(body: HomeExploreContent(onSwitchToForYou: () {})),
          ),
        ),
      );
      expect(find.byType(CoverflowCarousel), findsNothing);
      service.requests.first.completeError(StateError('offline'));
      await loading;
      await tester.pump();
      expect(find.byType(CoverflowCarousel), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
