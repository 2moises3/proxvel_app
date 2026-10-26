import 'package:flutter/material.dart';
import '../../../controllers/archive_controller.dart';
import '../../../core/theme/app_colors.dart';

/// No confunde una lista aún desconocida con una lista vacía de exclusiones.
class ArchiveLoadingState extends StatelessWidget {
  const ArchiveLoadingState({super.key, required this.controller});
  final ArchiveController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.error == null || controller.isLoading) ...[
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.border,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Preparando tus destinos…', textAlign: TextAlign.center),
        ] else ...[
          const Icon(Icons.cloud_off_rounded, color: AppColors.discovery),
          const SizedBox(height: 12),
          const Text(
            'No pudimos recuperar tus destinos ocultos. Reintenta para mostrar tu selección.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: controller.loadArchives,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ],
    ),
  );
}
