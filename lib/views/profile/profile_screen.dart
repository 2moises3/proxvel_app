import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../controllers/my_reviews_controller.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats_row.dart';
import 'widgets/preferences_summary_card.dart';
import 'widgets/profile_menu_section.dart';
import 'widgets/about_proxvel_sheet.dart';
import 'widgets/logout_confirm_sheet.dart';
import '../../core/utils/avatar_picker_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().loadProfileData();
      final auth = context.read<AuthController>();
      context.read<MyReviewsController>().loadUserReviews(auth.currentUser);
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    await pickAndUploadAvatar(context);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final auth = context.watch<AuthController>();
    final profileCtrl = context.watch<ProfileController>();
    final favCount = context.select<FavoritesController, int>(
      (c) => c.favorites.length,
    );
    final reviewCount = context.select<MyReviewsController, int>(
      (c) => c.reviews.length,
    );
    final recCount = context.select<RecommendationController, int>(
      (c) => c.recommendations.length,
    );

    final user = auth.currentUser ?? profileCtrl.user;
    final userName = user?.fullName ?? 'Viajero';
    final userEmail = user?.email ?? 'sin correo registrado';
    final profile = profileCtrl.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (profileCtrl.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.accent,
                backgroundColor: Colors.transparent,
              ),
            ProfileHeader(
              name: userName,
              email: userEmail,
              avatarUrl: user?.avatarUrl,
              onTapAvatar: _pickAndUploadAvatar,
              onEditProfile: () => context.push('/profile/edit'),
            ),

            if (profileCtrl.error != null) _ErrorBanner(profileCtrl.error!),
            if (profileCtrl.isShowingCachedProfile)
              _ErrorBanner(
                'Estás viendo preferencias guardadas en este dispositivo. Conéctate y actualiza antes de editarlas.',
              ),

            ProfileStatsRow(
              favoritesCount: favCount,
              reviewsCount: reviewCount,
              recommendationsCount: recCount,
            ),

            if (profile != null) ...[
              const SizedBox(height: AppSpace.section),
              PreferencesSummaryCard(profile: profile),
            ],

            const SizedBox(height: AppSpace.section),
            ProfileMenuSection(
              onEditProfile: () => context.push('/profile/edit'),
              onChangePassword: () => context.push('/profile/change-password'),
              // The shared editor publishes the confirmed backend response.
              // Reloading here would duplicate the request and blank the page.
              onPreferences: () => context.push('/profile/preferences'),
              onAtlas: () => context.push('/profile/atlas'),
              onMyReviews: () => context.push('/profile/my-reviews'),
              onArchived: () => context.push('/archived'),
              onPrivacy: () => context.push('/legal'),
              onAbout: () => showAboutProxvelSheet(context),
              onDeleteAccount: () => context.push('/legal/delete-account'),
              onUpdates: () => context.push('/profile/updates'),
              onLogout: () => showLogoutConfirmSheet(
                context,
                onConfirm: () async {
                  final router = GoRouter.of(context);
                  await auth.logout();
                  router.go('/welcome');
                },
              ),
            ),

            const SizedBox(height: AppSpace.group),
            const Text(
              'Hecho para descubrir el Perú.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            SizedBox(height: 146 + MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

/// Banner de error de carga del perfil.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpace.related),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
