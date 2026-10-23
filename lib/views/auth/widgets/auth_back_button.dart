import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';

/// Conserva el contraste del regreso sobre cualquier fotografía de acceso.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 12,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: IconButton.filled(
      tooltip: 'Volver',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        fixedSize: const Size.square(AppSizing.touchTarget),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: AppSizing.icon),
      onPressed: onPressed,
    ),
  );
}
