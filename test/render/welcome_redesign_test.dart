import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/views/auth/welcome_screen.dart';
import 'package:proxvell_app/views/auth/widgets/auth_backdrop.dart';

void main() {
  testWidgets('welcome pages render and retain full width actions', (
    tester,
  ) async {
    final font = FontLoader('Outfit');
    for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$name.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    AuthScenes.selected = 2;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: key, child: const WelcomeScreen()),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const ResizeImage(
          AssetImage('assets/images/auth_selva_v1.png'),
          width: 720,
        ),
        key.currentContext!,
      );
    });
    await tester.pump(const Duration(milliseconds: 100));
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '../proxvel_landing/.artifacts/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    await capture('welcome-splash-01');
    tester.view.physicalSize = const Size(320, 740);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Crear cuenta'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
