import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../main/main_layout.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/cards/destination_card.dart';
import '../../core/widgets/states/loading_view.dart';
import '../../core/widgets/states/proxvel_empty_state.dart';
import '../../controllers/archive_controller.dart' as import_archive_controller;
import '../../models/destination_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final controller = context.watch<FavoritesController>();
    final archiveCtrl = context.watch<import_archive_controller.ArchiveController>();

    final filteredFavorites = controller.favorites
        .where((d) => !archiveCtrl.isArchived(d.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(filteredFavorites.length),
          Expanded(
            child: controller.isLoading
                ? const LoadingView()
                : controller.error != null
                ? ProxvelEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'No pudimos cargar tus favoritos',
                    subtitle: controller.error!,
                    actionLabel: 'Reintentar',
                    onAction: controller.loadFavorites,
                  )
                : filteredFavorites.isEmpty
                ? ProxvelEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Aún no tienes favoritos',
                    subtitle:
                        'Explora destinos y guarda los que más\nte gusten tocando el corazón.',
                    actionLabel: 'Explorar destinos',
                    onAction: () {
                      final mainLayout = MainLayout.of(context);
                      // Solicitar al HomeController que vuelva a la pestaña 0 (Explorar)
                      context.read<HomeController>().requestTabChange(0);
                      
                      if (mainLayout != null) {
                        mainLayout.changeTab(0);
                      } else {
                        context.go('/main');
                      }
                    },
                  )
                : _buildFavoritesList(controller, filteredFavorites),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 24, AppSpace.screen, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis Favoritos',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: AppSpace.micro),
                    Text(
                      count > 0
                          ? '$count destino${count > 1 ? 's' : ''} guardado${count > 1 ? 's' : ''}'
                          : 'Tu colección personal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textOnDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesController controller, List<DestinationModel> filteredFavorites) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 155 / 200,
      ),
      itemCount: filteredFavorites.length,
      itemBuilder: (context, i) {
        final dest = filteredFavorites[i];
        return Stack(
          children: [
            Positioned.fill(
              child: DestinationCard(
                destination: dest,
                showFavoriteButton: false,
                onTap: () => context.push('/destination/${dest.id}'),
              ),
            ),
            // ── Remove button ──
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _confirmRemove(controller, dest.id, dest.name),
                child: Container(
                   width: 44,
                   height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemove(FavoritesController controller, String id, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 16, AppSpace.screen, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpace.section),
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppSpace.field),
            Text(
              '¿Quitar "$name" de favoritos?',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpace.related),
            const Text(
              'Podrás volver a agregarlo cuando quieras.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.section),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.content),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      controller.toggleFavorite(id);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Quitar',
                        style: TextStyle(
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
