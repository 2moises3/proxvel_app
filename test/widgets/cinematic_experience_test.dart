import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/views/auth/welcome_screen.dart';
import 'package:proxvell_app/views/auth/login_screen.dart';
import 'package:proxvell_app/views/auth/register_screen.dart';
import 'package:proxvell_app/views/auth/widgets/auth_backdrop.dart';
import 'package:proxvell_app/views/destination/widgets/expandable_description_text.dart';
import 'package:proxvell_app/core/navigation/destination_opening.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/destination_controller.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/tourism_service.dart';
import 'package:proxvell_app/integration/services/review_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/views/destination/destination_detail_screen.dart';
import 'package:proxvell_app/views/home/widgets/home_discovery_sections.dart';

class _WaitingDestinationController extends DestinationController {
  _WaitingDestinationController()
    : super(DestinationService(), TourismService(), ReviewService()) {
    isLoading = true;
  }
  @override
  Future<void> loadDestination(String id, {int? month}) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AuthScenes.selected = 0);

  GoRouter router() => GoRouter(
    initialLocation: '/welcome',
    observers: [authRouteObserver],
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    ],
  );
  Widget host(GoRouter route, {bool reduce = false}) => MaterialApp.router(
    theme: AppTheme.lightTheme,
    routerConfig: route,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduce,
        textScaler: const TextScaler.linear(1.3),
      ),
      child: child!,
    ),
  );
  String background(WidgetTester tester) =>
      tester.widget<AuthBackdrop>(find.byType(AuthBackdrop).last).imagePath;

  testWidgets(
    'la bienvenida rota, congela el fondo al ingresar y lo conserva al volver',
    (tester) async {
      final route = router();
      await tester.pumpWidget(host(route));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(background(tester), AuthScenes.assets[1]);
      await tester.ensureVisible(find.text('Ya tengo cuenta · Iniciar sesión'));
      await tester.tap(find.text('Ya tengo cuenta · Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(background(tester), AuthScenes.assets[1]);
      await tester.enterText(
        find.byType(TextField).first,
        'viajero@example.test',
      );
      await tester.pump(const Duration(seconds: 24));
      expect(background(tester), AuthScenes.assets[1]);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'viajero@example.test',
      );
      route.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(background(tester), AuthScenes.assets[1]);
      await tester.pump(const Duration(seconds: 8));
      expect(background(tester), AuthScenes.assets[2]);
      await tester.pumpWidget(const SizedBox());
      route.dispose();
    },
  );

  testWidgets('el registro recibe el paisaje elegido y no lo cambia', (
    tester,
  ) async {
    final route = router();
    await tester.pumpWidget(host(route));
    await tester.pump(const Duration(seconds: 8));
    await tester.ensureVisible(find.text('Crear mi cuenta'));
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(background(tester), AuthScenes.assets[1]);
    await tester.pump(const Duration(seconds: 24));
    expect(background(tester), AuthScenes.assets[1]);
    expect(find.text('Nombre'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    route.dispose();
  });

  testWidgets(
    'reducir movimiento mantiene una sola imagen y admite pantalla pequeña',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final route = router();
      await tester.pumpWidget(host(route, reduce: true));
      await tester.pump(const Duration(seconds: 32));
      expect(background(tester), AuthScenes.assets.first);
      await tester.ensureVisible(find.text('Crear mi cuenta'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      route.dispose();
    },
  );

  testWidgets('la bienvenida no avanza mientras la app está en segundo plano', (
    tester,
  ) async {
    final route = router();
    await tester.pumpWidget(host(route));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 24));
    expect(background(tester), AuthScenes.assets.first);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 8));
    expect(background(tester), AuthScenes.assets[1]);
    await tester.pumpWidget(const SizedBox());
    route.dispose();
  });

  testWidgets('una descripción breve no ofrece una expansión innecesaria', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ExpandableDescriptionText(text: 'Un valle entre montañas.'),
        ),
      ),
    );
    expect(find.text('Leer descripción'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('la imagen compartida se abre y vuelve sin duplicar héroes', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    Widget photo() => const DestinationHero(
      tag: 'search/destino',
      child: ColoredBox(color: Colors.amber),
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: Scaffold(body: SizedBox(width: 100, height: 120, child: photo())),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: SizedBox(height: 400, child: photo())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'la vista previa mantiene la imagen compartida mientras responde la API',
    (tester) async {
      final controller = _WaitingDestinationController();
      final destination = DestinationModel.fromApiCatalog({
        'destination_id': 'destino',
        'destination': 'Destino',
        'category': 'Naturaleza',
      });
      Widget detail(String id) =>
          ChangeNotifierProvider<DestinationController>.value(
            value: controller,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: DestinationDetailScreen(
                key: ValueKey(id),
                destinationId: id,
                opening: DestinationOpening(destination, 'search'),
              ),
            ),
          );
      await tester.pumpWidget(detail('destino'));
      await tester.pump();
      expect(tester.widget<Hero>(find.byType(Hero)).tag, 'search/destino');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(detail('otro'));
      await tester.pump();
      expect(
        find.byType(Hero),
        findsNothing,
        reason: 'Una vista previa de otro destino no se reutiliza.',
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'explorar mantiene legibilidad con nombres largos y texto ampliado',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final destination = DestinationModel.fromApiCatalog({
        'destination_id': 'destino',
        'destination': 'Complejo Arqueológico de un Nombre Extenso',
        'category': 'Arqueología',
        'city': 'Ciudad con nombre largo',
        'region': 'Región con nombre largo',
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeDiscoverySections(
                destinations: [destination],
                recommendations: const [],
                onOpenForYou: () {},
                onOpenDestination: (_) {},
                onOpenCategory: (_) {},
                onOpenCatalog: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
