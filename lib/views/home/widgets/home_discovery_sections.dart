import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../models/destination_model.dart';
import '../../../models/recommendation_result_model.dart';

/// Secciones de Explorar construidas únicamente con el catálogo y el motor.
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
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      1.6,
    );
    if (destinations.isEmpty) return const SizedBox.shrink();
    final available = {for (final d in destinations) d.id: d};
    final personal = recommendations
        .where((r) => available.containsKey(r.destination.id))
        .take(5)
        .toList();
    final discovery =
        (destinations.length > 5 ? destinations.skip(3) : destinations)
            .take(3)
            .toList();
    final cover =
        (destinations.length > 6 ? destinations.skip(6) : destinations)
            .where((d) => d.imageUrl.isNotEmpty)
            .firstOrNull;
    final grouped = <String, List<DestinationModel>>{};
    for (final destination in destinations) {
      final category = destination.category.trim();
      if (category.isEmpty) continue;
      grouped.putIfAbsent(category, () => []).add(destination);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.auto_awesome_rounded,
          title: 'Recomendado para ti',
          subtitle: personal.isEmpty
              ? 'Descubre una selección a tu medida'
              : 'Elegidos según tus intereses',
          onSeeMore: onOpenForYou,
        ),
        const SizedBox(height: AppSpace.content),
        if (personal.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: _RecommendationInvitation(onTap: onOpenForYou),
          )
        else
          SizedBox(
            height: 154 * textScale,
            child: ListView.separated(
              key: const ValueKey('home-recommendations'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              itemCount: personal.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpace.content),
              itemBuilder: (_, index) {
                final rec = personal[index];
                final destination = available[rec.destination.id]!;
                return _RecommendationCard(
                  destination: destination,
                  onTap: () => onOpenRecommendation != null
                      ? onOpenRecommendation!(destination)
                      : onOpenDestination(destination),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpace.group),
        _SectionHeader(
          icon: Icons.explore_outlined,
          title: 'Para descubrir',
          onSeeMore: onOpenCatalog,
        ),
        const SizedBox(height: AppSpace.content),
        SizedBox(
          height: 148 * textScale,
          child: ListView.separated(
            key: const ValueKey('home-discovery'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            itemCount: discovery.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => _DiscoveryCard(
              destination: discovery[index],
              onTap: () => onOpenDestination(discovery[index]),
            ),
          ),
        ),
        if (cover != null) ...[
          const SizedBox(height: AppSpace.section),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: _FeatureCard(
              destination: cover,
              onTap: () => onOpenDestination(cover),
            ),
          ),
        ],
        for (final entry in grouped.entries) ...[
          const SizedBox(height: AppSpace.group),
          _SectionHeader(
            icon: _categoryIcon(entry.key),
            title: entry.key,
            onSeeMore: () => onOpenCategory(entry.key),
          ),
          const SizedBox(height: AppSpace.content),
          SizedBox(
            height: 186 * textScale,
            child: ListView.separated(
              key: ValueKey('home-category-${entry.key}'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              itemCount: entry.value.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _CategoryCard(
                destination: entry.value[index],
                onTap: () => onOpenDestination(entry.value[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'arqueología':
      return Icons.account_balance_outlined;
    case 'naturaleza':
      return Icons.park_outlined;
    case 'museo':
      return Icons.museum_outlined;
    case 'recreación':
      return Icons.waves_outlined;
    default:
      return Icons.place_outlined;
  }
}

String _location(DestinationModel destination) => [
  destination.city,
  destination.region,
].where((part) => part.trim().isNotEmpty).join(', ');

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onSeeMore,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.accent),
        const SizedBox(width: AppSpace.related),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onSeeMore,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9C6500),
            minimumSize: const Size(64, 44),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text('Ver más  →', style: AppTextStyles.smallBody),
        ),
      ],
    ),
  );
}

class _RecommendationInvitation extends StatelessWidget {
  const _RecommendationInvitation({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.card),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            Icon(Icons.explore_outlined, color: AppColors.accent),
            SizedBox(width: AppSpace.content),
            Expanded(
              child: Text(
                'Descubre tus recomendaciones',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.destination, required this.onTap});
  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 258,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 104,
                height: double.infinity,
                child: AdaptiveDestinationImage(
                  imagePath: destination.imageUrl,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _location(destination),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    _CategoryLabel(destination.category),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.destination, required this.onTap});
  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 230,
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                  child: SizedBox(
                    width: 83,
                    height: double.infinity,
                    child: AdaptiveDestinationImage(
                      imagePath: destination.imageUrl,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _location(destination),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    _CategoryLabel(destination.category),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.destination, required this.onTap});
  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primaryDark,
    borderRadius: BorderRadius.circular(19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height:
            194 *
            (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AdaptiveDestinationImage(imagePath: destination.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xE6000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EN PORTADA',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    destination.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: AppSpace.micro),
                  Text(
                    _location(destination),
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 11),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 8,
                      ),
                      child: Text(
                        'Descubrir  →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.destination, required this.onTap});
  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 172,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 84,
                width: 172,
                child: AdaptiveDestinationImage(
                  imagePath: destination.imageUrl,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 9, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _location(destination),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel(this.category);
  final String category;

  @override
  Widget build(BuildContext context) {
    if (category.trim().isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
