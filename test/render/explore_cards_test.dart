import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/core/widgets/carousels/coverflow_carousel.dart';
import 'package:proxvell_app/views/home/widgets/home_discovery_sections.dart';

class _Favorites extends FavoritesController {
  _Favorites() : super(FavoritesService());
  @override
  Future<void> toggleFavorite(String id, [DestinationModel? model]) async {
    if (!favoriteDestinationIds.remove(id)) favoriteDestinationIds.add(id);
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'deck opens the visible card, swipes, saves and handles small catalogs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fonts = FontLoader('Outfit');
      for (final weight in ['Regular', 'Medium', 'SemiBold']) {
        fonts.addFont(
          rootBundle.load('assets/fonts/outfit/Outfit-$weight.ttf'),
        );
      }
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final destinations = [
        for (final (i, region) in ['Cusco', 'Ica', 'San Martín'].indexed)
          DestinationModel.fromApiCatalog({
            'destination_id': '$i',
            'destination': [
              'Valle Sagrado de los Incas',
              'Reserva Nacional de Paracas',
              'Catarata de Ahuashiyacu',
            ][i],
            'region': region,
            'category': i == 0 ? 'Arqueología' : 'Naturaleza',
          }).copyWithImage(
            'assets/images/${['auth_andes_v1.png', 'auth_costa_v1.png', 'auth_selva_v1.png'][i]}',
            [],
          ),
      ];
      final favorites = _Favorites();
      String? opened;
      final key = GlobalKey();
      Widget app(List<DestinationModel> items, {double scale = 1}) =>
          ChangeNotifierProvider<FavoritesController>.value(
            value: favorites,
            child: MaterialApp(
              theme: ThemeData(fontFamily: 'Outfit'),
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                backgroundColor: const Color(0xFFFAFAF8),
                body: RepaintBoundary(
                  key: key,
                  child: ColoredBox(
                    color: const Color(0xFFFAFAF8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CoverflowCarousel(
                            destinations: items,
                            onDestinationTap: (d) => opened = d.id,
                          ),
                          const SizedBox(height: 24),
                          HomeDiscoverySections(
                            destinations: items,
                            recommendations: const [],
                            onOpenForYou: () {},
                            onOpenDestination: (_) {},
                            onOpenCategory: (_) {},
                            onOpenCatalog: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(app(destinations));
      await tester.runAsync(() async {
        for (final d in destinations) {
          await precacheImage(AssetImage(d.imageUrl), key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ver destino').hitTestable());
      expect(opened, '0');
      await tester.tap(find.byTooltip('Guardar en favoritos').hitTestable());
      await tester.pump();
      expect(favorites.isFavorite('0'), isTrue);
      await tester.drag(find.byType(CoverflowCarousel), const Offset(-190, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ver destino').hitTestable());
      expect(opened, '1');
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/explore-deck.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -620),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/explore-editorial.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -650),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/explore-categories.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 3000),
      );
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpWidget(app(destinations.take(2).toList(), scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Destino siguiente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(destinations.take(1).toList()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Destino siguiente'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app([]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
