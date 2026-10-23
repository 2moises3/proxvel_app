import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/announcement_model.dart';
import '../../theme/app_colors.dart';

/// Aspecto de cada plantilla de anuncio. Los mismos tonos usa la vista previa del dashboard.
class AnnouncementStyle {
  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;

  /// true = fondo claro con texto oscuro (aviso minimalista).
  final bool light;

  /// Se puede pintar la imagen de fondo.
  final bool allowsImage;

  const AnnouncementStyle({
    required this.gradient,
    required this.icon,
    this.iconColor = AppColors.accent,
    this.light = false,
    this.allowsImage = true,
  });

  Color get titleColor => light ? AppColors.textPrimary : Colors.white;
  Color get bodyColor => light ? AppColors.textSecondary : Colors.white.withValues(alpha: 0.9);

  static AnnouncementStyle of(String template) {
    switch (template) {
      case 'image_banner':
        return const AnnouncementStyle(
          gradient: [Color(0xFF334155), Color(0xFF0F172A)],
          icon: Icons.campaign_rounded,
        );
      case 'minimal_notice':
        return const AnnouncementStyle(
          gradient: [Colors.white, Colors.white],
          icon: Icons.info_outline_rounded,
          light: true,
          allowsImage: false,
        );
      case 'tourism_highlight':
        return const AnnouncementStyle(
          gradient: [Color(0xFFB87838), Color(0xFF0C7343)],
          icon: Icons.explore_rounded,
          iconColor: AppColors.accentLight,
        );
      case 'maintenance_notice':
        return const AnnouncementStyle(
          gradient: [Color(0xFFF59E0B), Color(0xFFE11D48)],
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.white,
        );
      case 'gradient_card':
      default:
        return const AnnouncementStyle(
          gradient: [AppColors.primaryDark, AppColors.primaryLight],
          icon: Icons.campaign_rounded,
        );
    }
  }
}

/// Abre la acción del botón: rutas internas con el router, enlaces https en el navegador.
Future<void> openAnnouncementAction(BuildContext context, AnnouncementModel ann) async {
  final url = (ann.ctaUrl ?? '').trim();
  if (url.startsWith('/')) {
    context.push(url);
    return;
  }
  if (!url.startsWith('https://')) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.tryParse(url);
  final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger?.showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
  }
}
