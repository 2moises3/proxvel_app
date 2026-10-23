import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Acceso al mapa real, sin representar una ilustración como si fuera un mapa.
class MapLocationPreview extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? destinationId;

  const MapLocationPreview({
    super.key,
    this.latitude,
    this.longitude,
    this.destinationId,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = latitude != null && longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpace.content),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: hasCoordinates
                ? () => context.push(destinationId == null
                    ? '/map'
                    : '/map/destination/$destinationId')
                : null,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCoordinates
                        ? Icons.map_outlined
                        : Icons.location_off_outlined,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpace.content),
                  Expanded(
                    child: Text(
                      hasCoordinates
                          ? 'Ver ubicación en el mapa'
                          : 'Ubicación geográfica no disponible',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasCoordinates)
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
