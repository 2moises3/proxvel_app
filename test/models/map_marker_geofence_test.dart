import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/models/map_marker_model.dart';

void main() {
  test('el marcador usa el radio y la permanencia del catálogo', () {
    final marker = MapMarkerModel(
      destinationId: 'parque_reserva',
      destination: 'Parque de la Reserva',
      latitude: -12.0694,
      longitude: -77.0346,
    ).withCatalog({'geofence_radius_meters': 25000, 'min_dwell_minutes': 1});

    expect(marker.geofenceRadiusMeters, 25000);
    expect(marker.minDwellMinutes, 1);
    expect(marker.toJson()['geofence_radius_meters'], 25000);
  });
}
