import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/recommendation_result_model.dart';
import 'package:proxvell_app/views/home/widgets/home_discovery_sections.dart';

void main() {
  testWidgets('las secciones usan destinos reales y abren su categoría', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nature = DestinationModel.fromApiCatalog({
      'destination_id': 'paracas',
      'destination': 'Reserva Nacional de Paracas',
      'city': 'Paracas',
      'region': 'Ica',
      'category': 'Naturaleza',
    });
    final archaeology = DestinationModel.fromApiCatalog({
      'destination_id': 'huaca',
      'destination': 'Huaca de la Luna',
      'city': 'Trujillo',
      'region': 'La Libertad',
      'category': 'Arqueología',
    });
    final recommendation = RecommendationResultModel(
      id: nature.id,
      destination: nature,
      compatibilityPercentage: 82,
      finalScore: .82,
      label: 'Recomendado',
      reasons: const [],
      aspectScores: const [],
      contextSignals: const [],
    );
    String? selectedCategory;
    String? selectedDestination;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeDiscoverySections(
              destinations: [nature, archaeology],
              recommendations: [recommendation],
              onOpenForYou: () {},
              onOpenDestination: (destination) =>
                  selectedDestination = destination.id,
              onOpenCategory: (category) => selectedCategory = category,
              onOpenCatalog: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recomendado para ti'), findsOneWidget);
    expect(find.text('Reserva Nacional de Paracas'), findsWidgets);
    expect(find.text('Para descubrir'), findsOneWidget);
    expect(find.text('Tendencias del momento'), findsNothing);
    expect(find.byKey(const ValueKey('home-category-Todos')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Reserva Nacional de Paracas').first);
    expect(selectedDestination, 'paracas');

    final categoriesRail = find.byKey(const ValueKey('home-categories-rail'));
    await tester.ensureVisible(categoriesRail);
    await tester.pumpAndSettle();
    final categoriesList = tester.widget<ListView>(categoriesRail);
    expect(categoriesList.controller!.offset, 0);
    await tester.drag(categoriesRail, const Offset(-250, 0));
    await tester.pumpAndSettle();
    final categoryRow = find.byKey(const ValueKey('home-category-Arqueología'));
    await tester.ensureVisible(categoryRow);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: categoryRow, matching: find.text('Arqueología')),
    );
    await tester.pumpAndSettle();
    expect(selectedCategory, isNull);
    final openCategory = find.text('Ver Arqueología (1) →');
    await tester.ensureVisible(openCategory);
    await tester.pumpAndSettle();
    await tester.tap(openCategory);
    expect(selectedCategory, 'Arqueología');
  });
}
