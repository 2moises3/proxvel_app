import 'package:flutter/material.dart';
import 'package:proxvell_app/core/widgets/maps/destination_location.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/views/home/widgets/nearby_destinations_section.dart';
import 'package:proxvell_app/models/destination_model.dart';

void main() {
  setUp(() { DestinationLocation.shared.position = null; DestinationLocation.shared.error = null; });
  testWidgets(
    'shows only catalog destinations within 100 km after permission',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return switch (call.method) {
              'isLocationServiceEnabled' => true,
              'checkPermission' => 2,
              'getCurrentPosition' => {
                'latitude': -12.0,
                'longitude': -77.0,
                'timestamp': 0,
                'accuracy': 100.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'speed_accuracy': 0.0,
                'altitude_accuracy': 0.0,
                'heading_accuracy': 0.0,
              },
              _ => null,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      DestinationModel destination(String name, double lat) =>
          DestinationModel.fromApiCatalog({
            'destination_id': name,
            'destination': name,
            'latitude': lat,
            'longitude': -77.0,
          });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NearbyDestinationsSection(
                destinations: [
                  destination('Cercano', -12.01),
                  destination('Lejano', -14.0),
                ],
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ver cercanos'));
      await tester.pumpAndSettle();
      expect(find.text('Cercano'), findsOneWidget);
      expect(find.text('Lejano'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'location is opt-in and disabled GPS gives a recoverable message',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls++;
            if (call.method == 'isLocationServiceEnabled') return false;
            throw StateError('Unexpected call: ${call.method}');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyDestinationsSection(
              destinations: const [],
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text('Ver cercanos'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
        find.text(
          'Activa la ubicación del dispositivo para calcular la distancia.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver cercanos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
