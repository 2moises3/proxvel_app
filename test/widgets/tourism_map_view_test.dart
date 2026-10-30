import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/tourism_map_controller.dart';
import 'package:proxvell_app/integration/services/tourism_map_service.dart';
import 'package:proxvell_app/models/map_marker_model.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/maps/destination_location.dart';
import 'package:proxvell_app/core/widgets/maps/map_photo_pin.dart';
import 'package:proxvell_app/views/map/tourism_map_view.dart';
import '../render/destination_redesign_test.dart' show snapshot;

class NoNetworkTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );
}

class MapData extends TourismMapService {
  int loads = 0;
  bool fail = false;
  @override
  Future<List<MapMarkerModel>> getMapMarkers() async {
    loads++;
    if (fail) throw StateError('offline');
    return [
      MapMarkerModel(
        destinationId: 'lima',
        destination: 'Museo de Lima',
        latitude: -12.11,
        longitude: -77.03,
        category: 'Museo',
        region: 'Lima',
        description: 'Una descripción del catálogo.',
        coverImageUrl: 'assets/images/auth_costa_v1.png',
      ),
      MapMarkerModel(
        destinationId: 'cusco',
        destination: 'Lugar de Cusco',
        latitude: -13.25,
        longitude: -72.26,
        category: 'Arqueología',
        region: 'Cusco',
      ),
      MapMarkerModel(
        destinationId: 'paracas',
        destination: 'Lugar de Paracas',
        latitude: -13.86,
        longitude: -76.25,
        category: 'Naturaleza',
        region: 'Ica',
      ),
    ];
  }
}

class MapLocation extends DestinationLocation {
  final calls = <bool>[];
  @override
  Future<void> locate({bool requestPermission = true}) async {
    calls.add(requestPermission);
    if (!requestPermission) return;
    position = Position(
      latitude: -12.1,
      longitude: -77.02,
      timestamp: DateTime.now(),
      accuracy: 30,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    notifyListeners();
  }
}

class RetryMapLocation extends DestinationLocation {
  bool enabled = false;
  int attempts = 0;

  @override
  Future<void> locate({bool requestPermission = true}) async {
    if (!requestPermission) return;
    attempts++;
    busy = true;
    position = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (enabled) {
      position = Position(
        latitude: -12.1,
        longitude: -77.02,
        timestamp: DateTime.now(),
        accuracy: 30,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      error = null;
    } else {
      error = 'Activa la ubicación del dispositivo para calcular la distancia.';
    }
    busy = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('permite reintentar distancia tras activar ubicación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = RetryMapLocation();
    final controller = TourismMapController(MapData());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: TourismMapView(
            tileProvider: NoNetworkTiles(),
            location: location,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MapPhotoPin).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mi distancia'));
    await tester.pumpAndSettle();
    expect(location.attempts, 1);
    expect(find.text('Ver mi distancia'), findsOneWidget);
    location.enabled = true;
    await tester.tap(find.text('Ver mi distancia'));
    await tester.pumpAndSettle();
    expect(location.attempts, 2);
    expect(find.textContaining('en línea recta'), findsOneWidget);
  });

  testWidgets(
    'map filters, selects a photo, shows GPS and navigates to destination',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = MapData();
      final location = MapLocation();
      final controller = TourismMapController(service);
      addTearDown(controller.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => TourismMapView(
              tileProvider: NoNetworkTiles(),
              location: location,
            ),
          ),
          GoRoute(
            path: '/destination/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Detalle ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(location.calls, [
        false,
      ], reason: 'Opening the atlas does not request GPS permission');
      expect(find.text('Todos'), findsOneWidget);
      expect(find.byType(MapPhotoPin), findsNWidgets(3));
      await tester.enterText(find.byType(TextField), 'no existe');
      await tester.pumpAndSettle();
      expect(find.text('Probemos otra búsqueda'), findsOneWidget);
      expect(find.byType(MapPhotoPin), findsNothing);
      await tester.tap(find.text('Ver todos los destinos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Museo'));
      await tester.pumpAndSettle();
      expect(find.byType(MapPhotoPin), findsOneWidget);
      await tester.tap(find.byType(MapPhotoPin));
      await tester.pumpAndSettle();
      expect(find.text('Museo de Lima'), findsOneWidget);
      expect(find.text('Google Maps'), findsOneWidget);
      await tester.tap(find.text('Ver mi distancia'));
      await tester.pumpAndSettle();
      expect(location.calls, [false, true]);
      expect(find.textContaining('en línea recta'), findsOneWidget);
      expect(find.bySemanticsLabel('Tu ubicación aproximada'), findsOneWidget);
      await tester.tap(find.byTooltip('Ver detalle de Museo de Lima'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle lima'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(service.loads, 1);
      expect(find.text('Museo de Lima'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'focused map stays on destination, and compact/large text controls remain usable',
    (tester) async {
      final font = FontLoader('Outfit');
      for (final w in ['Regular', 'Medium', 'SemiBold']) {
        font.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$w.ttf'));
      }
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [
        const Size(390, 844),
        const Size(320, 640),
        const Size(640, 360),
      ]) {
        tester.view.physicalSize = size;
        final location = MapLocation();
        final controller = TourismMapController(MapData());
        final capture = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: controller,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(size.width == 320 ? 1.6 : 1),
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: capture,
                child: TourismMapView(
                  key: ValueKey(size),
                  destinationId: 'cusco',
                  tileProvider: NoNetworkTiles(),
                  location: location,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MapPhotoPin), findsOneWidget);
        expect(find.text('Lugar de Cusco'), findsOneWidget);
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(map.mapController!.camera.zoom, 13);
        final offset = map.mapController!.camera.latLngToScreenOffset(
          const LatLng(-13.25, -72.26),
        );
        expect(offset.dy, lessThan(size.height / 2));
        if (size.width == 390) {
          await snapshot(tester, capture, 'map-focused-layout-fixture');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      }
    },
  );
  testWidgets(
    'failed map request is retryable, missing destination has an honest state',
    (tester) async {
      final data = MapData()..fail = true;
      final controller = TourismMapController(data);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            home: TourismMapView(
              destinationId: 'missing',
              tileProvider: NoNetworkTiles(),
              location: MapLocation(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Volvamos a intentarlo'), findsOneWidget);
      data.fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Ubicación no disponible'), findsOneWidget);
      expect(find.byType(MapPhotoPin), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
