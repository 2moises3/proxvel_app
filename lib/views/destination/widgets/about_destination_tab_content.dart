import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/destination_model.dart';
import '../../../models/tourism_catalog_model.dart';
import '../../../core/theme/app_colors.dart';
import 'expandable_description_text.dart';
import 'activities_list.dart';
import 'key_info_grid.dart';
import 'map_location_preview.dart';
import 'practical_info_card.dart';

class AboutDestinationTabContent extends StatelessWidget {
  final DestinationModel destination;
  final TourismCatalogModel? tourismInfo;

  const AboutDestinationTabContent({
    super.key,
    required this.destination,
    this.tourismInfo,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    void add(Widget child) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpace.section));
      }
      sections.add(child);
    }

    final description = tourismInfo?.description ?? destination.description;
    if (description.trim().isNotEmpty) {
      add(
        _section('Qué te espera', ExpandableDescriptionText(text: description)),
      );
    }
    final activities = tourismInfo?.activitiesSummary;
    if (activities != null && activities.trim().isNotEmpty) {
      add(
        _section(
          'Qué puedes hacer',
          Text(activities, style: AppTextStyles.bodySecondary),
        ),
      );
    } else if (destination.activities.isNotEmpty) {
      add(ActivitiesList(activities: destination.activities));
    }
    if (tourismInfo?.interestTags.isNotEmpty == true) {
      add(
        _section(
          'Ideal si te interesa',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tourismInfo!.interestTags)
                Chip(
                  label: Text(_capitalize(tag)),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  labelStyle: AppTextStyles.smallLabel,
                ),
            ],
          ),
        ),
      );
    }
    if (tourismInfo != null &&
        (tourismInfo!.costLabel != null ||
            tourismInfo!.recommendedDuration != null ||
            tourismInfo!.howToGet != null ||
            tourismInfo!.visitorInfoSummary != null ||
            tourismInfo!.officialWebsite != null)) {
      add(PracticalInfoCard(info: tourismInfo));
    }
    final accessibility = tourismInfo?.accessibilitySummary;
    if (accessibility != null && accessibility.trim().isNotEmpty) {
      add(
        _section(
          'Accesibilidad',
          Text(accessibility, style: AppTextStyles.bodySecondary),
        ),
      );
    }
    add(KeyInfoGrid(destination: destination, tourismInfo: tourismInfo));
    add(
      MapLocationPreview(
        latitude: tourismInfo?.latitude ?? destination.latitude,
        longitude: tourismInfo?.longitude ?? destination.longitude,
        destinationId: destination.id,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _section(String title, Widget body) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.sectionTitle),
      const SizedBox(height: AppSpace.content),
      body,
    ],
  );

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
