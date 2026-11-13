import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Explica para qué se usa la ubicación ANTES del diálogo del sistema.
/// Devuelve true si ya hay permiso o el viajero acepta continuar.
Future<bool> ensureLocationConsent(BuildContext context) async {
  final current = await Geolocator.checkPermission();
  if (current == LocationPermission.whileInUse || current == LocationPermission.always) return true;
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.uiUsarTuUbicacion),
      content: Text(
        context.l10n.uiUsaremosTuUbicacionSoloParaCalcular +
        context.l10n.uiNoSaleDeTuTelefonoY,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.uiAhoraNo)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.uiPermitir)),
      ],
    ),
  );
  return ok == true;
}
