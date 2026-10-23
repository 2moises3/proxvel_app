import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import 'profile_menu_item.dart';

/// Sección de menú del perfil (editar, preferencias, reseñas, sobre, logout).
/// Recibe los callbacks desde la pantalla para mantener la navegación y los
/// diálogos en un único lugar.
class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onPreferences;
  final VoidCallback onMyReviews;
  final VoidCallback onArchived;
  final VoidCallback onPrivacy;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const ProfileMenuSection({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onPreferences,
    required this.onMyReviews,
    required this.onArchived,
    required this.onPrivacy,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.edit_rounded,
                  label: 'Editar perfil',
                  onTap: onEditProfile,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Cambiar contraseña',
                  onTap: onChangePassword,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.tune_rounded,
                  label: 'Tu forma de viajar',
                  onTap: onPreferences,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.rate_review_rounded,
                  label: 'Mis reseñas',
                  onTap: onMyReviews,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.archive_outlined,
                  label: 'Archivados',
                  onTap: onArchived,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacidad y legal',
                  onTap: onPrivacy,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Sobre PROXVEL',
                  onTap: onAbout,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.field),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              isDestructive: true,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
