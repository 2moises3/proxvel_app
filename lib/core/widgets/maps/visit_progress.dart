import 'package:flutter/material.dart';
import '../../../controllers/visit_controller.dart';
import '../../../models/visit_model.dart';
import '../../localization/l10n.dart';
import '../../theme/app_layout.dart';
import 'destination_location.dart';

Future<void> finishVisit(
  BuildContext context,
  VisitController controller,
  DestinationLocation location,
  VisitModel visit,
) async {
  await location.locate();
  if (!context.mounted) return;
  final point = location.position;
  final radius = (visit.geofenceRadiusMeters ?? 250).toDouble();
  if (point == null || location.tooImpreciseFor(radius)) {
    _showLocationIssue(context, location, radius);
    return;
  }
  final ok = await controller.verifyActiveVisit(
    latitude: point.latitude,
    longitude: point.longitude,
  );
  if (!context.mounted) return;
  _message(
    context,
    ok
        ? context.l10n.uiTuVisitaHaSidoSelladaCon
        : context.errorText(
            controller.error ?? '',
            fallback: context.l10n.stampVisitError,
          ),
  );
}

void _showLocationIssue(
  BuildContext context,
  DestinationLocation location,
  double radius,
) {
  final l10n = context.l10n;
  _message(
    context,
    location.tooImpreciseFor(radius)
        ? l10n.locationImprecise
        : location.message(context, fallback: l10n.enableLocationForVisit),
    action: location.needsSettings || location.serviceDisabled
        ? SnackBarAction(
            label: l10n.uiAbrirAjustesDeUbicacion,
            onPressed: location.openSettingsAndRetry,
          )
        : null,
  );
}

void _message(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
}

class VisitProgress extends StatelessWidget {
  const VisitProgress({
    super.key,
    required this.controller,
    required this.location,
    required this.destinationId,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  final VisitController controller;
  final DestinationLocation location;
  final String destinationId;
  final double latitude, longitude;
  final int radius;

  Future<void> _start(BuildContext context) async {
    await location.locate();
    if (!context.mounted) return;
    final point = location.position;
    if (point == null || location.tooImpreciseFor(radius.toDouble())) {
      _showLocationIssue(context, location, radius.toDouble());
      return;
    }
    final ok = await controller.startCheckIn(
      destinationId: destinationId,
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!context.mounted || ok) return;
    _message(
      context,
      context.errorText(
        controller.error ?? '',
        fallback: context.l10n.visitStartError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visit = controller.activeVisit;
    final blocked = controller.isActionLoading || location.busy;
    if (visit != null && visit.isInProgress) {
      if (visit.destinationId != destinationId) return const SizedBox.shrink();
      if (visit.progress < 1) {
        return Text(
          l10n.visitRemaining(visit.remainingMinutes),
          style: Theme.of(context).textTheme.bodySmall,
        );
      }
      return FilledButton(
        onPressed: blocked
            ? null
            : () => finishVisit(context, controller, location, visit),
        child: Text(l10n.uiSellarVisita),
      );
    }
    if (controller.latestStampedDestinationId == destinationId) {
      return Text(
        l10n.visitStamped,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final distance = location.distance(latitude, longitude);
    final imprecise = location.tooImpreciseFor(radius.toDouble());
    if (distance == null || imprecise) {
      return TextButton(
        onPressed: blocked
            ? null
            : () async {
                await location.retry();
                if (context.mounted &&
                    (location.issue != null || location.error != null)) {
                  _showLocationIssue(context, location, radius.toDouble());
                }
              },
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizing.touchTarget),
        ),
        child: Text(imprecise ? l10n.retry : l10n.enableLocationForVisit),
      );
    }
    if (distance > radius) {
      return Text(
        l10n.visitApproach,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return FilledButton(
      onPressed: blocked ? null : () => _start(context),
      child: Text(l10n.visitStart),
    );
  }
}
