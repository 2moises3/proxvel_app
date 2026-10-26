import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/auth/register_screen.dart';

void main() {
  testWidgets(
    'registration still requires eight matching characters without a strength meter',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.enterText(find.byType(TextField).at(1), 'Torres');
      await tester.enterText(find.byType(TextField).at(2), 'ana@example.test');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '1234567');
      await tester.enterText(find.byType(TextField).at(1), '1234567');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(find.text('Débil'), findsNothing);
      expect(find.text('Segura'), findsNothing);
      expect(find.text('Fuerte'), findsNothing);
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '12345678');
      await tester.pump();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
