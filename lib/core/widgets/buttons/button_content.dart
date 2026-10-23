import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_text_styles.dart';

/// Mantiene la geometría de la etiqueta mientras se espera la respuesta.
class ButtonContent extends StatelessWidget {
  final String text;
  final bool isLoading;
  const ButtonContent({super.key, required this.text, required this.isLoading});

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      ExcludeSemantics(
        excluding: isLoading,
        child: Opacity(
          opacity: isLoading ? 0 : 1,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.button,
          ),
        ),
      ),
      if (isLoading)
        Semantics(
          label: 'Cargando',
          liveRegion: true,
          child: const SizedBox.square(
            dimension: AppSpace.section,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
    ],
  );
}
