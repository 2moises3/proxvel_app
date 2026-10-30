import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../common/app_icon.dart';

/// Location stays in memory. Only the invitation's dismissal date is persisted.
class DestinationLocation extends ChangeNotifier {
  static final shared = DestinationLocation();
  Position? position;
  DateTime? measuredAt;
  bool busy = false;
  String? error;
  bool needsSettings = false;
  bool serviceDisabled = false;
  Future<void> openSettingsAndRetry() async {
    try {
      if (needsSettings) {
        await Geolocator.openAppSettings();
      } else {
        await Geolocator.openLocationSettings();
      }
    } catch (_) {
      error = kIsWeb
          ? 'En tu navegador, haz clic en el ícono a la izquierda de la URL y activa "Permitir ubicación".'
          : 'Abre los ajustes de ubicación de tu dispositivo. Después, vuelve a pulsar para actualizar.';
    }
    needsSettings = false;
    serviceDisabled = false;
    notifyListeners();
  }

  Future<void> locate({bool requestPermission = true}) async {
    if (busy) return;
    busy = true;
    position = null;
    measuredAt = null;
    error = null;
    needsSettings = false;
    serviceDisabled = false;
    notifyListeners();
    try {
      bool isEnabled = true;
      try {
        isEnabled = await Geolocator.isLocationServiceEnabled().timeout(
          const Duration(seconds: 6),
        );
      } on TimeoutException {
        rethrow;
      } catch (_) {
        isEnabled = !kIsWeb ? false : true;
      }
      if (!isEnabled && !kIsWeb) {
        serviceDisabled = true;
        throw 'Activa la ubicación del dispositivo para calcular la distancia.';
      }
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 6),
      );
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 15),
        );
      }
      if (permission == LocationPermission.deniedForever) {
        needsSettings = true;
        throw kIsWeb
            ? 'La ubicación está bloqueada en tu navegador. Haz clic en el ícono a la izquierda de la URL y activa "Permitir ubicación".'
            : 'Puedes permitir la ubicación desde los ajustes de la app o del dispositivo.';
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (requestPermission) {
          throw 'Puedes seguir explorando sin compartir tu ubicación.';
        }
        return;
      }
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: kIsWeb ? LocationAccuracy.low : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      ).timeout(const Duration(seconds: 22));
      measuredAt = DateTime.now();
    } catch (e) {
      position = null;
      measuredAt = null;
      error = e is String
          ? e
          : e is TimeoutException
          ? 'La ubicación tardó demasiado. Comprueba el GPS y vuelve a intentarlo.'
          : 'No pudimos obtener tu ubicación. Inténtalo otra vez.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  double? distance(double? lat, double? lon) {
    final p = position;
    if (p == null ||
        lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      return null;
    }
    return Geolocator.distanceBetween(p.latitude, p.longitude, lat, lon);
  }
}

class LocationInvitationPolicy {
  static const key = 'location_invitation_dismissed_day';
  static String day(DateTime date) => '${date.year}-${date.month}-${date.day}';
  static bool shouldShow(String? dismissed, DateTime now) =>
      dismissed != day(now);
}

/// Root portal keeps the invitation above the floating navigation island.
class LocationInvitation extends StatefulWidget {
  const LocationInvitation({super.key});
  @override
  State<LocationInvitation> createState() => _LocationInvitationState();
}

