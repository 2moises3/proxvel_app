import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public OSM layer remains replaceable; no credentials embedded in the app.
class TourismTileLayer extends StatelessWidget {
  const TourismTileLayer({super.key, this.onError, this.tileProvider});
  final VoidCallback? onError;
  final TileProvider? tileProvider;
  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.m3biznovatech.proxvel',
    maxNativeZoom: 19,
    tileProvider: tileProvider,
    errorTileCallback: (_, _, _) => onError?.call(),
  );
}

/// Kept outside floating cards so attribution is never covered by app controls.
class TourismMapAttribution extends StatelessWidget {
  const TourismMapAttribution({super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        try {
          await launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
        } catch (_) {}
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          '© OpenStreetMap',
          style: TextStyle(fontSize: 10, color: Color(0xFF374151)),
        ),
      ),
    ),
  );
}
