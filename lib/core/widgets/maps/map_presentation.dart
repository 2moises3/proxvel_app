import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/map_marker_model.dart';

String normalizeMapSearch(String text) {
  const source = 'áéíóúüñ';
  const target = 'aeiouun';
  var result = text.toLowerCase().trim();
  for (var i = 0; i < source.length; i++) {
    result = result.replaceAll(source[i], target[i]);
  }
  return result;
}

List<MapMarkerModel> filterMapPlaces(
  List<MapMarkerModel> places, {
  String query = '',
  String? category,
}) {
  final words = normalizeMapSearch(query).split(RegExp(r'\s+'));
  return places.where((m) {
    final text = normalizeMapSearch(
      '${m.destination} ${m.city ?? ''} ${m.region ?? ''} ${m.category ?? ''}',
    );
    return (category == null || category == m.category) &&
        words.every(text.contains);
  }).toList();
}

Uri googleMapsLocation(double latitude, double longitude) => Uri.https(
  'www.google.com',
  '/maps/search/',
  {'api': '1', 'query': '$latitude,$longitude'},
);

String mapDistanceLabel(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';

/// Group overlapping photos in screen space, never displace a destination's pin.
class MapPhotoGroup {
  MapPhotoGroup(this.items);
  final List<MapMarkerModel> items;
  LatLng get point => LatLng(
    items.fold<double>(0, (v, m) => v + m.latitude) / items.length,
    items.fold<double>(0, (v, m) => v + m.longitude) / items.length,
  );
}

List<MapPhotoGroup> groupMapPhotos(
  List<MapMarkerModel> places,
  Offset Function(LatLng) project, {
  String? selectedId,
}) {
  final groups = <MapPhotoGroup>[];
  for (final place in places.where((m) => m.destinationId != selectedId)) {
    final point = project(LatLng(place.latitude, place.longitude));
    MapPhotoGroup? near;
    for (final group in groups) {
      if ((project(group.point) - point).distance < 70) {
        near = group;
        break;
      }
    }
    if (near == null) {
      groups.add(MapPhotoGroup([place]));
    } else {
      near.items.add(place);
    }
  }
  // Last painted marker stays above the other photos.
  for (final place in places.where((m) => m.destinationId == selectedId)) {
    groups.add(MapPhotoGroup([place]));
  }
  return groups;
}
