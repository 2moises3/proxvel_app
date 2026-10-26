import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:proxvell_app/controllers/recommendation_controller.dart';
import 'package:proxvell_app/integration/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/controllers/profile_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/profile_service.dart';
import 'package:proxvell_app/models/traveler_profile_model.dart';
import 'package:proxvell_app/models/user_model.dart';
import 'package:proxvell_app/views/profile/preferences_screen.dart';

class EditableProfileFixture extends ProfileController {
  TravelerProfileModel? submitted;
  Completer<void>? pendingSave;
  EditableProfileFixture(LocalStorageService storage)
    : super(ProfileService(storage), storage) {
    user = UserModel(id: 'fixture', name: 'Test', email: 'test@example.com');
    profile = TravelerProfileModel(
      perfilTuristico: 'cultural',
      presupuesto: 'medio',
      diasViaje: 3,
      climaPreferido: 'templado',
      tipoInteres: 'historia',
      intereses: ['historia'],
      toleranciaMultitudes: 'media',
    );
  }
  @override
  Future<void> loadProfileData() async {}
  @override
  Future<void> updatePreferences(TravelerProfileModel updatedProfile) async {
    submitted = updatedProfile;
    await pendingSave?.future;
    profile = updatedProfile;
    notifyListeners();
  }
}

class RecordingRecommendations extends RecommendationController {
  RecordingRecommendations() : super(RecommendationService());
  int refreshes = 0;
  @override
  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
  }
}

void main() {
  testWidgets(
    'all preference sections fit a narrow screen with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await storage.init();
      final controller = EditableProfileFixture(storage);
      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final title in [
        'Tu estilo de viajero',
        'Presupuesto de viaje',
        'Días de viaje',
        'Clima preferido',
        'Tolerancia a multitudes',
        'Tus intereses',
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: title);
        await tester.ensureVisible(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'save keeps draft on failure, prevents duplicate taps and refreshes only after success',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await storage.init();
      final controller = EditableProfileFixture(storage);
      final recommendations = RecordingRecommendations();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProfileController>.value(value: controller),
            ChangeNotifierProvider<RecommendationController>.value(
              value: recommendations,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar preferencias'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Guardar preferencias'), 300);
      controller.pendingSave = Completer<void>();
      await tester.tap(find.text('Guardar preferencias'));
      await tester.pump();
      expect(controller.submitted!.applyAiGlobally, isTrue);
      expect(controller.submitted!.perfilTuristico, 'cultural');
      expect(controller.submitted!.intereses, ['historia']);
      expect(controller.submitted!.diasViaje, 3);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(recommendations.refreshes, 0);
      controller.pendingSave!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(controller.profile!.applyAiGlobally, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(recommendations.refreshes, 0);
      controller.pendingSave = Completer<void>();
      await tester.tap(find.text('Guardar preferencias'));
      await tester.pump();
      controller.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(controller.profile!.applyAiGlobally, isTrue);
      expect(recommendations.refreshes, 1);
      expect(find.byTooltip('Editar preferencias'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      recommendations.dispose();
    },
  );

  testWidgets('back protects an unsaved draft and discard never persists it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();
    final controller = EditableProfileFixture(storage);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Origen')),
        ),
        GoRoute(
          path: '/preferences',
          builder: (_, _) => const PreferencesScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileController>.value(
        value: controller,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    router.push('/preferences');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar preferencias'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir sin guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Origen'), findsOneWidget);
    expect(controller.submitted, isNull);
    expect(controller.profile!.applyAiGlobally, isFalse);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    controller.dispose();
  });
  testWidgets('preference switch stays draft and cancel restores it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();
    final controller = EditableProfileFixture(storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.tap(find.byTooltip('Editar preferencias'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(controller.profile!.applyAiGlobally, isFalse);
    await tester.scrollUntilVisible(find.text('Cancelar'), 300);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.profile!.applyAiGlobally, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
