import 'package:flutter/material.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../buttons/proxvel_button.dart';

/// Estado compartido que puede desplazarse incluso bajo una cabecera o teclado.
class ProxvelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProxvelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 32),
              ),
              const SizedBox(height: AppSpace.section),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpace.content),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.section),
                ProxvelButton(text: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
