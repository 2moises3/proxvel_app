import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Outfit reaches text, controls and dialogs (dark: $dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Explora Perú')),
            body: Column(
              children: [
                const Text('Tu próxima historia'),
                const TextField(
                  decoration: InputDecoration(hintText: 'Buscar'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Descubrir'),
                ),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text('Tus preferencias'),
                        content: Text('Elige tu forma de viajar'),
                      ),
                    ),
                    child: const Text('Preferencias'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      void expectOutfit(String label) {
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        );
        expect(richText.text.style?.fontFamily, 'Outfit', reason: label);
      }

      for (final label in [
        'Explora Perú',
        'Tu próxima historia',
        'Descubrir',
        'Preferencias',
      ]) {
        expectOutfit(label);
      }
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontFamily, 'Outfit');
      await tester.tap(find.text('Preferencias'));
      await tester.pumpAndSettle();
      expectOutfit('Tus preferencias');
      expectOutfit('Elige tu forma de viajar');
      expect(tester.takeException(), isNull);
    });
  }
}
