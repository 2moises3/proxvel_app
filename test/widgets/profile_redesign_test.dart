import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/utils/avatar_picker_helper.dart';
import 'package:proxvell_app/views/profile/widgets/profile_header.dart';
import 'package:proxvell_app/views/profile/widgets/profile_menu_section.dart';
import 'package:proxvell_app/views/profile/widgets/about_proxvel_sheet.dart';

void main() {
  test(
    'avatar validation mirrors allowed formats without trusting extension',
    () {
      expect(avatarValidationMessage([]), isNotNull);
      expect(avatarValidationMessage([1, 2, 3]), isNotNull);
      expect(avatarValidationMessage([255, 216, 255, 0]), isNull);
      expect(
        avatarValidationMessage([137, 80, 78, 71, 13, 10, 26, 10]),
        isNull,
      );
      expect(
        avatarValidationMessage([82, 73, 70, 70, 0, 0, 0, 0, 87, 69, 66, 80]),
        isNull,
      );
      expect(
        avatarValidationMessage(List.filled(5 * 1024 * 1024 + 1, 0)),
        isNotNull,
      );
    },
  );
  testWidgets('profile remains readable at narrow width and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  name: 'María Alejandra Morales',
                  email: 'viajera@example.com',
                  onTapAvatar: () {},
                  onEditProfile: () {},
                ),
                ProfileMenuSection(
                  onEditProfile: () {},
                  onChangePassword: () {},
                  onPreferences: () {},
                  onMyReviews: () {},
                  onArchived: () {},
                  onPrivacy: () {},
                  onAbout: () {},
                  onUpdates: () {},
                  onLogout: () {},
                  onDeleteAccount: () => deleted = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Eliminar mi cuenta'), 300);
    await tester.tap(find.text('Eliminar mi cuenta'));
    expect(deleted, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('about uses installed version and exposes legal content', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'PROXVEL',
      packageName: 'test',
      version: '2.3.4',
      buildNumber: '17',
      buildSignature: '',
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const AboutProxvelScreen()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Política de privacidad'), 300);
    expect(find.text('Política de privacidad'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Versión 2.3.4 · 17'), 300);
    expect(find.text('Versión 2.3.4 · 17'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
