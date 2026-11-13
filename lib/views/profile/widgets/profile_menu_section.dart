import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_picker.dart';
import '../../../core/localization/l10n.dart';
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
  final VoidCallback onAtlas;
  final VoidCallback onMyReviews;
  final VoidCallback onArchived;
  final VoidCallback onPrivacy;
  final VoidCallback onAbout;
  final VoidCallback onUpdates;
  final bool updateAvailable;
  final VoidCallback onLogout;
  final VoidCallback? onDeleteAccount;

  const ProfileMenuSection({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onPreferences,
    required this.onAtlas,
    required this.onMyReviews,
    required this.onArchived,
    required this.onPrivacy,
    required this.onAbout,
    required this.onUpdates,
    this.updateAvailable = false,
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
        _group(context.l10n.yourExperience, [
          ProfileMenuItem(
            svgIcon: AppIcons.compass,
            label: context.l10n.visitAtlas,
            onTap: onAtlas,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.sliders,
            label: context.l10n.travelPreferences,
            onTap: onPreferences,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.star,
            label: context.l10n.myReviews,
            onTap: onMyReviews,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.compass,
            label: context.l10n.archivedPlaces,
            onTap: onArchived,
          ),
        ]),
        _group(context.l10n.accountPrivacy, [
          ProfileMenuItem(
            svgIcon: AppIcons.navProfile,
            label: context.l10n.personalData,
            onTap: onEditProfile,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.lock,
            label: context.l10n.changePassword,
            onTap: onChangePassword,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.info,
            label: context.l10n.privacyData,
            onTap: onPrivacy,
          ),
        ]),
        _group('PROXVEL', [
          if (context.watch<AppLanguage?>() != null)
            ProfileMenuItem(
              icon: Icons.language_rounded,
              label: context.l10n.language,
              onTap: () => showLanguagePicker(context),
            ),
          ProfileMenuItem(
            svgIcon: AppIcons.info,
            label: context.l10n.aboutProxvel,
            onTap: onAbout,
          ),
          ProfileMenuItem(
            svgIcon: AppIcons.externalLink,
            label: updateAvailable
                ? context.l10n.uiActualizacionDisponible
                : context.l10n.updates,
            onTap: onUpdates,
          ),
        ]),
        _group(context.l10n.manageAccount, [
          ProfileMenuItem(
            svgIcon: AppIcons.logOut,
            label: context.l10n.signOut,
            onTap: onLogout,
          ),
          if (onDeleteAccount != null)
            ProfileMenuItem(
              svgIcon: AppIcons.navProfile,
              label: context.l10n.deleteAccount,
              isDestructive: true,
              onTap: onDeleteAccount!,
            ),
        ]),
      ],
    ),
  );
}
