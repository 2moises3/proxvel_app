import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/destination_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../integration/services/review_service.dart';

class ReviewsTabContent extends StatefulWidget {
  const ReviewsTabContent({super.key, required this.controller, this.month});
  final DestinationController controller;
  final int? month;
  @override
  State<ReviewsTabContent> createState() => _ReviewsTabContentState();
}

class _ReviewsTabContentState extends State<ReviewsTabContent> {
  int? _rating;
  int _visible = 10;
  bool _refreshing = false;
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await widget.controller.refreshReviews();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final reviews = controller.reviews
        .where(
          (r) =>
              r.ratingGeneral.isFinite &&
              r.ratingGeneral >= 1 &&
              r.ratingGeneral <= 5,
        )
        .toList();
    final filtered = _rating == null
        ? reviews
        : reviews.where((r) => r.ratingGeneral.round() == _rating).toList();
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (a, b) => a + b.ratingGeneral) /
              reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Voces de viajeros', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        const Text(
          'Experiencias reales para preparar la tuya.',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(0, 56),
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              await context.push<bool>(
                '/feedback/${controller.destination!.id}',
              );
              if (mounted) await _refresh();
            },
            icon: const AppIcon(
              AppIcons.edit,
              size: 18,
              color: AppColors.textPrimary,
            ),
            label: const Text('Escribir reseña'),
          ),
        ),
        if (_refreshing)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 24),
        if (controller.hasReviewsError) ...[
          const Text(
            'No pudimos cargar las reseñas. Tus datos del destino siguen disponibles.',
            style: AppTextStyles.bodySecondary,
          ),
          TextButton(
            onPressed: _refreshing ? null : _refresh,
            child: const Text('Reintentar'),
          ),
        ] else if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                AppIcon(AppIcons.star, color: AppColors.discovery, size: 32),
                SizedBox(height: 12),
                Text(
                  'Cada viaje tiene algo que contar.',
                  style: AppTextStyles.cardTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Si ya conoces este lugar, tu experiencia puede ayudar al próximo viajero.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const AppIcon(
                      AppIcons.starFilled,
                      size: 24,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${reviews.length} reseñas',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Text('$star', style: AppTextStyles.body2),
                            const SizedBox(width: 5),
                            const AppIcon(
                              AppIcons.starFilled,
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value:
                                      reviews
                                          .where(
                                            (r) =>
                                                r.ratingGeneral.round() == star,
                                          )
                                          .length /
                                      reviews.length,
                                  minHeight: 6,
                                  color: AppColors.discovery,
                                  backgroundColor: AppColors.border,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${(reviews.where((r) => r.ratingGeneral.round() == star).length * 100 / reviews.length).round()}%',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stars in <int?>[null, 5, 4, 3, 2, 1])
                ChoiceChip(
                  label: stars == null
                      ? const Text('Todas')
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$stars'),
                            const SizedBox(width: 4),
                            AppIcon(
                              AppIcons.starFilled,
                              size: 12,
                              color: _rating == stars
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ],
                        ),
                  selected: _rating == stars,
                  showCheckmark: false,
                  selectedColor: AppColors.discovery,
                  labelStyle: TextStyle(
                    color: _rating == stars
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() {
                    _rating = stars;
                    _visible = 10;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Aún no hay reseñas con esta puntuación.',
                style: AppTextStyles.bodySecondary,
              ),
            ),
          for (final review in filtered.take(_visible))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.discovery.withValues(
                            alpha: .08,
                          ),
                          foregroundColor: AppColors.discovery,
                          child: Text(
                            (review.authorName?.trim().isNotEmpty == true
                                    ? review.authorName!.trim()[0]
                                    : 'V')
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _authorLine(review.authorName, review.createdAt),
                            style: AppTextStyles.label,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const AppIcon(
                          AppIcons.starFilled,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.ratingGeneral.toStringAsFixed(1),
                          style: AppTextStyles.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(review.reviewText, style: AppTextStyles.body1),
                    if (review.reviewId != null && !review.isOwn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _reportReview(context, review.reviewId!),
                          child: const Text(
                            'Reportar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (filtered.length > _visible)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _visible += 10),
                child: const Text('Ver más reseñas'),
              ),
            ),
        ],
      ],
    );
  }
}

const _kMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «Lucía P. · octubre 2026». Sin nombre: «Viajero PROXVEL».
String _authorLine(String? author, String? createdAt) {
  final who = (author == null || author.trim().isEmpty)
      ? 'Viajero PROXVEL'
      : author;
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Text(
              '¿Por qué reportas esta reseña?',
              style: AppTextStyles.sectionTitle,
            ),
          ),
          for (final e in _kReportReasons.entries)
            ListTile(
              title: Text(e.value),
              onTap: () => Navigator.pop(ctx, e.key),
            ),
          const SizedBox(height: AppSpace.related),
        ],
      ),
    ),
  );
  if (reason == null) return;
  try {
    await service.reportReview(reviewId, reason);
    messenger.showSnackBar(
      const SnackBar(content: Text('Gracias. Revisaremos la reseña.')),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('No pudimos enviar el reporte. Intenta de nuevo.'),
      ),
    );
  }
}
