import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/auth/login_screen.dart';
import 'package:proxvell_app/views/auth/register_screen.dart';
import 'package:proxvell_app/views/auth/widgets/auth_form_page.dart';

void main() {
  for (final size in [const Size(516,956), const Size(390,844), const Size(320,640)]) {
    testWidgets('account forms scroll only when content needs it at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      double extent() => tester.state<ScrollableState>(
        find.descendant(of: find.byType(AuthFormPage), matching: find.byType(Scrollable)).first,
      ).position.maxScrollExtent;

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();
      if (size.height >= 844) {
        expect(extent(), 0, reason: 'Login should fit without drag scrolling');
      } else {
        expect(extent(), greaterThan(0), reason: 'Compact screens keep controls accessible');
      }

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();
      if (size.height >= 844) {
        expect(extent(), 0, reason: 'Registration first step should fit');
      } else {
        expect(extent(), greaterThan(0));
      }

      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.enterText(find.byType(TextField).at(1), 'Torres');
      await tester.enterText(find.byType(TextField).at(2), 'ana@example.test');
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Crea tu contraseña'), findsOneWidget);
      if (size.height >= 844) {
        expect(extent(), 0, reason: 'Password step should fit');
      } else {
        expect(extent(), greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
