import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/images/adaptive_destination_image.dart';
import '../../../models/destination_model.dart';

class DestinationGalleryPreview extends StatelessWidget {
  final List<String> imageUrls;

  const DestinationGalleryPreview({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    // 1. Filtrado estricto de URLs reusando la lógica centralizada
    final validImages = imageUrls.where((url) => DestinationModel.isValidImageUrl(url)).toList();

    debugPrint('[Gallery] validImages.length = ${validImages.length}');

    // Caso A: 0 imágenes válidas
    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Caso B: 1 imagen válida
    if (validImages.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Galería',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppSpace.content),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AdaptiveDestinationImage(
              imagePath: validImages.first,
              width: double.infinity,
              height: 160,
            ),
          ),
        ],
      );
    }

    // Caso C: 2 o más imágenes válidas
    final displayImages = validImages.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Galería',
              style: AppTextStyles.sectionTitle,
            ),
            GestureDetector(
              onTap: () {
                // Navigate to full gallery
              },
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.content),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpace.content),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AdaptiveDestinationImage(
                  imagePath: displayImages[index],
                  width: 100,
                  height: 120,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.field),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            displayImages.length,
            (index) => Padding(
              padding: EdgeInsets.only(right: index < displayImages.length - 1 ? 6.0 : 0),
              child: _buildDot(index == 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.divider,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
