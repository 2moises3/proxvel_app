import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/navigation/proxvel_bottom_navigation.dart';
import 'package:proxvell_app/l10n/app_localizations.dart';
import 'package:proxvell_app/views/home/widgets/month_fan_picker.dart';

void main() {
  for (final language in ['es', 'en']) {
    testWidgets('compact navigation exposes tappable semantics in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ProxvelBottomNavigation(
                currentIndex: 0,
                onTap: (index) => selected = index,
              ),
            ),
          ),
        ),
      );
      final map = find.bySemanticsLabel(language == 'en' ? 'Map' : 'Mapa');
      final node = tester.getSemantics(map);
      expect(node.rect.height, greaterThanOrEqualTo(48));
      expect(node.rect.width, greaterThanOrEqualTo(48));
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.tap,
      );
      expect(selected, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('a single tap opens a month list and selects July', (
    tester,
  ) async {
    int? month;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: MonthFanPicker(month: 1, onChanged: (value) => month = value),
        ),
      ),
    );
    await tester.tap(find.text('January'));
    await tester.pumpAndSettle();
    expect(find.text('Choose month'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('July'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('July'));
    await tester.pumpAndSettle();
    expect(month, 7);
  });
}
