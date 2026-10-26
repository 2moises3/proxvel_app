import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/destination_model.dart';
import '../../../models/tourism_catalog_model.dart';

class KeyInfoGrid extends StatelessWidget {
  final DestinationModel destination;
  final TourismCatalogModel? tourismInfo;

  const KeyInfoGrid({super.key, required this.destination, this.tourismInfo});

  @override
  Widget build(BuildContext context) {
    final altitude = tourismInfo?.altitudeM ?? destination.altitudeM;
    final region = _pick(tourismInfo?.region, destination.region);
    final city = _pick(tourismInfo?.city, destination.city);

    // Solo se muestran los datos que existen: nada de "N/A".
    final items = <_KeyInfoItem>[
      if (altitude != null)
        _KeyInfoItem(
          icon: Icons.landscape_outlined,
          label: 'Altitud',
          value: '${altitude.toStringAsFixed(0)} m s. n. m.',
        ),
      if (region != null)
        _KeyInfoItem(
          icon: Icons.location_on_outlined,
          label: 'Región',
          value: region,
        ),
      if (city != null)
        _KeyInfoItem(
          icon: Icons.map_outlined,
          label: 'Ciudad base',
          value: city,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final target = i.isEven ? left : right;
      if (target.isNotEmpty) target.add(const SizedBox(height: AppSpace.field));
      target.add(items[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Datos del lugar', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpace.field),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 330
              ? Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      items[i],
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: left)),
                    const SizedBox(width: AppSpace.content),
                    Expanded(child: Column(children: right)),
                  ],
                ),
        ),
      ],
    );
  }

  static String? _pick(String? primary, String fallback) {
    if (primary != null && primary.trim().isNotEmpty) return primary;
    return fallback.trim().isEmpty ? null : fallback;
  }
}

class _KeyInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KeyInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpace.related),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.mutedLabel),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
