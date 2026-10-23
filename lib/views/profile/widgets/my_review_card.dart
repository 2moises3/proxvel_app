import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/review_model.dart';
import '../../../core/theme/app_colors.dart';

class MyReviewCard extends StatelessWidget {
  final ReviewModel review;

  const MyReviewCard({super.key, required this.review});

  String _mapStatus(String? status) {
    if (status == null) return 'Estado no disponible';
    switch (status) {
      case 'pending_processing':
        return 'Pendiente de análisis';
      case 'processed':
        return 'Procesada';
      case 'used_for_training':
        return 'Usada para mejora del modelo';
      default:
        return 'Estado no disponible';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.textMuted;
    switch (status) {
      case 'pending_processing':
        return AppColors.warning;
      case 'processed':
      case 'used_for_training':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAspects = review.aspectRatings.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Destino y Estrellas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  review.destinationName ?? review.destinationId ?? 'Destino',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpace.micro),
                  Text(
                    review.ratingGeneral.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.content),

          // Review Text
          Text(
            '"${review.reviewText}"',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpace.field),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpace.content),

          // Aspects (if exist)
          if (hasAspects) ...[
            const Text(
              'Aspectos comentados:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.related),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.aspectRatings.entries.map((e) {
                final double val = (e.value is num)
                    ? (e.value as num).toDouble()
                    : 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${e.key} ${val.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpace.content),
          ],

          // Status and processing month
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(review.status),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                _mapStatus(review.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(review.status),
                ),
              ),
              if (review.processingMonth != null &&
                  review.processingMonth!.isNotEmpty) ...[
                Text(
                  'Análisis: ${review.processingMonth}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
