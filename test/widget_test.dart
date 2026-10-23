import 'package:flutter_test/flutter_test.dart';

import 'package:proxvell_app/app.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';

void main() {
  testWidgets('la app arranca sin errores', (WidgetTester tester) async {
    final storageService = LocalStorageService();
    // Construye la app y dibuja el primer frame.
    await tester.pumpWidget(ProxvelApp(storageService: storageService));
  });
}
