import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/controllers/destination_controller.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/controllers/announcement_controller.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/tourism_service.dart';
import 'package:proxvell_app/integration/services/review_service.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/integration/services/announcement_service.dart';
import 'package:proxvell_app/views/destination/destination_detail_screen.dart';
import '../render/destination_redesign_test.dart' show fixture, snapshot;

class DetailController extends DestinationController {
  DetailController()
    : super(DestinationService(), TourismService(), ReviewService()) {
    destination = fixture;
    tourismInfo = TourismCatalogModel(
      description: 'Información del destino',
      recommendedDuration: 'Medio día',
      latitude: -13.16,
      longitude: -72.54,
    );
  }
  @override
  Future<void> loadDestination(String id, {int? month}) async {}
}

void main() {
  testWidgets(
    'recommendation opens Para ti and detail tabs remain pinned after scrolling',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final imageKey = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DestinationController>(
              create: (_) => DetailController(),
            ),
            ChangeNotifierProvider(
              create: (_) => FavoritesController(FavoritesService()),
            ),
            ChangeNotifierProvider(
              create: (_) => AnnouncementController(AnnouncementService()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: RepaintBoundary(
              key: imageKey,
              child: const DestinationDetailScreen(
                destinationId: 'fixture',
                source: 'ai_recommendation',
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DestinationDetailScreen));
        await precacheImage(
          const AssetImage('assets/images/home_andes_lagoon.webp'),
          context,
        );
        await precacheImage(
          const AssetImage('assets/images/auth_andes_v1.png'),
          context,
        );
      });
      await tester.pump(const Duration(seconds: 1));
      await snapshot(tester, imageKey, 'detail-initial');
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tu viaje merece algo más personal.'), findsOneWidget);
      final y = tester.getTopLeft(find.text('Para ti')).dy;
      expect(y, lessThan(60));
      expect(y, greaterThanOrEqualTo(0));
      await tester.tap(find.text('El lugar'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Conoce el lugar'), findsOneWidget);
      final reassembly = tester.binding.reassembleApplication();
      await tester.pump(const Duration(seconds: 1));
      await reassembly;
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Reseñas'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('El lugar'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Conoce el lugar'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
