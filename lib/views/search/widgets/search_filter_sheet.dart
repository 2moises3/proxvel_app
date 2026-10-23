import 'package:flutter/material.dart' hide SearchController;
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../controllers/search_controller.dart' show SearchController, SearchFilters;
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.card),

            // Title row
            Row(
              children: [
                const Text(
                  'Filtrar resultados',
                  style: AppTextStyles.sectionTitle,
                ),
                const Spacer(),
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
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.section),

            // Solo se muestran los filtros que tienen datos reales detrás: no hay
            // costos ni clima por destino en el backend, y regiones/categorías
            // aparecen únicamente si ya están cargadas.
            if (ctrl.availableRegions.isNotEmpty) ...[
              _sectionLabel('Región'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.availableRegions
                    .map((r) => _filterChip(r, _region == r, () {
                          setState(() => _region = _region == r ? null : r);
                        }))
                    .toList(),
              ),
              const SizedBox(height: AppSpace.card),
            ],

            if (ctrl.availableCategories.isNotEmpty) ...[
              _sectionLabel('Categoría'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.availableCategories
                    .map((c) => _filterChip(c, _category == c, () {
                          setState(() => _category = _category == c ? null : c);
                        }))
                    .toList(),
              ),
              const SizedBox(height: AppSpace.card),
            ],

            // ── Clima y afluencia del mes (datos de la tesis: clima 1991-2020 y llegadas históricas) ──
            _sectionLabel('Mes de viaje'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  _filterChip(kMonthShort[m - 1], (_month ?? DateTime.now().month) == m, () {
                    setState(() => _month = m);
                  }),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Se usa para los filtros de clima y afluencia.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpace.card),

            _sectionLabel('Clima favorable para'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kClimateOptions.entries
                  .map((e) => _filterChip(e.value, _climate == e.key, () {
                        setState(() => _climate = _climate == e.key ? null : e.key);
                      }))
                  .toList(),
            ),
            const SizedBox(height: AppSpace.card),

            _sectionLabel('Afluencia'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCrowdOptions.entries
                  .map((e) => _filterChip(e.value, _crowd == e.key, () {
                        setState(() => _crowd = _crowd == e.key ? null : e.key);
                      }))
                  .toList(),
            ),
            const SizedBox(height: AppSpace.card),

            // El costo solo aparece cuando ya hay destinos con nivel de costo cargado.
            if (ctrl.availableCostLevels.isNotEmpty) ...[
              _sectionLabel('Gasto de visita (estimado)'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.availableCostLevels
                    .map((c) => _filterChip(kCostOptions[c] ?? c, _cost == c, () {
                          setState(() => _cost = _cost == c ? null : c);
                        }))
                    .toList(),
              ),
              const SizedBox(height: AppSpace.card),
            ],

            // La compatibilidad solo existe con el orden por IA activado.
            if (ctrl.aiSortEnabled) ...[
              // ── Afinidad mínima ──
              _sectionLabel('Afinidad mínima'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [60, 70, 80, 90]
                    .map((v) => _filterChip('≥ $v%', _minCompat == v,
                        () => setState(() => _minCompat = _minCompat == v ? null : v)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 28),

            // ── Apply button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: GestureDetector(
                onTap: () {
                  final newFilters = SearchFilters(
                    query: ctrl.filters.query,
                    region: _region,
                    category: _category,
                    minCompatibility: _minCompat,
                    climate: _climate,
                    crowd: _crowd,
                    month: _month,
                    costLevel: _cost,
                  );
                  ctrl.search(newFilters: newFilters);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Aplicar filtros',
                    style: AppTextStyles.cardTitleOnDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
