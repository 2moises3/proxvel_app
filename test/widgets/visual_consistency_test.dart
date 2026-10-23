import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proxvell_app/core/widgets/buttons/shimmer_button.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/states/error_view.dart';
import 'package:proxvell_app/views/auth/login_screen.dart';
import 'package:proxvell_app/views/auth/register_screen.dart';
import 'package:proxvell_app/views/destination/widgets/ranking_header_card.dart';

Widget host(Widget child, Size size, {double keyboard = 0}) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: size,
      textScaler: const TextScaler.linear(1.3),
      viewInsets: EdgeInsets.only(bottom: keyboard),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: child,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 390.0]) {
    testWidgets('login: validación y teclado a $width con texto ampliado', (
      tester,
    ) async {
      final size = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const LoginScreen(), size));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('El correo es requerido'), findsOneWidget);
      expect(find.text('La contraseña es requerida'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(const LoginScreen(), size, keyboard: 280));
      await tester.pump();
      await tester.ensureVisible(find.text('Iniciar sesión'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('registro: ambos pasos a $width con texto ampliado', (
      tester,
    ) async {
      final size = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const RegisterScreen(), size));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).at(0), 'Prueba');
      await tester.enterText(find.byType(TextField).at(1), 'Visual');
      await tester.enterText(
        find.byType(TextField).at(2),
        'visual@example.test',
      );
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      await tester.ensureVisible(find.text('Crear mi cuenta'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'la explicación secundaria se abre sin ocultar el significado del porcentaje',
    (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: RankingHeaderCard(
                rankPosition: 3,
                compatibilityPercentage: 91,
                label: 'Parcialmente recomendado',
              ),
            ),
          ),
          const Size(320, 800),
        ),
      );
      expect(
        find.text('No indica una probabilidad de satisfacción.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entender mi afinidad'));
      await tester.pumpAndSettle();
      expect(find.textContaining('El orden también considera'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el error admite un espacio reducido y conserva reintentar', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: SizedBox(
            width: 280,
            height: 220,
            child: ErrorView(
              message: 'Revisa tu conexión y vuelve a intentarlo.',
              onRetry: () => retries++,
            ),
          ),
        ),
        const Size(320, 800),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'el botón de acceso conserva su alto y evita toques durante la espera',
    (tester) async {
      final animation = AnimationController(vsync: tester);
      var taps = 0;
      Widget button(bool loading) => host(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ShimmerButton(
              shimmer: animation,
              baseColor: const Color(0xFFF59E0B),
              hoverColor: const Color(0xFFD97706),
              text: 'Iniciar sesión',
              isLoading: loading,
              onPressed: () => taps++,
            ),
          ),
        ),
        const Size(320, 800),
      );
      await tester.pumpWidget(button(false));
      final height = tester.getSize(find.byType(ShimmerButton)).height;
      await tester.pumpWidget(button(true));
      expect(tester.getSize(find.byType(ShimmerButton)).height, height);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(taps, 0);
      await tester.pumpWidget(const SizedBox());
      animation.dispose();
    },
  );
}
