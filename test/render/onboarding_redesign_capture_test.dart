import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/onboarding/onboarding_profile_screen.dart';
import 'package:proxvell_app/views/onboarding/widgets/illustrated_preference_option.dart';

void main() {
  testWidgets('keeps the intro and first step usable on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.2),
          ),
          child: child!,
        ),
        home: const OnboardingProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Omitir por ahora'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'captures the five preference steps and preserves forward navigation',
    (tester) async {
      final fonts = FontLoader('Outfit');
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        fonts.addFont(
          rootBundle.load('assets/fonts/outfit/Outfit-$weight.ttf'),
        );
      }
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();

      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: RepaintBoundary(
            key: key,
            child: const OnboardingProfileScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            384,
            null,
            const AssetImage('assets/images/onboarding_backpack_peru.png'),
          ),
          key.currentContext!,
        );
        for (final path in [
          'assets/images/onboarding_backpack_peru.png',
          'assets/images/onboarding_climates_peru.png',
          'assets/images/onboarding_crowds_peru.png',
          'assets/images/onboarding_interests_peru.png',
        ]) {
          await precacheImage(
            ResizeImage.resizeIfNeeded(640, null, AssetImage(path)),
            key.currentContext!,
          );
        }
        for (final name in [
          'nature',
          'culture',
          'history',
          'food',
          'adventure',
          'mountains',
          'photography',
          'beach',
          'urban',
          'rural',
          'academic',
          'relax',
          'family',
        ]) {
          await precacheImage(
            ResizeImage.resizeIfNeeded(
              384,
              null,
              AssetImage('assets/images/onboarding_${name}_scene.webp'),
            ),
            key.currentContext!,
          );
        }
      });
      await tester.pumpAndSettle();

      Future<void> capture(String name) async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../proxvel_landing/.artifacts/onboarding-$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('intro');
      expect(find.text('Omitir por ahora'), findsOneWidget);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5'), findsOneWidget);
      await tester.tap(find.text('Cultural'));
      await tester.pumpAndSettle();
      await capture('style');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5'), findsOneWidget);
      await tester.tap(find.byTooltip('Añadir un día'));
      await tester.pump();
      expect(find.text('2 días'), findsOneWidget);
      await tester.tap(find.text('Medio'));
      await tester.pumpAndSettle();
      await capture('budget');
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      await capture('budget-compact');
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(430, 900);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('3 de 5'), findsOneWidget);
      await tester.tap(find.text('Templado'));
      await tester.pumpAndSettle();
      await capture('climate');
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(430, 900);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('4 de 5'), findsOneWidget);
      await tester.tap(find.text('Me adapto'));
      await tester.pumpAndSettle();
      await capture('crowds');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('5 de 5'), findsOneWidget);
      await tester.tap(find.text('Naturaleza'));
      await tester.pumpAndSettle();
      await capture('interests');
      await tester.ensureVisible(find.text('Familiar'));
      await tester.tap(find.text('Familiar'));
      await tester.pumpAndSettle();
      await capture('interests-bottom');
      for (final label in ['Naturaleza', 'Familiar']) {
        expect(
          tester
              .widget<IllustratedPreferenceOption>(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is IllustratedPreferenceOption &&
                      widget.label == label,
                ),
              )
              .selected,
          isTrue,
        );
      }
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Familiar'));
      expect(find.text('Guardar preferencias'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
