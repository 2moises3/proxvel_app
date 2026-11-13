import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/destination_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../core/widgets/cards/favorite_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../core/widgets/maps/destination_location.dart';

/// Full-height cover. Image bounds remain fixed during image crossfades.
class DestinationCover extends StatefulWidget {
  const DestinationCover({
    super.key,
    required this.destination,
    this.heroTag,
    this.scrollController,
    this.selectedImageUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewCount = 0,
    required this.onOpenGallery,
    required this.onImageChanged,
  });
  final DestinationModel destination;
  final String? heroTag;
  final ScrollController? scrollController;
  final String? selectedImageUrl;
  final double? latitude, longitude, rating;
  final int reviewCount;
  final VoidCallback onOpenGallery;
  final ValueChanged<String> onImageChanged;
  @override
  State<DestinationCover> createState() => _DestinationCoverState();
}

class _DestinationCoverState extends State<DestinationCover> {
  final _coverAnchor = GlobalKey();
  final _titleAnchor = GlobalKey();
  final _stickyLimit = ValueNotifier<double>(0);

  void _measureTitle() {
    if (!mounted) return;
    final cover = _coverAnchor.currentContext?.findRenderObject();
    final title = _titleAnchor.currentContext?.findRenderObject();
    if (cover is! RenderBox || title is! RenderBox || !title.hasSize) return;
    final top = MediaQuery.paddingOf(context).top + 24;
    final titleY = title.localToGlobal(Offset.zero, ancestor: cover).dy;
    _stickyLimit.value = (titleY - top - 48 - 12).clamp(0.0, double.infinity);
  }

  @override
  void dispose() {
    _stickyLimit.dispose();
    super.dispose();
  }

  Widget _actions(BuildContext context, DestinationModel destination) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton.filled(
        tooltip: context.l10n.back,
        onPressed: () => context.canPop() ? context.pop() : context.go('/main'),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 48),
        ),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Consumer<FavoritesController>(
        builder: (context, favorites, _) {
          final selected = favorites.isFavorite(destination.id);
          return IconButton.filled(
            tooltip: selected
                ? context.l10n.removeFavorite
                : context.l10n.addFavorite,
            onPressed: favorites.isSaving(destination.id)
                ? null
                : () => toggleFavoriteWithFeedback(
                    context,
                    favorites,
                    destination.id,
                    destination,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            icon: AppIcon(
              selected ? AppIcons.heartFilled : AppIcons.heartOutline,
              color: selected ? AppColors.discovery : AppColors.textPrimary,
            ),
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final images = {
      d.imageUrl,
      ...d.galleryImages,
    }.where((e) => e.trim().isNotEmpty).toList();
    final selected = images.indexOf(widget.selectedImageUrl ?? d.imageUrl);
    final image = images.isEmpty ? '' : images[selected < 0 ? 0 : selected];
    // Intrinsic content can grow for accessibility; normal content occupies exactly one viewport.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitle());
    return Stack(
      key: _coverAnchor,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onOpenGallery,
            child: DestinationHero(
              tag: widget.heroTag,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: AdaptiveDestinationImage(
                  key: ValueKey(image),
                  imagePath: image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Colors.transparent,
                    Color(0xB3000000),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: IntrinsicHeight(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const Spacer(),
                    SizedBox(key: _titleAnchor),
                    if (d.category.isNotEmpty)
                      Text(
                        context.categoryLabel(d.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      context.destinationTitle(d.id, d.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          [
                            d.city,
                            d.region,
                          ].where((s) => s.isNotEmpty).toSet().join(' · '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.reviewCount > 0 && widget.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(
                                AppIcons.starFilled,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.rating!.toStringAsFixed(1)} (${context.l10n.reviewsCount(widget.reviewCount)})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DestinationDistance(
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                          if (images.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 64,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) => Semantics(
                                  button: true,
                                  selected: images[i] == image,
                                  label: context.l10n.photoPosition(
                                    i + 1,
                                    images.length,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      widget.onImageChanged(images[i]);
                                    },
                                    child: Container(
                                      width: 64,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: images[i] == image
                                              ? AppColors.accent
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: AdaptiveDestinationImage(
                                          imagePath: images[i],
                                          cacheWidth: 192,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        context.l10n.uiDeslizaParaDescubrirElLugar,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 24,
          left: 24,
          right: 24,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.scrollController,
              _stickyLimit,
            ]),
            builder: (context, child) {
              final scroll = widget.scrollController;
              final offset = scroll != null && scroll.hasClients
                  ? scroll.offset
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, offset.clamp(0.0, _stickyLimit.value)),
                child: child,
              );
            },
            child: _actions(context, d),
          ),
        ),
      ],
    );
  }
}
