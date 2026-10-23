import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/cards/stats_card.dart';

/// Fila de estadísticas del perfil: favoritos, reseñas y recomendaciones.
class ProfileStatsRow extends StatelessWidget {
  final int favoritesCount;
  final int reviewsCount;
  final int recommendationsCount;

  const ProfileStatsRow({
    super.key,
    required this.favoritesCount,
    required this.reviewsCount,
    required this.recommendationsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 20, AppSpace.screen, 0),
      child: Row(
        children: [
          StatsCard(
            icon: Icons.favorite_rounded,
            value: '$favoritesCount',
            label: 'Favoritos',
          ),
          const SizedBox(width: AppSpace.content),
          StatsCard(
            icon: Icons.rate_review_rounded,
            value: '$reviewsCount',
            label: 'Reseñas',
          ),
          const SizedBox(width: AppSpace.content),
          StatsCard(
            icon: Icons.auto_awesome_rounded,
            value: '$recommendationsCount',
            label: 'Para ti',
          ),
        ],
      ),
    );
  }
}
