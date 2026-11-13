import '../../core/localization/l10n.dart';
import '../profile/widgets/profile_page_bar.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';
import '../profile/widgets/profile_menu_item.dart';

/// Perfil → Privacidad y legal: todos los documentos y el acceso a «Mis datos».
class PrivacyLegalScreen extends StatelessWidget {
  const PrivacyLegalScreen({super.key});

  Future<void> _contact(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: kSupportEmail,
        queryParameters: {'subject': context.l10n.uiConsultaSobreMisDatos},
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.emailSupport(kSupportEmail))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget divider() => const Divider(height: 1, color: AppColors.divider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, context.l10n.uiPrivacidadYLegal),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            20,
            AppSpace.screen,
            32,
          ),
          children: [
            Text(
              context.l10n.uiQueHacemosConTusDatosTus,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.field),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: context.l10n.uiPoliticaDePrivacidad,
                    onTap: () => context.push('/legal/doc/privacidad'),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.description_outlined,
                    label: context.l10n.uiTerminosYCondiciones,
                    onTap: () => context.push('/legal/doc/terminos'),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: context.l10n.uiMisDatosYEliminacionDeCuenta,
                    onTap: () => context.push('/legal/my-data'),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.verified_user_outlined,
                    label: context.l10n.uiPermisosDeLaApp,
                    onTap: () => context.push('/legal/doc/permisos'),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.public_rounded,
                    label: context.l10n.uiFuentesYLicencias,
                    onTap: () => context.push('/legal/doc/fuentes'),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.code_rounded,
                    label: context.l10n.uiLicenciasDeCodigoAbierto,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'PROXVEL',
                      applicationVersion: '1.0.0 (beta)',
                      applicationLegalese:
                          '© 2026 Biznovatech S.A.C. (M3Biznovatech)',
                    ),
                  ),
                  divider(),
                  ProfileMenuItem(
                    icon: Icons.mail_outline_rounded,
                    label: context.l10n.uiContactarASoporte,
                    onTap: () => _contact(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.field),
            const Text(
              'Biznovatech S.A.C. (M3Biznovatech)\nÑaña, Lurigancho-Chosica, Lima, Perú\n$kSupportEmail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
