import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart' hide SearchController;
import '../../../core/theme/app_typography.dart';
import '../../auth/widgets/auth_form_page.dart';
import '../../../controllers/search_controller.dart'
    show SearchController, SearchFilters;
import '../../../core/theme/app_colors.dart';

/// Bottom sheet with visual filter chips for search refinement.
class SearchFilterSheet extends StatefulWidget {
  final SearchController controller;

  const SearchFilterSheet({super.key, required this.controller});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late String? _region;
  late String? _category;
  late int? _minCompat;
  late String? _climate;
  late String? _crowd;
  late int? _month;
  late String? _cost;

  @override
  void initState() {
    super.initState();
    final f = widget.controller.filters;
    _region = f.region;
    _category = f.category;
    _minCompat = f.minCompatibility;
    _climate = f.climate;
    _crowd = f.crowd;
    _month = f.month;
    _cost = f.costLevel;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final l10n = context.l10n;
    final climates = {
      'frio': l10n.cold,
      'templado': l10n.mild,
      'calido': l10n.warm,
      'seco': l10n.dry,
    };
    final crowds = {'Bajo': l10n.quiet, 'Medio': l10n.moderateCrowds, 'Alto': l10n.busy};
    final costs = {'bajo': l10n.low, 'medio': l10n.medium, 'alto': l10n.high};
    return Material(
      color: const Color(0xFFFAFAF8),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.refineSearch,
                      style: AppTypography.style(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF202020),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.closeFilters,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _group(
                    context.l10n.place,
                    Icons.place_outlined,
                    [_region, _category].whereType<String>().join(' · '),
                    [
                      if (ctrl.availableRegions.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: ctrl.availableRegions.contains(_region)
                              ? _region
                              : null,
                          key: ValueKey(_region),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.l10n.region,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(context.l10n.allRegions),
                            ),
                            ...ctrl.availableRegions.map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _region = v),
                        ),
                      const SizedBox(height: 12),
                      _options(
                        {for (final c in ctrl.availableCategories) c: context.categoryLabel(c)},
                        _category,
                        (v) => setState(() => _category = v),
                      ),
                    ],
                    initiallyExpanded: true,
                  ),
                  _group(
                    context.l10n.whenToTravel,
                    Icons.calendar_month_outlined,
                    [
                      climates[_climate],
                      crowds[_crowd],
                    ].whereType<String>().join(' · '),
                    [
                      DropdownButtonFormField<int>(
                        initialValue: _month ?? DateTime.now().month,
                        key: ValueKey(_month),
                        decoration: InputDecoration(
                          labelText: context.l10n.travelMonth,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(context.shortMonth(m)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _month = v),
                      ),
                      const SizedBox(height: 14),
                      _label(context.l10n.preferredWeather),
                      _options(
                        climates,
                        _climate,
                        (v) => setState(() => _climate = v),
                      ),
                      const SizedBox(height: 14),
                      _label(context.l10n.visitorCount),
                      _options(
                        crowds,
                        _crowd,
                        (v) => setState(() => _crowd = v),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.weatherFilterNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (ctrl.availableCostLevels.isNotEmpty)
                    _group(
                      context.l10n.budget,
                      Icons.account_balance_wallet_outlined,
                      costs[_cost] ?? '',
                      [
                        _options(
                          {
                            for (final c in ctrl.availableCostLevels)
                              c: costs[c] ?? c,
                          },
                          _cost,
                          (v) => setState(() => _cost = v),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.estimatedSpending,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if (ctrl.aiSortEnabled)
                    _group(
                      context.l10n.yourMatch,
                      Icons.auto_awesome_rounded,
                      _minCompat == null ? '' : context.l10n.fromPercent(_minCompat!),
                      [
                        _options(
                          {
                            for (final v in [60, 70, 80, 90]) '$v': context.l10n.fromPercent(v),
                          },
                          _minCompat?.toString(),
                          (v) => setState(
                            () => _minCompat = v == null ? null : int.parse(v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.matchAvailable,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _region = null;
                      _category = null;
                      _minCompat = null;
                      _climate = null;
                      _crowd = null;
                      _month = null;
                      _cost = null;
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.discovery,
                    ),
                    child: Text(context.l10n.clear),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthSubmitButton(
                      text: context.l10n.apply,
                      onPressed: () => Navigator.pop(
                        context,
                        SearchFilters(
                          query: ctrl.filters.query,
                          region: _region,
                          category: _category,
                          minCompatibility: ctrl.aiSortEnabled
                              ? _minCompat
                              : null,
                          climate: _climate,
                          crowd: _crowd,
                          month: _month,
                          costLevel: _cost,
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
    );
  }

  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: AppTypography.style(fontSize: 15, fontWeight: FontWeight.w500),
    ),
  );

  Widget _group(
    String title,
    IconData icon,
    String summary,
    List<Widget> children, {
    bool initiallyExpanded = false,
  }) => Theme(
    data: Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
      hoverColor: AppColors.discovery.withValues(alpha: .06),
      splashColor: AppColors.discovery.withValues(alpha: .08),
      highlightColor: Colors.transparent,
      listTileTheme: ListTileTheme.of(context).copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      leading: Icon(icon, color: AppColors.discovery, size: 22),
      title: Text(
        title,
        style: AppTypography.style(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF202020),
        ),
      ),
      subtitle: Text(
        summary.isEmpty ? context.l10n.uiSinRestricciones : summary,
        style: AppTypography.style(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ],
    ),
  );

  Widget _options(
    Map<String, String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: options.entries
        .map(
          (e) => FilterChip(
            label: Text(e.value),
            selected: selected == e.key,
            onSelected: (_) => onChanged(selected == e.key ? null : e.key),
            shape: const StadiumBorder(),
            selectedColor: AppColors.discovery,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            labelStyle: AppTypography.style(
              fontSize: 13,
              color: selected == e.key ? Colors.white : const Color(0xFF202020),
            ),
          ),
        )
        .toList(),
  );
}
