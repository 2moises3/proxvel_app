import '../../../core/theme/app_layout.dart';
import 'category_destination_browser.dart';
import 'nearby_destinations_section.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../models/destination_model.dart';
import '../../../models/recommendation_result_model.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF626870);
TextStyle _type(
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
}) => AppTypography.style(
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: 1.25,
);

/// Varied editorial layouts, backed exclusively by the live catalogue.
class HomeDiscoverySections extends StatelessWidget {
  const HomeDiscoverySections({
    super.key,
    required this.destinations,
    required this.recommendations,
    required this.onOpenForYou,
    required this.onOpenDestination,
    this.onOpenRecommendation,
    required this.onOpenCategory,
    required this.onOpenCatalog,
  });
  final List<DestinationModel> destinations;
  final List<RecommendationResultModel> recommendations;
  final VoidCallback onOpenForYou;
  final ValueChanged<DestinationModel> onOpenDestination;
  final ValueChanged<DestinationModel>? onOpenRecommendation;
  final ValueChanged<String> onOpenCategory;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) return const SizedBox.shrink();
    final available = {for (final d in destinations) d.id: d};
    final personal = recommendations
        .where((r) => available.containsKey(r.destination.id))
        .firstOrNull;
    final discovery =
        (destinations.length > 5 ? destinations.skip(5) : destinations)
            .take(3)
            .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('Para descubrir', onOpenCatalog),
          const SizedBox(height: 4),
          Text(
            'Un lugar puede cambiar tus planes.',
            style: _type(14, color: _muted),
          ),
          const SizedBox(height: 16),
          DestinationPortraitRail(
            destinations: discovery,
            onOpen: onOpenDestination,
          ),
          const SizedBox(height: AppSpace.group),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.discovery.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.discovery,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recomendado para ti',
                        style: _type(17, weight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  personal == null
                      ? 'Tu forma de viajar, tu próxima historia.'
                      : 'Una pista para tu próxima escapada.',
                  style: _type(24, weight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                if (personal != null)
                  InkWell(
                    onTap: () => (onOpenRecommendation ?? onOpenDestination)(
                      available[personal.destination.id]!,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 64,
                              height: 72,
                              child: AdaptiveDestinationImage(
                                imagePath: available[personal.destination.id]!
                                    .imageUrl,
                                cacheWidth: 200,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              available[personal.destination.id]!.name,
                              style: _type(15, weight: FontWeight.w500),
                            ),
                          ),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 18,
                            color: AppColors.discovery,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'Explora recomendaciones según tus preferencias en Para ti.',
                    style: _type(15, color: _muted),
                  ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onOpenForYou,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.discovery,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Ir a Para ti  →',
                    style: _type(
                      15,
                      color: AppColors.discovery,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.group),
          NearbyDestinationsSection(
            destinations: destinations,
            onOpen: onOpenDestination,
          ),
          const SizedBox(height: AppSpace.group),
          CategoryDestinationBrowser(
            destinations: destinations,
            onOpen: onOpenDestination,
            onCategory: onOpenCategory,
            onAll: onOpenCatalog,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onOpenCatalog,
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              minimumSize: const Size(double.infinity, 56),
              shape: const StadiumBorder(),
              side: const BorderSide(color: Color(0xFFDBDBD7)),
            ),
            child: Text(
              'Explorar todos los destinos  ↗',
              style: _type(15, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String title, VoidCallback onTap) => Row(
    children: [
      Expanded(
        child: Text(title, style: _type(26, weight: FontWeight.w500)),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: AppColors.discovery),
        child: Text(
          'Ver todos',
          style: _type(14, color: AppColors.discovery, weight: FontWeight.w500),
        ),
      ),
    ],
  );
}
