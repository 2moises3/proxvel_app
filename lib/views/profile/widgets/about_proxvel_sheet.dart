import 'profile_page_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/legal/legal_texts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';
import 'profile_menu_item.dart';

void showAboutProxvelSheet(BuildContext context) =>
    context.push('/profile/about');

class AboutProxvelScreen extends StatefulWidget {
  const AboutProxvelScreen({super.key});
  @override
  State<AboutProxvelScreen> createState() => _AboutProxvelScreenState();
}

class _AboutProxvelScreenState extends State<AboutProxvelScreen> {
  late final Future<PackageInfo> _package = PackageInfo.fromPlatform();

  Future<void> _open(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir el enlace. Inténtalo nuevamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: profilePageBar(context, 'Sobre PROXVEL'),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent,
              child: AppIcon(
                AppIcons.compass,
                size: 30,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Más cerca de tu\npróxima historia.',
            style: TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Descubre destinos del Perú y encuentra los que conectan con tu forma de viajar.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _info(
            AppIcons.sparkles,
            'Preferencias que tienen sentido',
            'Tu perfil de viaje ayuda al motor a ordenar los destinos. Puedes cambiar tus preferencias cuando quieras.',
          ),
          _info(
            AppIcons.compass,
            'Información para decidir',
            'Explora los lugares, consulta reseñas y compara el contexto de tu visita. Confirma horarios, tarifas y condiciones antes de viajar.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Transparencia y confianza',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ProfileMenuItem(
                    svgIcon: AppIcons.info,
                    label: 'Términos y condiciones',
                    onTap: () => context.push('/legal/doc/terminos'),
                  ),
                  ProfileMenuItem(
                    svgIcon: AppIcons.lock,
                    label: 'Política de privacidad',
                    onTap: () => context.push('/legal/doc/privacidad'),
                  ),
                  ProfileMenuItem(
                    svgIcon: AppIcons.navProfile,
                    label: 'Permisos de la app',
                    onTap: () => context.push('/legal/doc/permisos'),
                  ),
                  ProfileMenuItem(
                    svgIcon: AppIcons.externalLink,
                    label: 'Fuentes y licencias',
                    onTap: () => context.push('/legal/doc/fuentes'),
                  ),
                  ProfileMenuItem(
                    svgIcon: AppIcons.info,
                    label: 'Licencias de código abierto',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'PROXVEL',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Estamos para ayudarte',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _open(Uri(scheme: 'mailto', path: kSupportEmail)),
            icon: const AppIcon(
              AppIcons.externalLink,
              size: 18,
              color: AppColors.discovery,
            ),
            label: const Text(kSupportEmail),
          ),
          const Divider(height: 40),
          TextButton(
            onPressed: () => _open(Uri.parse('https://m3biznovatech.com')),
            child: const Text('M3Biznovatech ↗'),
          ),
          FutureBuilder<PackageInfo>(
            future: _package,
            builder: (context, snapshot) => Text(
              snapshot.hasData
                  ? 'Versión ${snapshot.data!.version} · ${snapshot.data!.buildNumber}'
                  : snapshot.hasError
                  ? 'Versión no disponible'
                  : 'Consultando versión…',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _info(String icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, color: AppColors.discovery),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
