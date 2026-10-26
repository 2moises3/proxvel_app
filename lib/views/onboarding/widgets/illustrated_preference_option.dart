import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A circular scene with a selection ring; its label remains outside the image.
class IllustratedPreferenceOption extends StatelessWidget {
  const IllustratedPreferenceOption({
    super.key,
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Semantics(
      label: description == null ? label : '$label. $description',
      selected: selected,
      button: true,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: duration,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2.5,
                                color: selected
                                    ? AppColors.discovery
                                    : Colors.transparent,
                              ),
                            ),
                            child: ClipOval(
                              child: AnimatedScale(
                                scale: selected ? 1.05 : 1,
                                duration: duration,
                                curve: Curves.easeOutCubic,
                                child: Image.asset(
                                  asset,
                                  fit: BoxFit.cover,
                                  cacheWidth: 384,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (selected)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.discovery,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.style(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.discovery
                          : const Color(0xFF202020),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: AppTypography.style(
                        fontSize: 12,
                        color: const Color(0xFF626870),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
