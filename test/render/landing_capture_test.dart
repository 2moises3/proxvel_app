// Marketing captures rendered from production widgets; no account or API writes.
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/views/auth/welcome_screen.dart';
import 'package:proxvell_app/views/home/widgets/home_explore_content.dart';
import 'package:proxvell_app/views/search/widgets/search_filter_sheet.dart';
import 'package:proxvell_app/controllers/home_controller.dart';
import 'package:proxvell_app/controllers/archive_controller.dart';
import 'package:proxvell_app/controllers/favorites_controller.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/controllers/profile_controller.dart';
import 'package:proxvell_app/controllers/announcement_controller.dart';
import 'package:proxvell_app/controllers/search_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/archive_service.dart';
import 'package:proxvell_app/integration/services/favorites_service.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:proxvell_app/integration/services/profile_service.dart';
import 'package:proxvell_app/integration/services/announcement_service.dart';
import 'package:proxvell_app/models/destination_model.dart';

class QuietAnnouncements extends AnnouncementController {
  QuietAnnouncements() : super(AnnouncementService());
  @override
  Future<void> load({
    String placement = 'home_top',
    String? destinationId,
  }) async {}
}

void main() {
  testWidgets('render landing product captures', (tester) async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final outfit = FontLoader('Outfit');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      outfit.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$weight.ttf'));
    }
    await outfit.load();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    final storage = LocalStorageService();
    await storage.init();
    final raw =
        jsonDecode(
              File(
                '../proxvel_landing/src/data/catalog.json',
              ).readAsStringSync().replaceFirst('\uFEFF', ''),
            )
            as List;
    const photoMap = {
      'machu_picchu': 'machupicchu',
      'reserva_paracas': 'paracas',
      'valle_colca': 'colca',
      'ciudadela_kuelap': 'kuelap',
      'huaca_pucllana': 'huaca-pucllana',
    };
    final byId = {
      for (final row in raw.cast<Map<String, dynamic>>())
        row['destination_id']: row,
    };
    final destinations = [
      for (final entry in photoMap.entries)
        DestinationModel.fromApiCatalog(
          byId[entry.key]!,
        ).copyWithImage('capture_photos/${entry.value}.webp', const []),
    ];
    final home = HomeController(DestinationService(), storage)
      ..destinations = destinations;
    final key = GlobalKey();
    Future<void> capture(String name, Widget screen) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: home),
            ChangeNotifierProvider(
              create: (_) =>
                  ArchiveController(ArchiveService())..hasLoaded = true,
            ),
            ChangeNotifierProvider(
              create: (_) => FavoritesController(FavoritesService()),
            ),
            ChangeNotifierProvider(
              create: (_) => RecommendationController(RecommendationService()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  ProfileController(ProfileService(storage), storage),
            ),
            ChangeNotifierProvider<AnnouncementController>(
              create: (_) => QuietAnnouncements(),
            ),
          ],
          child: DefaultAssetBundle(
            bundle: _CaptureBundle(),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              home: RepaintBoundary(key: key, child: screen),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 650));
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.broken_image_rounded), findsNothing);
      if (name == 'explore') {
        expect(find.byIcon(Icons.landscape_outlined), findsNothing);
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../proxvel_landing/.artifacts/current-$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('welcome', const WelcomeScreen());
    await capture(
      'explore',
      Scaffold(
        body: SafeArea(child: HomeExploreContent(onSwitchToForYou: () {})),
      ),
    );
    await capture(
      'filters',
      Scaffold(
        body: SafeArea(
          child: SearchFilterSheet(
            controller: SearchController(DestinationService(), storage)
              ..availableCategories = ['Arqueología', 'Naturaleza', 'Museo']
              ..availableRegions = ['Cusco', 'Lima', 'Ica'],
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _CaptureBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    const prefix = 'capture_photos/';
    if (key.startsWith(prefix)) {
      final photo = File(
        '../proxvel_landing/public/images/${key.substring(prefix.length)}',
      );
      return ByteData.sublistView(photo.readAsBytesSync());
    }
    return rootBundle.load(key);
  }
}
