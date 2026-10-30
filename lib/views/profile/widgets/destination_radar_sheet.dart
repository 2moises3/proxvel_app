import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/visit_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/maps/destination_location.dart';
import '../../../integration/services/tourism_map_service.dart';
import '../../../models/map_marker_model.dart';
import '../../../models/visit_model.dart';

/// Modal interactivo de escaneo por Radar GPS:
/// Emula un sonar con ondas concéntricas y barrido rotatorio que
/// detecta destinos turísticos peruanos próximos para marcarlos como objetivo de sellado.
class DestinationRadarSheet extends StatefulWidget {
  final VoidCallback? onTargetSelected;

  const DestinationRadarSheet({super.key, this.onTargetSelected});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DestinationRadarSheet(),
    );
  }

  @override
  State<DestinationRadarSheet> createState() => _DestinationRadarSheetState();
}

class _DestinationRadarSheetState extends State<DestinationRadarSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _isScanning = true;
  List<MapMarkerModel> _nearbyDestinations = [];
  MapMarkerModel? _selectedTarget;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _performScan();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _performScan() async {
    setState(() {
      _isScanning = true;
      _statusText = '🛰️ Calibrando sensores GPS y buscando destinos...';
    });

    final mapService = context.read<TourismMapService>();
    final location = DestinationLocation.shared;
    await location.locate(requestPermission: true);
    if (!mounted) return;
    if (location.position == null) {
      setState(() {
        _isScanning = false;
        _nearbyDestinations = [];
        _selectedTarget = null;
        _statusText =
            location.error ??
            'Activa la ubicación para buscar destinos cerca de ti.';
      });
      return;
    }

    try {
      final markers = await mapService.getMapMarkers();
      if (!mounted) return;

      // Dejar que la animación de radar gire al menos 2 segundos para dar la experiencia visual
      await Future.delayed(const Duration(milliseconds: 2100));
      if (!mounted) return;

      // Ordenar por distancia desde la ubicación real del dispositivo.
      final withDistance = markers.map((m) {
        final dist = location.distance(m.latitude, m.longitude)!;
        return _MarkerDistance(m, dist);
      }).toList()..sort((a, b) => a.distance.compareTo(b.distance));

      if (mounted) {
        setState(() {
          _isScanning = false;
          _nearbyDestinations = withDistance.map((e) => e.marker).toList();
          _selectedTarget = _nearbyDestinations.isNotEmpty
              ? _nearbyDestinations.first
              : null;
          _statusText = _selectedTarget != null
              ? 'Destinos cercanos a tu ubicación actual'
              : 'No hay destinos con ubicación disponible.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = 'No pudimos completar el escaneo GPS.';
        });
      }
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null) return 'Distancia calculándose';
    if (meters < 1000) return 'A ${meters.toInt()} metros de ti';
    return 'A ${(meters / 1000).toStringAsFixed(1)} km de ti';
  }

  @override
  Widget build(BuildContext context) {
    final location = DestinationLocation.shared;
    final distance = _selectedTarget != null
        ? location.distance(
            _selectedTarget!.latitude,
            _selectedTarget!.longitude,
          )
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Barra de agarre superior
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título de cabecera
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.screen,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar de Destinos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Búsqueda activa de sellado por GPS',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Vista del Sonar animado ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _RadarPainter(
                              progress: _animCtrl.value,
                              isScanning: _isScanning,
                              hasTarget: _selectedTarget != null,
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Texto de estado
                  Text(
                    _statusText ?? 'Escaneando...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isScanning
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isScanning && location.position == null)
                    TextButton.icon(
                      onPressed: _performScan,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Reintentar ubicación'),
                    ),

                  const SizedBox(height: 16),

                  // ── Tarjeta del destino detectado ──
                  if (!_isScanning && _selectedTarget != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.screen,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final marker in _nearbyDestinations)
                            ChoiceChip(
                              label: Text(marker.destination),
                              selectedColor: AppColors.accentSoft,
                              backgroundColor: AppColors.surface,
                              labelStyle: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                              selected:
                                  marker.destinationId ==
                                  _selectedTarget!.destinationId,
                              onSelected: (_) =>
                                  setState(() => _selectedTarget = marker),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.screen,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.near_me_rounded,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDistance(distance),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedTarget!.region != null)
                                  Text(
                                    _selectedTarget!.region!.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedTarget!.destination,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Radio: ${_selectedTarget!.geofenceRadiusMeters} m · Permanencia: ${_selectedTarget!.minDwellMinutes} min',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                distance <=
                                        _selectedTarget!.geofenceRadiusMeters
                                    ? 'Estás dentro del radio de este destino.'
                                    : 'Aún estás fuera del radio de este destino.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Botón de Fijar como Objetivo
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final visitCtrl = context
                                      .read<VisitController>();
                                  final pending = PendingSealDestination(
                                    destinationId:
                                        _selectedTarget!.destinationId,
                                    destinationName:
                                        _selectedTarget!.destination,
                                    latitude: _selectedTarget!.latitude,
                                    longitude: _selectedTarget!.longitude,
                                    region: _selectedTarget!.region,
                                    coverImageUrl:
                                        _selectedTarget!.coverImageUrl,
                                    distanceMeters: distance,
                                    geofenceRadiusMeters:
                                        _selectedTarget!.geofenceRadiusMeters,
                                    minDwellMinutes:
                                        _selectedTarget!.minDwellMinutes,
                                  );
                                  visitCtrl.setPendingDestination(pending);
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '🎯 ${_selectedTarget!.destination} marcado como objetivo de sellado.',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(
                                  Icons.track_changes_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Fijar como objetivo de sellado',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerDistance {
  final MapMarkerModel marker;
  final double distance;
  _MarkerDistance(this.marker, this.distance);
}

/// CustomPainter que dibuja el sonar, anillos de onda y barrido circular
class _RadarPainter extends CustomPainter {
  final double progress;
  final bool isScanning;
  final bool hasTarget;

  _RadarPainter({
    required this.progress,
    required this.isScanning,
    required this.hasTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Círculos concéntricos de referencia
    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4.0);
      canvas.drawCircle(center, r, linePaint);
    }

    // Líneas en cruz (coordenadas)
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      linePaint,
    );

    // Onda concéntrica expansiva pulsante
    final waveRadius = maxRadius * progress;
    final waveOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
    final wavePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: waveOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, waveRadius, wavePaint);

    // Barrido rotatorio de sonar si está escaneando
    if (isScanning) {
      final angle = progress * 2 * math.pi;
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi / 2,
          colors: [
            AppColors.accent.withValues(alpha: 0.0),
            AppColors.accent.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: maxRadius),
        0.0,
        math.pi / 2,
        true,
        sweepPaint,
      );
      canvas.restore();
    }

    // Punto objetivo detectado ("blip")
    if (hasTarget && !isScanning) {
      final blipOffset = Offset(
        center.dx + maxRadius * 0.52,
        center.dy - maxRadius * 0.42,
      );
      final blipPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipOffset, 6.0, blipPaint);

      final blipHalo = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(blipOffset, 12.0, blipHalo);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.hasTarget != hasTarget;
  }
}
