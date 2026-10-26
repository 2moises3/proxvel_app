import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';
import 'package:proxvell_app/views/destination/widgets/about_destination_tab_content.dart';
import 'package:proxvell_app/views/destination/widgets/why_for_me_tab_content.dart';

void main() {
  testWidgets(
    'detail disclosures do not read the saved scroll offset as a bool',
    (tester) async {
      final panel = ValueNotifier<Widget>(const SizedBox(height: 1200));
      final scroll = ScrollController();
      final bucket = PageStorageBucket();
      addTearDown(panel.dispose);
      addTearDown(scroll.dispose);
      final destination = DestinationModel.fromApiCatalog({
        'destination_id': 'test',
        'destination': 'Destino',
      });
      final about = AboutDestinationTabContent(
        destination: destination,
        tourismInfo: TourismCatalogModel(
          visitorInfoSummary: 'Información de visita',
          howToGet: 'Ruta de llegada',
          accessibilitySummary: 'Acceso disponible',
        ),
      );
      const why = WhyForMeTabContent(
        compatibilityPercentage: 54,
        label: 'Parcialmente recomendado',
        explanation: 'Afinidad real',
        topAspects: [],
        aspectScores: [],
        shapBase: .5,
        shapValues: {'afinidad': .2},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PageStorage(
              bucket: bucket,
              child: ValueListenableBuilder<Widget>(
                valueListenable: panel,
                builder: (context, child, _) => CustomScrollView(
                  key: const PageStorageKey('destination/test/explore'),
                  controller: scroll,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 800)),
                    SliverToBoxAdapter(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      scroll.jumpTo(773);
      await tester.pumpAndSettle();
      final offset = bucket.readState(
        tester.element(find.byType(CustomScrollView)),
      );
      expect(offset, 773);
      panel.value = about;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      panel.value = why;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final interpret = find.text('Cómo interpretar este resultado');
      await tester.ensureVisible(interpret);
      await tester.tap(interpret);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La afinidad combina tus intereses'),
        findsOneWidget,
      );
      panel.value = about;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Each disclosure has its own state, separate from the scroll and other tabs.
      final route = find.text('Cómo llegar');
      await tester.ensureVisible(route);
      await tester.tap(route);
      await tester.pumpAndSettle();
      expect(find.text('Ruta de llegada'), findsOneWidget);
      panel.value = why;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La afinidad combina tus intereses'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        bucket.readState(tester.element(find.byType(CustomScrollView))),
        isA<double>(),
      );
    },
  );
}
