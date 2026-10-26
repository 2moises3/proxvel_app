import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main/main_layout.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/archive_controller.dart' as import_archive_controller;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common/app_icon.dart';
import '../../core/widgets/states/loading_view.dart';
import '../../models/destination_model.dart';
import 'widgets/favorite_destination_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isGrid = false;
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      final query = _searchCtrl.text.trim().toLowerCase();
      if (_searchQuery != query) {
        setState(() => _searchQuery = query);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final controller = context.watch<FavoritesController>();
    final archiveCtrl = context.watch<import_archive_controller.ArchiveController>();

    final allFavorites = controller.favorites
        .where((d) => !archiveCtrl.isArchived(d.id))
        .toList();

    // Extraer ciudades únicas ordenadas
    final cities = allFavorites
        .map((d) => d.city.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()..sort();

    // Filtrar por ciudad y por texto
    final filteredFavorites = allFavorites.where((d) {
      if (_selectedCity != null && d.city.trim() != _selectedCity) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final nameMatch = d.name.toLowerCase().contains(q);
        final cityMatch = d.city.toLowerCase().contains(q);
        final regionMatch = d.region.toLowerCase().contains(q);
        final catMatch = d.category.toLowerCase().contains(q);
        return nameMatch || cityMatch || regionMatch || catMatch;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(allFavorites.length),
            if (allFavorites.isNotEmpty) ...[
              _buildSearchBar(),
              if (cities.isNotEmpty) ...[
                _buildCityFilterRail(cities, allFavorites.length, allFavorites),
                const SizedBox(height: 10),
              ],
            ],
            Expanded(
              child: controller.isLoading
                  ? const LoadingView()
                  : controller.error != null
                      ? _buildErrorView(controller)
                      : allFavorites.isEmpty
                          ? _buildEmptyState()
                          : filteredFavorites.isEmpty
                              ? _buildNoSearchResults()
                              : _buildFavoritesContent(controller, filteredFavorites),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header con Título, Contador y Selector de Vista ──
  Widget _buildHeader(int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Mis Favoritos',
                      style: AppTypography.style(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.discovery.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalCount',
                          style: AppTypography.style(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.discovery,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  totalCount > 0
                      ? 'Tus destinos soñados listos para explorar'
                      : 'Tu colección personal de viajes',
                  style: AppTypography.style(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Selector de Visualización (Lista vs Cuadrícula) ──
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F4),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Lista (Opción A)
                  _buildLayoutToggleButton(
                    isSelected: !_isGrid,
                    icon: Icons.view_agenda_rounded,
                    tooltip: 'Vista en lista editorial',
                    onTap: () {
                      if (_isGrid) setState(() => _isGrid = false);
                    },
                  ),
                  const SizedBox(width: 2),
                  // Botón Cuadrícula (Opción B)
                  _buildLayoutToggleButton(
                    isSelected: _isGrid,
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Vista en cuadrícula',
                    onTap: () {
                      if (!_isGrid) setState(() => _isGrid = true);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoutToggleButton({
    required bool isSelected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  // ── Buscador Idéntico al Home (Cápsula con Ícono Primario) ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          style: AppTypography.style(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF202020),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintText: '¿A dónde quieres ir? o busca por nombre...',
            hintStyle: AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: AppIcon(
                AppIcons.search,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Filtro Horizontal por Ciudad ──
  Widget _buildCityFilterRail(
    List<String> cities,
    int totalCount,
    List<DestinationModel> allFavorites,
  ) {
    final choices = <String?>[null, ...cities];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: choices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final city = choices[i];
          final isSelected = _selectedCity == city;
          final count = city == null
              ? totalCount
              : allFavorites.where((d) => d.city.trim() == city).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedCity = city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.discovery : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? AppColors.discovery : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.discovery.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city ?? 'Todas',
                    style: AppTypography.style(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.24)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Contenido de Favoritos (Lista Editorial o Cuadrícula) ──
  Widget _buildFavoritesContent(
    FavoritesController controller,
    List<DestinationModel> favorites,
  ) {
    if (_isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, i) {
          final dest = favorites[i];
          return FavoriteDestinationCard(
            destination: dest,
            isGrid: true,
            onTap: () => context.push('/destination/${dest.id}'),
            onRemove: () => _confirmRemove(controller, dest.id, dest.name),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
      physics: const BouncingScrollPhysics(),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final dest = favorites[i];
        return SizedBox(
          height: 230,
          child: FavoriteDestinationCard(
            destination: dest,
            isGrid: false,
            onTap: () => context.push('/destination/${dest.id}'),
            onRemove: () => _confirmRemove(controller, dest.id, dest.name),
          ),
        );
      },
    );
  }

  // ── Empty State cuando no hay ningún favorito guardado ──
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.discovery.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.discovery.withValues(alpha: 0.30),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.heartFilled,
                  size: 40,
                  color: AppColors.discovery,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu lista de deseos está esperando',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Explora los destinos de PROXVEL y guarda los que más te inspiren tocando el corazón para tenerlos siempre a mano.',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                final mainLayout = MainLayout.of(context);
                context.read<HomeController>().requestTabChange(0);
                if (mainLayout != null) {
                  mainLayout.changeTab(0);
                } else {
                  context.go('/main');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      AppIcons.sparkles,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Descubrir destinos',
                      style: AppTypography.style(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── No results para la búsqueda o ciudad seleccionada ──
  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.search,
                  size: 28,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No encontramos resultados',
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCity != null && _searchQuery.isNotEmpty
                  ? 'No hay favoritos en "$_selectedCity" que coincidan con "$_searchQuery".'
                  : _selectedCity != null
                      ? 'Aún no tienes favoritos guardados en "$_selectedCity".'
                      : 'No tienes ningún favorito que coincida con "$_searchQuery".',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _selectedCity = null;
                });
              },
              child: Text(
                'Restablecer filtros',
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.discovery,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error View ──
  Widget _buildErrorView(FavoritesController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tus favoritos',
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error ?? 'Verifica tu conexión a internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modal Bottom Sheet Refinado para Confirmar Quitar de Favoritos ──
  void _confirmRemove(FavoritesController controller, String id, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.discovery.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.discovery.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.heartFilled,
                  size: 26,
                  color: AppColors.discovery,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '¿Quitar de favoritos?',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '¿Deseas quitar "$name" de tu lista? Podrás volver a guardarlo cuando quieras desde el explorador.',
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Conservar',
                        style: AppTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      controller.toggleFavorite(id);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.discovery,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.discovery.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Quitar',
                        style: AppTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
