import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/auth/session_ready_screen.dart';

void main() {
  testWidgets(
    'welcome fits a narrow screen with large text and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: const SessionWelcomeView(
              background: 'assets/images/auth_costa_v1.png',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ya estás dentro.'), findsOneWidget);
      expect(find.text('Continuar al inicio'), findsNothing);
    },
  );

  testWidgets('slow loading offers an accessible way to continue', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SessionWelcomeView(
          background: 'assets/images/auth_costa_v1.png',
          onContinue: () => continued = true,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Continuar al inicio'));
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
  });
}
