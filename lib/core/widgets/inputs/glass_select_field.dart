import 'dart:ui';
import '../../theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';

class GlassSelectField extends StatelessWidget {
  final bool accountStyle;
  final String label;
  final String? value;
  final String? placeholder;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onTap;

  const GlassSelectField({
    super.key,
    required this.label,
    this.accountStyle = false,
    this.value,
    this.placeholder,
    this.enabled = true,
    this.errorText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accountStyle) ...[
          Text(
            label,
            style: AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: enabled
              ? onTap
              : () {
                  if (!enabled && errorText != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorText!,
                          style: AppTypography.style(color: Colors.white),
                        ),
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              accountStyle ? 18 : AppRadius.control,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AnimatedContainer(
                duration: AppMotion.duration(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    accountStyle ? 18 : AppRadius.control,
                  ),
                  color: accountStyle
                      ? Colors.black.withValues(alpha: enabled ? 0.36 : 0.2)
                      : Colors.white.withValues(alpha: enabled ? 0.12 : 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: enabled ? 0.20 : 0.05,
                    ),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpace.field),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!accountStyle &&
                              value != null &&
                              value!.isNotEmpty)
                            Text(
                              label,
                              style: AppTypography.style(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            (value != null && value!.isNotEmpty)
                                ? value!
                                : (placeholder ?? label),
                            style: AppTypography.style(
                              color: Colors.white.withValues(
                                alpha: enabled
                                    ? ((value != null && value!.isNotEmpty)
                                          ? 1.0
                                          : (accountStyle ? 0.8 : 0.5))
                                    : 0.3,
                              ),
                              fontSize: accountStyle ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(
                        alpha: enabled ? 0.6 : 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
