import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/tourism_map_controller.dart';
import 'package:proxvell_app/integration/services/tourism_map_service.dart';
import 'package:proxvell_app/models/map_marker_model.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/maps/destination_location.dart';
import 'package:proxvell_app/core/widgets/maps/map_photo_pin.dart';
import 'package:proxvell_app/views/map/tourism_map_view.dart';

class _FakeTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ));
}

class _FakeLocation extends DestinationLocation {
  @override
  double? distance(double? lat, double? lon) => 5200.0;
}

class _FakeMapService extends TourismMapService {
  @override
  Future<List<MapMarkerModel>> getMapMarkers() async {
    return [
      MapMarkerModel(
        destinationId: 'dest-parque-aguas',
        destination: 'Circuito Mágico del Agua',
        latitude: -12.0694,
        longitude: -77.0345,
        category: 'Recreación',
        region: 'Lima',
        coverImageUrl: 'assets/images/auth_costa_v1.png',
      ),
      MapMarkerModel(
        destinationId: 'dest-machu-picchu',
        destination: 'Santuario de Machu Picchu',
        latitude: -13.1631,
        longitude: -72.5450,
        category: 'Arqueología',
        region: 'Cusco',
        coverImageUrl: 'assets/images/auth_sierra_v1.png',
      ),
    ];
  }
}

void main() {
  testWidgets('Fijar y desfijar destino en el mapa muestra pin y cápsula informativa', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeMapService();
    final location = _FakeLocation();
    final controller = TourismMapController(service);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TourismMapView(
              tileProvider: _FakeTiles(),
              location: location,
            ),
          ),
        ),
      ),
    );

    // Esperar carga inicial
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tocar el pin en el mapa
    final pinFinder = find.byType(MapPhotoPin).first;
    expect(pinFinder, findsOneWidget);
    await tester.tap(pinFinder);
    await tester.pump(const Duration(milliseconds: 600));

    // Debe existir el botón "Fijar en mapa"
    final fixButtonFinder = find.text('Fijar en mapa');
    expect(fixButtonFinder, findsOneWidget);

    // Tocar "Fijar en mapa"
    await tester.tap(fixButtonFinder);
    await tester.pump(const Duration(milliseconds: 600));

    // El botón debe actualizarse a "Fijado"
    expect(find.text('Fijado'), findsWidgets);

    // Debe mostrar la cápsula superior flotante
    expect(find.byIcon(Icons.push_pin_rounded), findsWidgets);

    // Desfijar tocando el botón de cerrar en la cápsula
    final closePinFinder = find.byTooltip('Desfijar destino');
    expect(closePinFinder, findsOneWidget);
    await tester.tap(closePinFinder);
    await tester.pump(const Duration(milliseconds: 600));

    // La cápsula debe desaparecer
    expect(closePinFinder, findsNothing);
  });
}
