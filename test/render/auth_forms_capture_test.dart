import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/views/auth/login_screen.dart';
import 'package:proxvell_app/views/auth/register_screen.dart';
import 'package:proxvell_app/views/auth/residence_gate_screen.dart';
import 'package:proxvell_app/views/auth/forgot_password_screen.dart';
import 'package:proxvell_app/views/auth/reset_password_screen.dart';
import 'package:proxvell_app/views/auth/widgets/auth_backdrop.dart';

void main() {
  testWidgets('capture account forms from real widgets without account writes', (tester) async {
    final fonts = FontLoader('Outfit');
    for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$name.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    AuthScenes.selected = 2;
    final key = GlobalKey();
    Future<void> show(Widget screen) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: key, child: screen),
      ));
      await tester.runAsync(() async {
        await precacheImage(const ResizeImage(AssetImage('assets/images/auth_selva_v1.png'), width: 720), key.currentContext!);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pumpAndSettle();
    }
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('../proxvel_landing/.artifacts/auth-selva-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await show(const LoginScreen());
    await capture('auth-clean-login');
    await show(const RegisterScreen());
    await capture('auth-clean-register-01');
    await tester.enterText(find.byType(TextField).at(0), 'Ana');
    await tester.enterText(find.byType(TextField).at(1), 'Torres');
    await tester.enterText(find.byType(TextField).at(2), 'preview@example.test');
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await capture('auth-clean-register-02');
    await show(const ResidenceGateScreen(mode: ResidenceGateMode.registration));
    await capture('auth-clean-residence');
    await show(const ForgotPasswordScreen());
    await capture('auth-clean-recovery');
    await show(const ResetPasswordScreen(email: 'preview@example.test'));
    await capture('auth-clean-reset');
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
