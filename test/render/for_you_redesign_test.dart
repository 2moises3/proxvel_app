import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/controllers/archive_controller.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:proxvell_app/integration/services/archive_service.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/recommendation_result_model.dart';
import 'package:proxvell_app/views/home/widgets/home_for_you_content.dart';
import 'package:proxvell_app/views/home/widgets/explore_hero.dart';
import 'package:proxvell_app/views/home/widgets/month_fan_picker.dart';

void main() {
  testWidgets('month fan commits only on release and supports cancel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <int?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 280, right: 24),
            child: Align(
              alignment: Alignment.topRight,
              child: MonthFanPicker(month: null, onChanged: calls.add),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(OutlinedButton)),
    );
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(find.text('Dic'), findsOneWidget);
    final centers = MonthFanPicker.labels
        .map((label) => tester.getCenter(find.text(label).last))
        .toList();
    for (var i = 0; i < centers.length; i++) {
      for (var j = i + 1; j < centers.length; j++) {
        expect((centers[i] - centers[j]).distance, greaterThanOrEqualTo(62));
      }
    }
    // Both rings cover the full left half-turn, above and below the anchor.
    final anchorY = tester.getCenter(find.byType(OutlinedButton)).dy;
    expect(centers[6].dy, lessThan(anchorY));
    expect(centers[12].dy, greaterThan(anchorY));
    await gesture.moveTo(tester.getCenter(find.text('Jul')));
    await tester.pump();
    expect(calls, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [7]);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(calls, [7]);
    expect(find.text('Dic'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screens and larger text retain the month fan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected = 7;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: MonthFanPicker(
            month: 7,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
    expect(find.byType(GridView), findsNothing);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'for you presents all eligible visible results and compact controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('Outfit');
      for (final w in ['Regular', 'Medium', 'SemiBold']) {
        font.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$w.ttf'));
      }
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final controller = RecommendationController(RecommendationService());
      controller.recommendations = List.generate(
        7,
        (i) => RecommendationResultModel(
          id: '$i',
          destination: DestinationModel.fromApiCatalog({
            'destination_id': '$i',
            'destination': i == 0
                ? 'Reserva Nacional de Paracas'
                : 'Destino $i',
            'region': 'Ica',
            'category': 'Naturaleza',
          }).copyWithImage('assets/images/auth_costa_v1.png', []),
          compatibilityPercentage: 70,
          finalScore: 1 - i / 10,
          label: i == 6
              ? 'No recomendado'
              : i == 5
              ? 'Parcialmente recomendado'
              : 'Recomendado',
          monthName: 'octubre',
          reasons: [
            'Coincide con tus intereses en naturaleza y relax. El clima de este mes se ajusta a tus preferencias.',
          ],
          aspectScores: [],
          contextSignals: [],
        ),
      );
      final archives = ArchiveController(ArchiveService())
        ..hasLoaded = true
        ..archivedDestinationIds.add('4');
      final favorites = FavoritesController(FavoritesService());
      final capture = GlobalKey();
      final fullCapture = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: controller),
            ChangeNotifierProvider.value(value: archives),
            ChangeNotifierProvider.value(value: favorites),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Outfit'),
            builder: (context, child) =>
                RepaintBoundary(key: fullCapture, child: child!),
            home: RepaintBoundary(
              key: capture,
              child: Scaffold(
                backgroundColor: const Color(0xFFF9FAFB),
                body: Column(
                  children: [
                    ExploreHero(
                      userName: 'Marck Morales',
                      showSearch: false,
                      unreadCount: 0,
                      onProfile: () {},
                      onNotifications: () {},
                      onSearch: () {},
                    ),
                    const SizedBox(height: 16),
                    const Text('Explorar                 ✦ Para ti'),
                    const Expanded(child: HomeForYouContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/auth_costa_v1.png'),
          capture.currentContext!,
        );
        await precacheImage(
          const AssetImage('assets/images/home_andes_lagoon.webp'),
          capture.currentContext!,
        );
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('5 destinos para explorar'), findsOneWidget);
      expect(find.textContaining('Coincide con tus intereses'), findsNothing);
      expect(find.text('¿A dónde quieres ir?').hitTestable(), findsNothing);
      expect(find.text('#1'), findsNothing);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/for-you-redesign.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);
      await tester.runAsync(() async {
        final boundary =
            fullCapture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/month-fan.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      archives.dispose();
      favorites.dispose();
    },
  );
}
