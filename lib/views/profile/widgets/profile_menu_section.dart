import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';
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
  final VoidCallback onUpdates;
  final VoidCallback onLogout;
  final VoidCallback? onDeleteAccount;

  const ProfileMenuSection({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onPreferences,
    required this.onMyReviews,
    required this.onArchived,
    required this.onPrivacy,
    required this.onAbout,
    required this.onUpdates,
    required this.onLogout,
    this.onDeleteAccount,
  });

  Widget _group(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 60,
                    color: AppColors.divider,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _group('Tu experiencia', [
          ProfileMenuItem(
            svgIcon: AppIcons.sliders,
            label: 'Preferencias de viaje',
            onTap: onPreferences,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.star,
            label: 'Mis reseñas',
            onTap: onMyReviews,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.compass,
            label: 'Destinos archivados',
            onTap: onArchived,
          ),
        ]),
        _group('Cuenta y privacidad', [
          ProfileMenuItem(
            svgIcon: AppIcons.navProfile,
            label: 'Datos personales',
            onTap: onEditProfile,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.lock,
            label: 'Cambiar contraseña',
            onTap: onChangePassword,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.info,
            label: 'Privacidad y mis datos',
            onTap: onPrivacy,
          ),
        ]),
        _group('PROXVEL', [
          ProfileMenuItem(
            svgIcon: AppIcons.info,
            label: 'Conoce PROXVEL',
            onTap: onAbout,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.externalLink,
            label: 'Actualizaciones',
            onTap: onUpdates,
          ),
        ]),
        _group('Gestionar mi cuenta', [
          ProfileMenuItem(
            svgIcon: AppIcons.logOut,
            label: 'Cerrar sesión',
            onTap: onLogout,
          ),
          if (onDeleteAccount != null)
            ProfileMenuItem(
              svgIcon: AppIcons.navProfile,
              label: 'Eliminar mi cuenta',
              isDestructive: true,
              onTap: onDeleteAccount!,
            ),
        ]),
      ],
    ),
  );
}
