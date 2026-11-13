import 'package:flutter/material.dart';
import '../../localization/l10n.dart';
import '../../theme/app_colors.dart';

enum SkeletonLayout {
  explore,
  recommendations,
  results,
  favorites,
  notifications,
  detail,
  detailPreview,
}

class ContentSkeleton extends StatelessWidget {
  const ContentSkeleton(this.layout, {super.key});
  final SkeletonLayout layout;

  @override
  Widget build(BuildContext context) {
    final body = switch (layout) {
      SkeletonLayout.explore => [_photo(300), _bar(140), _photo(120)],
      SkeletonLayout.recommendations => [_photo(270), _photo(270)],
      SkeletonLayout.results ||
      SkeletonLayout.favorites => List.generate(4, (_) => _row(84)),
      SkeletonLayout.notifications => List.generate(5, (_) => _row(44)),
      SkeletonLayout.detailPreview => [_bar(220), _bar(130)],
      SkeletonLayout.detail => [_photo(260), _bar(180), _bar(120), _photo(120)],
    };
    return Semantics(
      liveRegion: true,
      label: context.l10n.uiCargando,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in body)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: item,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _photo(double height) => _shape(double.infinity, height, 20);
  static Widget _bar(double width) =>
      Align(alignment: Alignment.centerLeft, child: _shape(width, 12, 6));
  static Widget _shape(double width, double height, double radius) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
  static Widget _row(double width) => Row(
    children: [
      _shape(width, width, 14),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          children: [_bar(155), const SizedBox(height: 10), _bar(96)],
        ),
      ),
    ],
  );
}
