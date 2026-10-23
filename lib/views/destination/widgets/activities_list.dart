import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class ActivitiesList extends StatelessWidget {
  final List<String> activities;

  const ActivitiesList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Qué puedes hacer?',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpace.field),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpace.card),
            itemBuilder: (context, index) {
              return _buildActivityItem(activities[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String activity) {
    final iconData = _getIconForActivity(activity);

    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpace.related),
          Text(
            activity,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForActivity(String activity) {
    final lower = activity.toLowerCase();
    if (lower.contains('caminata') || lower.contains('trekking') || lower.contains('senderismo')) return Icons.directions_walk_rounded;
    if (lower.contains('foto')) return Icons.camera_alt_outlined;
    if (lower.contains('paisaje') || lower.contains('observación')) return Icons.landscape_rounded;
    if (lower.contains('cultura') || lower.contains('historia')) return Icons.account_balance_rounded;
    if (lower.contains('investigación')) return Icons.science_outlined;
    if (lower.contains('sandboard') || lower.contains('buggy')) return Icons.downhill_skiing_rounded; // Close enough for sandboarding
    if (lower.contains('bote') || lower.contains('navegación')) return Icons.directions_boat_outlined;
    if (lower.contains('montañismo') || lower.contains('alpinismo')) return Icons.terrain_rounded;
    if (lower.contains('camping')) return Icons.campaign_outlined; // Close enough
    if (lower.contains('fauna')) return Icons.pets_rounded;
    if (lower.contains('pesca')) return Icons.phishing_rounded;
    if (lower.contains('gastro')) return Icons.restaurant_outlined;
    if (lower.contains('compras')) return Icons.shopping_bag_outlined;
    if (lower.contains('nocturna')) return Icons.nightlife_rounded;
    if (lower.contains('termales')) return Icons.hot_tub_rounded;
    if (lower.contains('entretenimiento')) return Icons.local_play_outlined;
    return Icons.explore_outlined;
  }
}
