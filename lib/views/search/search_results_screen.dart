import '../../core/theme/app_typography.dart';
import '../../core/navigation/destination_opening.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/search_controller.dart'
    show SearchController, SearchFilters;
import '../../controllers/profile_controller.dart';
import '../../controllers/archive_controller.dart' as import_archive_controller;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/states/loading_view.dart';
import '../../core/widgets/states/proxvel_empty_state.dart';
import 'widgets/search_result_card.dart';
import 'widgets/search_filter_sheet.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String? initialCategory;
  final bool autoOpenFilters;

  const SearchResultsScreen({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
    this.autoOpenFilters = false,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _queryCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Asegura que el perfil esté cargado para poder gatear el orden IA.
      final profileCtrl = context.read<ProfileController>();
      if (profileCtrl.profile == null) await profileCtrl.loadProfileData();
      if (!mounted) return;

      final ctrl = context.read<SearchController>();
      ctrl.search(
        newFilters: SearchFilters(
          query: widget.initialQuery,
          category: widget.initialCategory,
        ),
        aiSort: profileCtrl.profile?.applyAiGlobally ?? false,
        hasProfile: profileCtrl.profile?.isRecommendationReady == true,
      );

      if (widget.autoOpenFilters) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
        if (mounted) _openFilters();
      }
    });
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  bool get _hasProfile =>
      context.read<ProfileController>().profile?.isRecommendationReady == true;

  void _onSearch() {
    final ctrl = context.read<SearchController>();
    ctrl.search(
      newFilters: ctrl.filters.copyWith(query: _queryCtrl.text.trim()),
      aiSort: ctrl.aiSortEnabled,
      hasProfile: _hasProfile,
    );
  }

  void _onToggleAiSort(bool value) {
    final ctrl = context.read<SearchController>();
    ctrl.search(
      newFilters: ctrl.filters.copyWith(query: _queryCtrl.text.trim()),
      aiSort: value,
      hasProfile: _hasProfile,
    );
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final ctrl = context.read<SearchController>();
    final selected = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .88,
        child: SearchFilterSheet(controller: ctrl),
      ),
    );
    if (!mounted || selected == null) return;
    ctrl.search(
      newFilters: selected.copyWith(query: _queryCtrl.text.trim()),
      aiSort: ctrl.aiSortEnabled,
      hasProfile: _hasProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final ctrl = context.watch<SearchController>();
    final archiveCtrl = context
        .watch<import_archive_controller.ArchiveController>();

    final filteredResults = ctrl.results
        .where((r) => !archiveCtrl.isArchived(r.destination.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(ctrl),
          Expanded(
            child: ctrl.isLoading
                ? const LoadingView()
                : ctrl.error != null
                ? ProxvelEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'No pudimos cargar los destinos',
                    subtitle: ctrl.error!,
                    actionLabel: 'Reintentar',
                    onAction: () => ctrl.search(
                      hasProfile: _hasProfile,
                      aiSort: ctrl.aiSortEnabled,
                    ),
                  )
                : filteredResults.isEmpty
                ? ProxvelEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Sin resultados',
                    subtitle: ctrl.filters.hasActiveFilters
                        ? 'Prueba ajustando tus filtros\npara encontrar más destinos.'
                        : 'No encontramos destinos que\ncoincidan con tu búsqueda.',
                    actionLabel: ctrl.filters.hasActiveFilters
                        ? 'Limpiar filtros'
                        : null,
                    onAction: ctrl.filters.hasActiveFilters
                        ? () => ctrl.clearFilters()
                        : null,
                  )
                : _buildResultsList(ctrl, filteredResults),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SearchController ctrl) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Volver',
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Hero(
                    tag: 'home_search_bar_hero',
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      child: TextField(
                        controller: _queryCtrl,
                        onSubmitted: (_) => _onSearch(),
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        style: AppTypography.style(
                          fontSize: 15,
                          color: const Color(0xFF202020),
                        ),
                        decoration: InputDecoration(
                          hintText: '¿A dónde quieres ir?',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: AppTypography.style(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: IconButton(
                            tooltip: 'Buscar',
                            onPressed: _onSearch,
                            icon: const Icon(Icons.search_rounded, size: 21),
                          ),
                          suffixIcon: _queryCtrl.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Borrar búsqueda',
                                  onPressed: () {
                                    _queryCtrl.clear();
                                    _onSearch();
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 19,
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: const BorderSide(
                              color: Color(0xFFDBDBD7),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: const BorderSide(
                              color: Color(0xFFDBDBD7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: const BorderSide(
                              color: AppColors.discovery,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Hero(
                  tag: 'home_filter_button_hero',
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton.filled(
                      tooltip: 'Filtros',
                      onPressed: _openFilters,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: const Color(0xFF202020),
                        minimumSize: const Size(52, 52),
                      ),
                      icon: Badge(
                        isLabelVisible: ctrl.filters.activeFilterCount > 0,
                        backgroundColor: AppColors.discovery,
                        label: Text('${ctrl.filters.activeFilterCount}'),
                        child: const Icon(Icons.tune_rounded, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ctrl.availableCategories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final category = i == 0
                      ? null
                      : ctrl.availableCategories[i - 1];
                  return ChoiceChip(
                    label: Text(category ?? 'Todos'),
                    selected: ctrl.filters.category == category,
                    showCheckmark: false,
                    selectedColor: AppColors.discovery,
                    backgroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: AppTypography.style(
                      fontSize: 13,
                      color: ctrl.filters.category == category
                          ? Colors.white
                          : const Color(0xFF202020),
                    ),
                    onSelected: (_) => ctrl.search(
                      newFilters: ctrl.filters.copyWith(
                        category: category,
                        clearCategory: category == null,
                        query: _queryCtrl.text.trim(),
                      ),
                      aiSort: ctrl.aiSortEnabled,
                      hasProfile: _hasProfile,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.discovery,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ordenar para mí',
                    style: AppTypography.style(
                      fontSize: 14,
                      color: const Color(0xFF202020),
                    ),
                  ),
                ),
                Switch(
                  value: ctrl.aiSortEnabled,
                  activeTrackColor: AppColors.discovery,
                  activeThumbColor: Colors.white,
                  onChanged: _onToggleAiSort,
                ),
              ],
            ),
            if (ctrl.aiBlockedNoProfile)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Completa tus preferencias para usar el orden por IA.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/preferences'),
                    child: const Text('Completar'),
                  ),
                ],
              ),
            if (ctrl.filters.hasActiveFilters)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ctrl.filters.activeFilterCount} filtros activos',
                      style: AppTypography.style(
                        fontSize: 12,
                        color: AppColors.discovery,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ctrl.clearFilters(),
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    SearchController ctrl,
    List<dynamic> filteredResults,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            16,
            AppSpace.screen,
            8,
          ),
          child: Text(
            '${filteredResults.length} destino${filteredResults.length != 1 ? 's' : ''} encontrado${filteredResults.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              4,
              AppSpace.screen,
              24,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredResults.length,
            itemBuilder: (_, i) {
              final item = filteredResults[i];
              final source = ctrl.aiSortEnabled ? 'ai_search' : 'search';
              return SearchResultCard(
                item: item,
                onTap: () => context.push(
                  '/destination/${item.destination.id}?source=$source&month=${ctrl.filters.month ?? DateTime.now().month}',
                  extra: DestinationOpening(item.destination, 'search'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
