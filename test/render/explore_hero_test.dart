import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/home/widgets/explore_hero.dart';

void main() {
  testWidgets(
    'hero sizes to content and keeps search, profile and notifications usable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fonts = FontLoader('Outfit');
      for (final w in ['Regular', 'Medium']) {
        fonts.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$w.ttf'));
      }
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      var profile = 0, search = 0, notifications = 0;
      final key = GlobalKey();
      Widget app({
        double scale = 1,
        String name = 'Marck Morales',
        int unread = 2,
        bool showSearch = true,
        bool reduceMotion = false,
      }) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 24),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: key,
              child: ExploreHero(
                showSearch: showSearch,
                userName: name,
                unreadCount: unread,
                onProfile: () => profile++,
                onNotifications: () => notifications++,
                onSearch: () => search++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/home_andes_lagoon.webp'),
          key.currentContext!,
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The current three-line headline still fits in a compact shared hero.
      expect(tester.getSize(find.byType(ExploreHero)).height, lessThan(320));
      final expandedHeight = tester.getSize(find.byType(ExploreHero)).height;
      final imageRect = tester.getRect(find.byType(Image).first);
      final headingRect = tester.getRect(
        find.text(
          'Descubre destinos increíbles y vive experiencias inolvidables en Perú.',
        ),
      );
      await tester.pumpWidget(app(showSearch: false));
      expect(tester.getSize(find.byType(ExploreHero)).height, expandedHeight);
      await tester.pump(const Duration(milliseconds: 160));
      final intermediateHeight = tester
          .getSize(find.byType(ExploreHero))
          .height;
      expect(intermediateHeight, lessThan(expandedHeight));
      expect(tester.getRect(find.byType(Image).first), imageRect);
      expect(
        tester.getRect(
          find.text(
            'Descubre destinos increíbles y vive experiencias inolvidables en Perú.',
          ),
        ),
        headingRect,
      );
      final opacity = tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      expect(opacity, greaterThan(0));
      expect(opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(find.text('¿A dónde quieres ir?').hitTestable(), findsNothing);
      expect(tester.getRect(find.byType(Image).first), imageRect);
      expect(
        tester.getSize(find.byType(ExploreHero)).height,
        lessThan(expandedHeight - 50),
      );
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 120));
      final reversingHeight = tester.getSize(find.byType(ExploreHero)).height;
      await tester.pumpWidget(app(showSearch: false));
      expect(tester.getSize(find.byType(ExploreHero)).height, reversingHeight);
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marck Morales'));
      await tester.tap(find.text('¿A dónde quieres ir?'));
      await tester.tap(find.byTooltip('Notificaciones'));
      expect(profile, 1);
      expect(search, 1);
      expect(notifications, 1);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/explore-hero.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpWidget(
        app(scale: 1.8, name: 'Marck Alejandro Morales Fernández', unread: 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Buscar y filtrar destinos'));
      expect(search, 2);
      await tester.pumpWidget(app(reduceMotion: true));
      final stableImage = tester.getRect(find.byType(Image).first);
      final expanded = tester.getSize(find.byType(ExploreHero)).height;
      await tester.pumpWidget(app(reduceMotion: true, showSearch: false));
      expect(tester.getRect(find.byType(Image).first), stableImage);
      expect(
        tester.getSize(find.byType(ExploreHero)).height,
        lessThan(expanded - 50),
      );
      expect(find.text('¿A dónde quieres ir?').hitTestable(), findsNothing);
    },
  );
}
