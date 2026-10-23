import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive star rating selector with labels.
class RatingSelector extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const RatingSelector({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  static const _labels = ['', 'Malo', 'Regular', 'Bueno', 'Muy bueno', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    final idx = rating.round().clamp(0, 5);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starValue = (i + 1).toDouble();
            final isActive = starValue <= rating;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isActive ? AppColors.accent : AppColors.border,
                    size: 40,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpace.related),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            idx > 0 ? _labels[idx] : 'Selecciona una calificación',
            key: ValueKey(idx),
            style: TextStyle(
              fontSize: 14,
              fontWeight: idx > 0 ? FontWeight.w700 : FontWeight.w400,
              color: idx > 0 ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
