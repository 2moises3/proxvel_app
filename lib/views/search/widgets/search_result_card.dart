import 'package:flutter/material.dart';
import '../../../core/navigation/destination_opening.dart';
import '../../../core/theme/app_layout.dart';
import '../../../controllers/search_controller.dart' show SearchResultItem;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';

/// Card de resultado de búsqueda.
/// La compatibilidad y la etiqueta IA solo se muestran cuando el orden IA está
/// activo (item.compatibility != null). En búsqueda normal no se pinta ningún
/// score ni dato inventado (sin rating ni precio falsos).
class SearchResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const SearchResultCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dest = item.destination;
    final compat = item.compatibility;
    final compatColor = compat != null
        ? _labelColor(item.label)
        : AppColors.accent;
    final location = [
      dest.city,
      dest.region,
    ].where((s) => s.trim().isNotEmpty).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image ──
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
                child: SizedBox(
                  width: 110,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DestinationHero(
                        tag: 'search/${dest.id}',
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.card),
                        ),
                        child: AdaptiveDestinationImage(
                          imagePath: dest.imageUrl,
                        ),
                      ),
                      // Compatibility badge — solo en orden IA.
                      if (compat != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: compatColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$compat%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label chip — solo en orden IA.
                      if (item.label != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: compatColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.label!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: compatColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Name
                      Text(
                        dest.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.micro),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (dest.category.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpace.related),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _miniTag(dest.category),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Verde = Recomendado, ámbar = Parcialmente recomendado, gris = el resto.
  Color _labelColor(String? label) {
    final l = (label ?? '').toLowerCase();
    if (l.contains('no recomendado')) return AppColors.textSecondary;
    if (l.contains('parcial')) return AppColors.accent;
    if (l.contains('recomendado')) return AppColors.success;
    return AppColors.textSecondary;
  }
}
