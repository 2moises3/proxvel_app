import '../../../core/theme/app_layout.dart';
import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/recommendation_controller.dart';
import '../../../controllers/archive_controller.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cards/destination_recommendation_card.dart';
import '../../../core/widgets/states/empty_profile_for_ai_state.dart';
import 'month_fan_picker.dart';
import 'archive_loading_state.dart';
import 'recommendation_motion.dart';
import '../../../core/widgets/states/content_skeleton.dart';

class HomeForYouContent extends StatefulWidget {
  const HomeForYouContent({super.key});
  @override
  State<HomeForYouContent> createState() => _HomeForYouContentState();
}

class _HomeForYouContentState extends State<HomeForYouContent>
    with AutomaticKeepAliveClientMixin {
  final _entered = <String>{};
  int _revision = -1;
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<RecommendationController>();
    final archives = context.watch<ArchiveController>();
    if (_revision != controller.resultsRevision) {
      _revision = controller.resultsRevision;
      _entered.clear();
    }
    final eligible = controller.recommendations
        .where((r) => r.isEligible)
        .toList();
    final items = eligible
        .where((r) => !archives.isArchived(r.destination.id))
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          archives.loadArchives(),
          controller.loadRecommendations(forceRefresh: true),
        ]);
      },
      color: AppColors.discovery,
      child: CustomScrollView(
        key: const PageStorageKey('for-you-scroll'),
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => context.push('/profile/preferences'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.discovery,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 19),
                          label: Text(context.l10n.editPreferences),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MonthFanPicker(
                        month: controller.selectedMonth,
                        onChanged: controller.setMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.placesForYou,
                    style: AppTypography.style(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: const Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    !archives.hasLoaded
                        ? context.l10n.restoringSelection
                        : controller.isLoading
                        ? context.l10n.matchingPreferences
                        : context.l10n.placeCount(items.length),
                    style: AppTypography.style(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.isLoading && items.isNotEmpty)
                    const LinearProgressIndicator(minHeight: 2),
                  if (items.isNotEmpty &&
                      controller.resultsMonth !=
                          (controller.selectedMonth ?? DateTime.now().month))
                    Text(
                      context.l10n.previousMonthResults(
                        context.fullMonth(
                          controller.resultsMonth ?? DateTime.now().month,
                        ),
                      ),
                    ),
                  if (archives.hasLoaded && archives.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        context.errorText(archives.error!),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (!archives.hasLoaded)
                    ArchiveLoadingState(controller: archives)
                  else if (controller.profileIncomplete)
                    const EmptyProfileForAiState()
                  else if (controller.error != null)
                    _message(
                      controller.connectionUnavailable
                          ? context.l10n.connectionUnavailable
                          : context.errorText(controller.error!),
                      context.l10n.retry,
                      () => controller.loadRecommendations(forceRefresh: true),
                    )
                  else if (!controller.isLoading && items.isEmpty)
                    _message(
                      eligible.isNotEmpty
                          ? context.l10n.allMatchesHidden
                          : context.l10n.noMatchesForPreferences,
                      eligible.isNotEmpty
                          ? context.l10n.viewArchived
                          : context.l10n.editPreferences,
                      () => context.push(
                        eligible.isNotEmpty
                            ? '/archived'
                            : '/profile/preferences',
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (controller.isLoading && items.isEmpty && archives.error == null)
            const SliverToBoxAdapter(
              child: ContentSkeleton(SkeletonLayout.recommendations),
            ),
          if (archives.hasLoaded &&
              items.isNotEmpty &&
              !controller.profileIncomplete)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final rec = items[index];
                  final entryKey =
                      '${controller.resultsRevision}/${rec.destination.id}';
                  final animate = _entered.add(entryKey);
                  return RecommendationArrival(
                    key: ValueKey(entryKey),
                    index: index,
                    animate: animate,
                    child: DestinationRecommendationCard(
                      recommendation: rec,
                      onTap: () {
                        final month =
                            controller.resultsMonth ?? controller.selectedMonth;
                        context.push(
                          '/destination/${Uri.encodeComponent(rec.destination.id)}?source=ai_recommendation${month == null ? '' : '&month=$month'}',
                          extra: DestinationOpening(
                            rec.destination,
                            'recommendation',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              AppSizing.navigationClearance(context),
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (archives.hasLoaded && items.isNotEmpty) ...[
                    Text(
                      context.l10n.historicalConditions,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/archived'),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: Text(context.l10n.hiddenPlaces),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.discovery,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, String action, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
