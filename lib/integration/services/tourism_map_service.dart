import 'package:flutter/foundation.dart';
import '../../models/map_marker_model.dart';
import '../api/api_client.dart';

class TourismMapService {
  final ApiClient? _api;

  TourismMapService({ApiClient? apiClient}) : _api = apiClient;
  bool detailsUnavailable = false;

  Future<List<MapMarkerModel>> getMapMarkers() async {
    if (_api == null) {
      debugPrint(
        '[TourismMapService] ApiClient is null, returning empty markers',
      );
      return [];
    }

    try {
      detailsUnavailable = false;
      final responses = await Future.wait([
        _api.get('/tourism/map-markers'),
        _api.get('/tourism/catalog').catchError((Object _) {
          detailsUnavailable = true;
          return <String, dynamic>{'data': <dynamic>[]};
        }),
      ]);
      final response = responses[0];
      final catalog = <String, Map<String, dynamic>>{
        for (final item
            in (responses[1]['data'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          if (item['destination_id'] is String)
            item['destination_id'] as String: item,
      };
      final dataList = response['data'] as List<dynamic>?;

      if (dataList != null) {
        return dataList
            .whereType<Map<String, dynamic>>()
            .where((e) => e['latitude'] is num && e['longitude'] is num)
            .map(MapMarkerModel.fromJson)
            .where((m) => m.destinationId.isNotEmpty && m.hasValidCoordinates)
            .map(
              (m) => catalog[m.destinationId] == null
                  ? m
                  : m.withCatalog(catalog[m.destinationId]!),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[TourismMapService] Error fetching map markers: $e');
      throw Exception('Failed to load map markers.');
    }
  }
}
