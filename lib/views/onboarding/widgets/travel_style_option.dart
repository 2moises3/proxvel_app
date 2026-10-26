import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class TravelStyleOption extends StatelessWidget {
  const TravelStyleOption({
    super.key,
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.containImage = false,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;
  final bool containImage;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: selected,
    button: true,
    child: ExcludeSemantics(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                width: 1.5,
                color: selected ? AppColors.discovery : const Color(0xFFE7E7E4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          asset,
                          fit: containImage ? BoxFit.contain : BoxFit.cover,
                          cacheWidth: 384,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.discovery : Colors.white,
                          border: Border.all(
                            color: selected
                                ? AppColors.discovery
                                : const Color(0xFFD1D4D6),
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 42),
                  child: Center(
                    child: Text(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
