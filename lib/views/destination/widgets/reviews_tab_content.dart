import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/destination_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../integration/services/review_service.dart';

class ReviewsTabContent extends StatelessWidget {
  final DestinationController controller;

  const ReviewsTabContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final reviews = controller.reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opiniones de viajeros',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpace.field),
        if (controller.hasReviewsError) ...[
          Container(
            padding: const EdgeInsets.all(AppSpace.screen),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: const Center(
              child: Text(
                'No se pudieron cargar las opiniones. Inténtalo nuevamente.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ),
        ] else if (reviews.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpace.screen),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Aún no hay opiniones para este destino. Sé el primero en comentar.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpace.field),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < review.ratingGeneral.floor()
                                  ? Icons.star_rounded
                                  : (i < review.ratingGeneral
                                      ? Icons.star_half_rounded
                                      : Icons.star_border_rounded),
                              color: AppColors.accent,
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(width: AppSpace.related),
                        Text(
                          review.ratingGeneral.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.content),
                    Text(
                      '"${review.reviewText}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.content),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _authorLine(review.authorName, review.createdAt),
                            style: AppTextStyles.mutedLabel,
                          ),
                        ),
                        if (review.reviewId != null)
                          InkWell(
                            onTap: () => _reportReview(context, review.reviewId!),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, size: 14, color: AppColors.textMuted),
                                  SizedBox(width: AppSpace.micro),
                                  Text('Reportar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: AppSpace.section),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await context.push('/feedback/${controller.destination!.id}');
              if (context.mounted) {
                context.read<DestinationController>().loadDestination(controller.destination!.id);
              }
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Escribir reseña'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _kMonths = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// «Lucía P. · octubre 2026». Sin nombre: «Viajero PROXVEL».
String _authorLine(String? author, String? createdAt) {
  final who = (author == null || author.trim().isEmpty) ? 'Viajero PROXVEL' : author;
  final date = DateTime.tryParse(createdAt ?? '');
  if (date != null) {
    return '$who · ${_kMonths[date.month - 1]} ${date.year}';
  }
  return who;
}

const _kReportReasons = <String, String>{
  'ofensiva': 'Es ofensiva o discriminatoria',
  'falsa': 'Parece falsa o engañosa',
  'spam': 'Es publicidad o spam',
  'datos_personales': 'Contiene datos personales',
  'otro': 'Otro motivo',
};

/// Pide el motivo y reporta la reseña; el equipo la revisa y puede ocultarla.
Future<void> _reportReview(BuildContext context, String reviewId) async {
  final service = context.read<ReviewService>();
  final messenger = ScaffoldMessenger.of(context);
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Text('¿Por qué reportas esta reseña?', style: AppTextStyles.sectionTitle),
          ),
          for (final e in _kReportReasons.entries)
            ListTile(title: Text(e.value), onTap: () => Navigator.pop(ctx, e.key)),
          const SizedBox(height: AppSpace.related),
        ],
      ),
    ),
  );
  if (reason == null) return;
  try {
    await service.reportReview(reviewId, reason);
    messenger.showSnackBar(const SnackBar(content: Text('Gracias. Revisaremos la reseña.')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('No pudimos enviar el reporte. Intenta de nuevo.')));
  }
}
