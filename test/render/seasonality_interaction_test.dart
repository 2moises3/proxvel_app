import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/models/seasonality_model.dart';
import 'package:proxvell_app/views/destination/widgets/seasonality_section.dart';
import 'destination_redesign_test.dart' show snapshot;

class CalendarService extends DestinationService {
  @override
  Future<DestinationCalendar?> getCalendar(
    String id, {
    String? clima,
    String? tolerancia,
  }) async => DestinationCalendar(
    destinationId: id,
    preference: 'templado',
    tolerance: 'media',
    bestMonth: 7,
    worstMonth: 1,
    months: List.generate(
      12,
      (i) => CalendarMonth(
        month: i + 1,
        hasData: i != 2,
        combined: i == 2 ? null : .3 + (6 - (6 - i).abs()) * .1,
        tempProm: i == 2 ? null : 18.5,
        lluviaMm: i == 2 ? null : 12,
        visitantesMedios: i == 2 ? null : 2400,
        climaNivel: 'Favorable',
        aforoNivel: 'Medio',
        climaExplicacion: 'Temperaturas suaves según los registros históricos.',
        aforoExplicacion: 'Afluencia moderada para tu tolerancia.',
      ),
    ),
  );
}

void main() {
  testWidgets(
    'calendar selects actual months, preserves missing data and renders metrics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('Outfit');
      for (final weight in ['Regular', 'Medium', 'SemiBold']) {
        font.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$weight.ttf'));
      }
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final key = GlobalKey();
      await tester.pumpWidget(
        Provider<DestinationService>(
          create: (_) => CalendarService(),
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Outfit'),
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SeasonalitySection(
                    destinationId: 'fixture',
                    initialMonth: 7,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Julio'), findsOneWidget);
      expect(find.text('18.5 °C'), findsOneWidget);
      await snapshot(tester, key, 'seasonality-interactive');
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Aún no tenemos datos de marzo'),
        findsOneWidget,
      );
      expect(find.text('18.5 °C'), findsNothing);
      await tester.tap(find.textContaining('Tu mejor contexto:'));
      await tester.pumpAndSettle();
      expect(find.text('Julio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
