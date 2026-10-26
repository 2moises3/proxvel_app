import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/core/widgets/maps/destination_location.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'invitation does not request OS access, dismissal persists today',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/geolocator'),
            (call) async {
              calls.add(call.method);
              return switch (call.method) {
                'checkPermission' => 0,
                'isLocationServiceEnabled' => true,
                _ => null,
              };
            },
          );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: LocationInvitation()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Activar ubicación'), findsOneWidget);
      expect(calls, isNot(contains('requestPermission')));
      expect(calls, isNot(contains('getCurrentPosition')));
      await tester.ensureVisible(find.text('Seguir explorando'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguir explorando'));
      await tester.pumpAndSettle();
      expect(find.text('Activar ubicación'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(LocationInvitationPolicy.key),
        LocationInvitationPolicy.day(DateTime.now()),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: LocationInvitation()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Activar ubicación'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('denied location never produces a fabricated distance', (
    tester,
  ) async {
    var requests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (call) async {
            if (call.method == 'requestPermission') requests++;
            return switch (call.method) {
              'checkPermission' => 0,
              'requestPermission' => 0,
              'isLocationServiceEnabled' => true,
              _ => null,
            };
          },
        );
    final location = DestinationLocation();
    await location.locate(requestPermission: false);
    expect(requests, 0);
    expect(location.position, isNull);
    await location.locate();
    expect(requests, 1);
    expect(location.distance(-12, -77), isNull);
    expect(location.error, contains('sin compartir'));
    location.dispose();
  });
}
