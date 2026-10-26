import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../models/destination_model.dart';

class CategoryDestinationBrowser extends StatefulWidget {
  const CategoryDestinationBrowser({
    super.key,
    required this.destinations,
    required this.onOpen,
    required this.onCategory,
    required this.onAll,
  });
  final List<DestinationModel> destinations;
  final ValueChanged<DestinationModel> onOpen;
  final ValueChanged<String> onCategory;
  final VoidCallback onAll;
  @override
  State<CategoryDestinationBrowser> createState() =>
      _CategoryDestinationBrowserState();
}

class _CategoryDestinationBrowserState
    extends State<CategoryDestinationBrowser> {
  String? _selected;
  final _categoriesScroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    _categoriesScroll.dispose();
    super.dispose();
  }

  String _scene(String category) => switch (category.toLowerCase()) {
    'arqueología' => 'history',
    'museo' => 'academic',
    'naturaleza' => 'nature',
    'recreación' => 'family',
    _ => 'culture',
  };
  @override
  Widget build(BuildContext context) {
    final categories = widget.destinations
        .map((d) => d.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (categories.isEmpty) return const SizedBox.shrink();
    final selected = categories.contains(_selected) ? _selected : null;
    final choices = <String?>[null, ...categories];
    final matches = widget.destinations
        .where((d) => selected == null || d.category.trim() == selected)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sigue tu curiosidad',
          style: AppTypography.style(fontSize: 26, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige una categoría y descubre sus destinos.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 64,
          child: ListView.separated(
            key: const ValueKey('home-categories-rail'),
            controller: _categoriesScroll,
            primary: false,
            padding: const EdgeInsets.all(1),
            scrollDirection: Axis.horizontal,
            itemCount: choices.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = choices[i];
              return Semantics(
                selected: c == selected,
                button: true,
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: c == selected
                          ? AppColors.discovery
                          : AppColors.border,
                      width: c == selected ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    key: ValueKey('home-category-${c ?? 'Todos'}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selected = c),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c == null)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    (c == selected
                                            ? AppColors.discovery
                                            : const Color(0xFFF3F4F6))
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.discovery,
                                size: 22,
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/onboarding_${_scene(c)}_scene.webp',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                cacheWidth: 132,
                              ),
                            ),
                          const SizedBox(width: 9),
                          Text(
                            c ?? 'Todos',
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: c == selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: c == selected
                                  ? AppColors.discovery
                                  : const Color(0xFF202020),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        DestinationPortraitRail(
          key: ValueKey(selected),
          destinations: matches.take(5).toList(),
          onOpen: widget.onOpen,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                selected == null ? widget.onAll() : widget.onCategory(selected),
            child: Text(
              'Ver ${selected ?? 'todos'} (${matches.length}) →',
              style: const TextStyle(color: AppColors.discovery),
            ),
          ),
        ),
      ],
    );
  }
}

class DestinationPortraitRail extends StatefulWidget {
  const DestinationPortraitRail({
    super.key,
    required this.destinations,
    required this.onOpen,
  });
  final List<DestinationModel> destinations;
  final ValueChanged<DestinationModel> onOpen;
  @override
  State<DestinationPortraitRail> createState() =>
      _DestinationPortraitRailState();
}

class _DestinationPortraitRailState extends State<DestinationPortraitRail> {
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        230 +
        (MediaQuery.textScalerOf(context).scale(15) - 15).clamp(0, 15) * 5,
    child: ListView.separated(
      controller: _scroll,
      primary: false,
      scrollDirection: Axis.horizontal,
      itemCount: widget.destinations.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final d = widget.destinations[i];
        return SizedBox(
          width: 165,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => widget.onOpen(d),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 134,
                    width: 165,
                    child: AdaptiveDestinationImage(
                      imagePath: d.imageUrl,
                      cacheWidth: 500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Text(
                      d.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: Text(
                      d.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
