import 'package:flutter/material.dart';
import 'tourism_map_view.dart';

class DestinationMapScreen extends StatelessWidget {
  const DestinationMapScreen({super.key, required this.destinationId});
  final String destinationId;
  @override
  Widget build(BuildContext context) =>
      TourismMapView(destinationId: destinationId);
}