class _LocationInvitationState extends State<LocationInvitation> {
  static String? _shownDay;
  final _portal = OverlayPortalController();
  bool _hideToday = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (_shownDay == LocationInvitationPolicy.day(DateTime.now())) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!LocationInvitationPolicy.shouldShow(
        prefs.getString(LocationInvitationPolicy.key),
        DateTime.now(),
      )) {
        return;
      }
      final permission = await Geolocator.checkPermission();
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        return;
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      _shownDay = LocationInvitationPolicy.day(DateTime.now());
      _portal.show();
    } catch (_) {
      /* Location is optional; plugin errors must not block home. */
    }
  }

  Future<void> _close(bool activate) async {
    _portal.hide();
    if (_hideToday) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LocationInvitationPolicy.key,
        LocationInvitationPolicy.day(DateTime.now()),
      );
    }
    if (activate) {
      await DestinationLocation.shared.locate();
      if (mounted && DestinationLocation.shared.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DestinationLocation.shared.error!),
            action:
                DestinationLocation.shared.needsSettings ||
                    DestinationLocation.shared.serviceDisabled
                ? SnackBarAction(
                    label: 'Ajustes',
                    onPressed: () {
                      DestinationLocation.shared.openSettingsAndRetry();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayLocation: OverlayChildLocation.rootOverlay,
    overlayChildBuilder: (context) => Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFEBECEF),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.discovery.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.discovery.withValues(
                                alpha: 0.22,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.mapPin,
                              size: 26,
                              color: AppColors.discovery,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _close(false),
                          tooltip: 'Cerrar',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Quizá tu próxima escapada esté cerca.',
                      style: AppTypography.style(
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Activa tu ubicación para descubrir destinos cercanos y ver qué tan lejos estás de cada lugar.',
                      style: AppTypography.style(
                        fontSize: 14.5,
                        height: 1.45,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: AppIcon(
                              AppIcons.info,
                              size: 16,
                              color: AppColors.discovery,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Es opcional. La distancia se calcula en tu dispositivo y no se envía al motor de recomendaciones. Si registras una visita en tu Atlas, enviamos tu ubicación al servidor para verificarla.',
                              style: AppTypography.style(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _hideToday = !_hideToday),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _hideToday,
                                onChanged: (v) =>
                                    setState(() => _hideToday = v ?? true),
                                activeColor: AppColors.discovery,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF9CA3AF),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'No volver a mostrar hoy',
                              style: AppTypography.style(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () => _close(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          shape: const StadiumBorder(),
                          elevation: 0,
                          textStyle: AppTypography.style(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppIcon(
                              AppIcons.compass,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Activar ubicación'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _close(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: AppTypography.style(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Seguir explorando'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class DestinationDistance extends StatefulWidget {
  const DestinationDistance({super.key, this.latitude, this.longitude});
  final double? latitude;
  final double? longitude;
  @override
  State<DestinationDistance> createState() => _DestinationDistanceState();
}

class _DestinationDistanceState extends State<DestinationDistance> {
  final location = DestinationLocation.shared;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          (location.measuredAt == null ||
              DateTime.now().difference(location.measuredAt!).inMinutes >= 5)) {
        location.locate(requestPermission: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: location,
    builder: (context, _) {
      final meters = location.distance(widget.latitude, widget.longitude);
      final valid =
          widget.latitude != null &&
          widget.longitude != null &&
          widget.latitude!.isFinite &&
          widget.longitude!.isFinite &&
          widget.latitude!.abs() <= 90 &&
          widget.longitude!.abs() <= 180;
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !valid
                      ? 'Ubicación por confirmar'
                      : meters == null
                      ? '¿Qué tan cerca estás?'
                      : meters < 1000
                      ? 'A unos ${meters.round()} m de ti'
                      : 'A unos ${(meters / 1000).toStringAsFixed(1)} km de ti',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.error ??
                      (!valid
                          ? 'Este destino aún no tiene coordenadas disponibles.'
                          : meters == null
                          ? 'Activa tu ubicación para ver la distancia.'
                          : 'Distancia en línea recta · aproximada'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: location.needsSettings || location.serviceDisabled
                ? 'Abrir ajustes de ubicación'
                : meters == null
                ? 'Activar ubicación'
                : 'Actualizar distancia',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: !valid || location.busy
                ? null
                : () async {
                    if (location.needsSettings) {
                      await location.openSettingsAndRetry();
                    } else if (location.serviceDisabled) {
                      await location.openSettingsAndRetry();
                    } else {
                      await location.locate();
                    }
                  },
            icon: location.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const AppIcon(AppIcons.mapPin, color: AppColors.textPrimary),
          ),
        ],
      );
    },
  );
}
