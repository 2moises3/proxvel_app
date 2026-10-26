import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_typography.dart';

/// Same choice surface in onboarding and the saved travel-preferences editor.
class PreferenceChoice extends StatelessWidget {
  const PreferenceChoice({
    super.key,
    required this.label,
    this.description,
    this.illustration,
    this.illustrationLeading = false,
    required this.selected,
    this.onTap,
  });
  final String label;
  final String? description, illustration;
  final bool illustrationLeading, selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppMotion.duration(context),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: EdgeInsets.symmetric(
          horizontal: illustrationLeading ? 12 : 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? AppColors.discovery : const Color(0xFFE7E7E4),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            if (illustrationLeading && illustration != null)
              SizedBox(
                width: 34,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        illustration!,
                        width: 32,
                        height: 32,
                        excludeFromSemantics: true,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -3,
                        bottom: -2,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.discovery,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 25,
                color: selected ? AppColors.discovery : const Color(0xFF92999D),
              ),
            SizedBox(width: illustrationLeading ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.style(
                      fontSize: illustrationLeading ? 16 : 17,
                      color: const Color(0xFF202020),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: AppTypography.style(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (illustration != null && !illustrationLeading) ...[
              const SizedBox(width: 12),
              SvgPicture.asset(
                illustration!,
                width: 48,
                height: 48,
                excludeFromSemantics: true,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
