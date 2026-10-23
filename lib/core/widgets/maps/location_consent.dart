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
      title: const Text('¿Usar tu ubicación?'),
      content: const Text(
        'Usaremos tu ubicación solo para calcular qué tan lejos estás de este destino. '
        'No sale de tu teléfono y no se guarda en nuestros servidores.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Permitir')),
      ],
    ),
  );
  return ok == true;
}
