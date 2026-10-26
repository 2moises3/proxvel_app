import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/tourism_map_controller.dart';
import 'package:proxvell_app/integration/api/api_client.dart';
import 'package:proxvell_app/integration/services/tourism_map_service.dart';
import 'package:proxvell_app/models/map_marker_model.dart';
import 'package:proxvell_app/core/widgets/maps/map_presentation.dart';

class MapApi extends ApiClient {
  bool failCatalog = false;
  final calls = <String>[];
  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    calls.add(endpoint);
    if (endpoint == '/tourism/catalog') {
      if (failCatalog) throw StateError('offline');
      return {
        'data': [
          {
            'destination_id': 'a',
            'city': 'Lima',
            'region': 'Lima',
            'description': 'Descripción real',
            'cover_image_url': 'https://example.com/a.jpg',
          },
        ],
      };
    }
    return {
      'data': [
        {
          'destination_id': 'a',
          'destination': 'Museo',
          'latitude': -12,
          'longitude': -77,
        },
        {'destination_id': 'bad', 'latitude': 999, 'longitude': 0},
        {'destination_id': 'missing', 'longitude': -77},
      ],
    };
  }
}

class DeferredMapService extends TourismMapService {
  final response = Completer<List<MapMarkerModel>>();
  int calls = 0;
  @override
  Future<List<MapMarkerModel>> getMapMarkers() {
    calls++;
    return response.future;
  }
}

void main() {
  test(
    'map enriches only valid public markers through two batch calls',
    () async {
      final api = MapApi();
      final service = TourismMapService(apiClient: api);
      final markers = await service.getMapMarkers();
      expect(markers, hasLength(1));
      expect(markers.single.description, 'Descripción real');
      expect(markers.single.coverImageUrl, 'https://example.com/a.jpg');
      expect(markers.single.locationLabel, 'Lima');
      expect(markers.single.rating, isNull);
      expect(api.calls, ['/tourism/map-markers', '/tourism/catalog']);
      api.failCatalog = true;
      final partial = await service.getMapMarkers();
      expect(partial, hasLength(1));
      expect(service.detailsUnavailable, isTrue);
      expect(partial.single.coverImageUrl, isNull);
    },
  );
  test(
    'concurrent routes share one load and reuse public session data',
    () async {
      final service = DeferredMapService();
      final controller = TourismMapController(service);
      final a = controller.loadMarkers();
      final b = controller.loadMarkers();
      service.response.complete([]);
      await Future.wait([a, b]);
      await controller.loadMarkers();
      expect(service.calls, 1);
      expect(controller.hasLoaded, isTrue);
      await controller.loadMarkers(refresh: true);
      expect(service.calls, 2);
      controller.dispose();
    },
  );
  test(
    'search normalizes accents, combines category and groups exact coordinates',
    () {
      final places = [
        MapMarkerModel(
          destinationId: 'a',
          destination: 'Museo de Sitio',
          latitude: -12,
          longitude: -77,
          category: 'Museo',
          region: 'Áncash',
        ),
        MapMarkerModel(
          destinationId: 'b',
          destination: 'Sitio B',
          latitude: -12,
          longitude: -77,
          category: 'Arqueología',
        ),
      ];
      expect(
        filterMapPlaces(places, query: 'museo ancash').single.destinationId,
        'a',
      );
      expect(
        filterMapPlaces(places, query: 'ancash', category: 'Arqueología'),
        isEmpty,
      );
      final grouped = groupMapPhotos(places, (_) => Offset.zero);
      expect(grouped.single.items, hasLength(2));
      expect(
        groupMapPhotos(places, (_) => Offset.zero, selectedId: 'b'),
        hasLength(2),
      );
      final uri = googleMapsLocation(-12, -77);
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['query'], '-12.0,-77.0');
      expect(mapDistanceLabel(850), '850 m');
    },
  );
}
