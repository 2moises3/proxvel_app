import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/core/localization/app_language.dart';
import 'package:proxvell_app/core/localization/language_picker.dart';
import 'package:proxvell_app/core/localization/l10n.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/l10n/app_localizations.dart';
import 'package:proxvell_app/views/auth/welcome_screen.dart';
import 'package:proxvell_app/views/legal/legal_document_screen.dart';
import 'package:proxvell_app/views/destination/widgets/about_destination_tab_content.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('English covers welcome, legal documents and catalog fallback', (
    tester,
  ) async {
    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: page,
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const WelcomeScreen());
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Comenzar aventura'), findsNothing);
    await show(LegalDocumentScreen.byId('privacidad'));
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('1. Who is responsible'), findsOneWidget);
    await show(
      Scaffold(
        body: SingleChildScrollView(
          child: AboutDestinationTabContent(
            destination: DestinationModel.fromJson({'id': 'machu_picchu'}),
            tourismInfo: TourismCatalogModel(
              description: 'Ciudadela inca.',
              contentLanguage: 'es',
              difficulty: 'moderada',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Get to know the place'), findsOneWidget);
    expect(find.text('Original content in Spanish'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
  });

  testWidgets('chooses English and persists the choice across launches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final storage = LocalStorageService();
    await storage.init();
    final language = AppLanguage(storage);
    addTearDown(language.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: language,
        child: Consumer<AppLanguage>(
          builder: (_, language, _) => MaterialApp(
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLanguagePicker(context),
                  child: Text(context.l10n.language),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(language.languageCode, 'es');
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(language.languageCode, 'en');
    final nextLaunch = AppLanguage(storage);
    addTearDown(nextLaunch.dispose);
    expect(nextLaunch.locale, const Locale('en'));

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device language'));
    await tester.pumpAndSettle();
    expect(find.text('Idioma'), findsOneWidget);
    expect(language.languageCode, 'es');
  });
}
