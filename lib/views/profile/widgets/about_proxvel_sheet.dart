import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom sheet "Sobre PROXVEL": logo, nombre y versión.
void showAboutProxvelSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 16, AppSpace.screen, 40),
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
          Image.asset(
            'assets/images/proxvel_logo_transparente.png',
            width: 60,
            height: 60,
          ),
          const SizedBox(height: AppSpace.field),
          const Text(
            'PROXVEL',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpace.related),
          const Text(
            'Aplicativo de recomendación\nturística personalizada',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpace.field),
          Text(
            'Versión 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ),
  );
}
