import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared progress marks for welcome and account setup.
class AuthProgressIndicator extends StatelessWidget {
  const AuthProgressIndicator({
    super.key,
    required this.step,
    required this.count,
  });
  final int step;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Paso ${step + 1} de $count',
    child: Row(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: index == step ? 26 : 7,
            height: 5,
            decoration: BoxDecoration(
              color: index == step
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ),
  );
}
