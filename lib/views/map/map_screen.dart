import 'package:flutter/material.dart';
import 'tourism_map_view.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) => TourismMapView(embedded: embedded);
}
