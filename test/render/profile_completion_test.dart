import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/onboarding/widgets/profile_completion_view.dart';

void main() {
  testWidgets(
    'completion explains where to go and waits for explicit navigation',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
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
      final key = GlobalKey();
      var navigations = 0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: key,
            child: ProfileCompletionView(onContinue: () => navigations++),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = key.currentContext!;
        for (final scene in ['mountains', 'beach', 'culture']) {
          await precacheImage(
            ResizeImage(
              AssetImage('assets/images/onboarding_${scene}_scene.webp'),
              width: 256,
            ),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(navigations, 0);
      expect(find.text('Inicio → Para ti'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/onboarding-completion.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Ir al inicio'));
      expect(navigations, 1);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: ProfileCompletionView(onContinue: () {}, isEntering: true),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
