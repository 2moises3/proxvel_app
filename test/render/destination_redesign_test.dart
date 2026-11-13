import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/maps/destination_location.dart';
import 'package:proxvell_app/controllers/destination_controller.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/tourism_service.dart';
import 'package:proxvell_app/integration/services/review_service.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';
import 'package:proxvell_app/models/review_model.dart';
import 'package:proxvell_app/views/destination/widgets/destination_cover.dart';
import 'package:proxvell_app/views/destination/widgets/about_destination_tab_content.dart';
import 'package:proxvell_app/views/destination/widgets/reviews_tab_content.dart';
import 'package:proxvell_app/views/destination/widgets/why_for_me_tab_content.dart';

final fixture = DestinationModel(
  id: 'fixture',
  name: 'Santuario Histórico de Machu Picchu',
  city: 'Aguas Calientes',
  region: 'Cusco',
  category: 'Arqueología',
  description:
      'Una visita entre montañas para descubrir la historia del lugar.',
  imageUrl: 'assets/images/home_andes_lagoon.webp',
  galleryImages: ['assets/images/auth_andes_v1.png'],
  averageCost: 0,
  climate: '',
  crowdLevel: '',
  rating: 0,
  aspects: [],
);
Future<void> snapshot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFF8F9FA), BlendMode.src);
    canvas.drawImage(image, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final opaque = await picture.toImage(image.width, image.height);
    final bytes = await opaque.toByteData(format: ui.ImageByteFormat.png);
    opaque.dispose();
    picture.dispose();
    final file = File('../proxvel_landing/.artifacts/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() {
    DestinationLocation.shared.position = null;
    DestinationLocation.shared.measuredAt = null;
    DestinationLocation.shared.error = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (call) async => switch (call.method) {
            'isLocationServiceEnabled' => true,
            'checkPermission' => 0,
            _ => null,
          },
        );
  });
  test('hide today expires on next calendar day', () {
    final today = DateTime(2026, 10, 26, 23, 59);
    final dismissed = LocationInvitationPolicy.day(today);
    expect(LocationInvitationPolicy.shouldShow(dismissed, today), false);
    expect(
      LocationInvitationPolicy.shouldShow(
        dismissed,
        today.add(const Duration(minutes: 2)),
      ),
      true,
    );
  });
  testWidgets('cover fills viewport, gallery stays stable, large text fits', (
    tester,
  ) async {
    final font = FontLoader('Outfit');
    for (final w in ['Regular', 'Medium', 'SemiBold']) {
      font.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$w.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    String? selected;
    for (final size in [const Size(390, 844), const Size(320, 640)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FavoritesController(FavoritesService()),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: SingleChildScrollView(
                  child: DestinationCover(
                    destination: fixture,
                    onOpenGallery: () {},
                    onImageChanged: (s) => selected = s,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(AssetImage(fixture.imageUrl), key.currentContext!);
        await precacheImage(
          AssetImage(fixture.galleryImages.first),
          key.currentContext!,
        );
      });
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DestinationCover)).height, size.height);
      await tester.tap(find.bySemanticsLabel('Fotografía 2 de 2'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(DestinationCover)).height, size.height);
      await tester.tap(find.bySemanticsLabel('Fotografía 1 de 2'));
      await tester.pumpAndSettle();
      expect(selected, fixture.imageUrl);
      expect(tester.takeException(), isNull);
      if (size.width == 390) await snapshot(tester, key, 'detail-cover');
    }
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesController(FavoritesService()),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DestinationCover(
                destination: fixture,
                onOpenGallery: () {},
                onImageChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('about renders only real provided fields and clips disclosures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AboutDestinationTabContent(
                destination: fixture,
                tourismInfo: TourismCatalogModel(
                  description: fixture.description,
                  recommendedDuration: 'Medio día',
                  difficulty: 'moderada',
                  altitudeM: 2430,
                  costLevel: 'medio',
                  activitiesSummary:
                      'Camina, conoce su historia y disfruta del paisaje.',
                  visitorInfoSummary:
                      'Confirma las condiciones de ingreso antes de tu visita.',
                  interestTags: ['Historia', 'Naturaleza'],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2430 m s. n. m.'), findsOneWidget);
    expect(find.textContaining('S/'), findsNothing);
    expect(tester.takeException(), isNull);
    await snapshot(tester, key, 'detail-information');
  });
  testWidgets('review distribution uses real rows and star filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c =
        DestinationController(
            DestinationService(),
            TourismService(),
            ReviewService(),
          )
          ..destination = fixture
          ..reviews = [
            ReviewModel(
              ratingGeneral: 5,
              reviewText: 'Una visita inolvidable.',
              userId: 'a',
              authorName: 'Lucía P.',
              createdAt: '2026-10-20',
            ),
            ReviewModel(
              ratingGeneral: 3,
              reviewText: 'Conviene planificar el ingreso.',
              userId: 'b',
              authorName: 'Mario R.',
            ),
          ];
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ReviewsTabContent(controller: c),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(2));
    await snapshot(tester, key, 'detail-reviews');
    await tester.tap(find.widgetWithText(ChoiceChip, '5'));
    await tester.pumpAndSettle();
    expect(find.text('Una visita inolvidable.'), findsOneWidget);
    expect(find.text('Conviene planificar el ingreso.'), findsNothing);
    expect(tester.takeException(), isNull);
    c.dispose();
  });
  testWidgets('affinity shows engine values without imaginary explanations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: WhyForMeTabContent(
              compatibilityPercentage: 67,
              label: 'Recomendado',
              explanation: 'Coincide con tus intereses.',
              topAspects: [],
              aspectScores: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('Coincide con tus intereses.'), findsOneWidget);
    expect(find.text('Contexto del mes'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
