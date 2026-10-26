import 'package:flutter/material.dart' hide SearchController;
import '../../../core/theme/app_typography.dart';
import '../../auth/widgets/auth_form_page.dart';
import '../../../controllers/search_controller.dart'
    show SearchController, SearchFilters;
import '../../../core/theme/app_colors.dart';
import '../../../models/seasonality_model.dart';

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
                      'Afina tu búsqueda',
                      style: AppTypography.style(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF202020),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar filtros',
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
                    'Lugar',
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
                          decoration: const InputDecoration(
                            labelText: 'Región',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas las regiones'),
                            ),
                            ...ctrl.availableRegions.map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _region = v),
                        ),
                      const SizedBox(height: 12),
                      _options(
                        {for (final c in ctrl.availableCategories) c: c},
                        _category,
                        (v) => setState(() => _category = v),
                      ),
                    ],
                    initiallyExpanded: true,
                  ),
                  _group(
                    'Cuándo viajar',
                    Icons.calendar_month_outlined,
                    [
                      _climate == null ? null : kClimateOptions[_climate],
                      _crowd == null ? null : kCrowdOptions[_crowd],
                    ].whereType<String>().join(' · '),
                    [
                      DropdownButtonFormField<int>(
                        initialValue: _month ?? DateTime.now().month,
                        key: ValueKey(_month),
                        decoration: const InputDecoration(
                          labelText: 'Mes de viaje',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(kMonthShort[m - 1]),
                            ),
                        ],
                        onChanged: (v) => setState(() => _month = v),
                      ),
                      const SizedBox(height: 14),
                      _label('Clima que prefieres'),
                      _options(
                        kClimateOptions,
                        _climate,
                        (v) => setState(() => _climate = v),
                      ),
                      const SizedBox(height: 14),
                      _label('Cantidad de visitantes'),
                      _options(
                        kCrowdOptions,
                        _crowd,
                        (v) => setState(() => _crowd = v),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Clima y afluencia se evalúan para ese mes con datos históricos; no son un pronóstico.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (ctrl.availableCostLevels.isNotEmpty)
                    _group(
                      'Presupuesto',
                      Icons.account_balance_wallet_outlined,
                      kCostOptions[_cost] ?? '',
                      [
                        _options(
                          {
                            for (final c in ctrl.availableCostLevels)
                              c: kCostOptions[c] ?? c,
                          },
                          _cost,
                          (v) => setState(() => _cost = v),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Nivel de gasto orientativo, no un precio de entrada.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if (ctrl.aiSortEnabled)
                    _group(
                      'Afinidad contigo',
                      Icons.auto_awesome_rounded,
                      _minCompat == null ? '' : 'Desde $_minCompat%',
                      [
                        _options(
                          {
                            for (final v in [60, 70, 80, 90]) '$v': 'Desde $v%',
                          },
                          _minCompat?.toString(),
                          (v) => setState(
                            () => _minCompat = v == null ? null : int.parse(v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Disponible cuando el motor puede usar tu perfil viajero.',
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
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthSubmitButton(
                      text: 'Aplicar',
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
        summary.isEmpty ? 'Sin restricciones' : summary,
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
