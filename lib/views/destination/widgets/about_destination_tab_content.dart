import 'destination_section_loading.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../models/destination_model.dart';
import '../../../models/tourism_catalog_model.dart';
import 'expandable_description_text.dart';
import 'map_location_preview.dart';

class AboutDestinationTabContent extends StatelessWidget {
  const AboutDestinationTabContent({
    super.key,
    required this.destination,
    this.tourismInfo,
    this.isLoading = false,
  });
  final bool isLoading;
  final DestinationModel destination;
  final TourismCatalogModel? tourismInfo;

  @override
  Widget build(BuildContext context) {
    final info = tourismInfo;
    final description = info?.description ?? destination.description;
    final facts = <({String icon, String title, String value})>[
      if (info?.recommendedDuration != null)
        (
          icon: AppIcons.clock,
          title: 'Tiempo sugerido',
          value: info!.recommendedDuration!,
        ),
      if (info?.difficultyLabel != null)
        (
          icon: AppIcons.route,
          title: 'Dificultad',
          value: info!.difficultyLabel!,
        ),
      if (info?.costLabel != null)
        (
          icon: AppIcons.wallet,
          title: 'Gasto orientativo',
          value: info!.costLabel!,
        ),
      if (info?.altitudeM != null)
        (
          icon: AppIcons.mountain,
          title: 'Altitud',
          value: '${info!.altitudeM!.round()} m s. n. m.',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Conoce el lugar', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        if (description.trim().isNotEmpty)
          ExpandableDescriptionText(text: description)
        else
          const Text(
            'Estamos preparando la descripción de este lugar. Puedes consultar los datos disponibles a continuación.',
            style: AppTextStyles.bodySecondary,
          ),
        if (isLoading) ...[
          const SizedBox(height: 24),
          const DestinationSectionLoading(
            label: 'Preparando los detalles de tu visita…',
          ),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth < 290 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.4
                  ? 1
                  : 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final fact in facts)
                    SizedBox(
                      width:
                          (constraints.maxWidth - 12 * (columns - 1)) / columns,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppIcon(
                              fact.icon,
                              color: AppColors.discovery,
                              size: 24,
                            ),
                            const SizedBox(height: 14),
                            Text(fact.value, style: AppTextStyles.cardTitle),
                            const SizedBox(height: 4),
                            Text(
                              fact.title,
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (info?.costLabel != null) ...[
            const SizedBox(height: 8),
            const Text(
              'El nivel de gasto es orientativo; no es una tarifa de entrada.',
              style: AppTextStyles.body2,
            ),
          ],
        ],
        if (info?.activitiesSummary != null) ...[
          const SizedBox(height: 28),
          const Text('Vívelo a tu manera', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Text(info!.activitiesSummary!, style: AppTextStyles.bodySecondary),
        ],
        if (info?.interestTags.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in info!.interestTags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.discovery.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    tag.isEmpty ? tag : tag[0].toUpperCase() + tag.substring(1),
                    style: const TextStyle(
                      color: AppColors.discovery,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (info?.visitorInfoSummary != null ||
            info?.howToGet != null ||
            info?.accessibilitySummary != null) ...[
          const SizedBox(height: 28),
          const Text('Antes de salir', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          if (info?.visitorInfoSummary != null)
            _DetailDisclosure(
              icon: AppIcons.info,
              title: 'Prepara tu visita',
              text: info!.visitorInfoSummary!,
              expanded: true,
            ),
          if (info?.howToGet != null)
            _DetailDisclosure(
              icon: AppIcons.route,
              title: 'Cómo llegar',
              text: info!.howToGet!,
            ),
          if (info?.accessibilitySummary != null)
            _DetailDisclosure(
              icon: AppIcons.accessibility,
              title: 'Accesibilidad',
              text: info!.accessibilitySummary!,
            ),
        ],
        if (info?.officialWebsite != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(info!.officialWebsite!);
              final valid =
                  uri != null &&
                  (uri.scheme == 'https' || uri.scheme == 'http');
              bool opened = false;
              try {
                if (valid) {
                  opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              } catch (_) {}
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No pudimos abrir el sitio oficial.'),
                  ),
                );
              }
            },
            icon: const AppIcon(
              AppIcons.externalLink,
              size: 18,
              color: AppColors.discovery,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.discovery,
              shape: const StadiumBorder(),
            ),
            label: const Text('Consultar sitio oficial'),
          ),
        ],
        const SizedBox(height: 28),
        MapLocationPreview(
          destinationName: destination.name,
          imageUrl: destination.imageUrl,
          locationLabel: [
            destination.city,
            destination.region,
          ].where((s) => s.isNotEmpty).toSet().join(' · '),
          latitude: info?.latitude ?? destination.latitude,
          longitude: info?.longitude ?? destination.longitude,
          destinationId: destination.id,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DetailDisclosure extends StatelessWidget {
  const _DetailDisclosure({
    required this.icon,
    required this.title,
    required this.text,
    this.expanded = false,
  });
  final String icon, title, text;
  final bool expanded;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.white,
        child: ExpansionTile(
          // Keep the expanded flag separate from the ancestor scroll offset.
          key: PageStorageKey('destination-info/$title'),
          initiallyExpanded: expanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          leading: AppIcon(icon, color: AppColors.discovery),
          title: Text(title, style: AppTextStyles.cardTitle),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, sentence)
                      in text.split(RegExp(r'(?<=[.!?])\s+')).indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.discovery.withValues(alpha: .08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.discovery,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sentence,
                              style: AppTextStyles.bodySecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
