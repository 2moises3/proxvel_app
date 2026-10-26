import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../images/adaptive_destination_image.dart';

class MapPhotoPin extends StatelessWidget {
  const MapPhotoPin({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.count = 1,
  });
  final String imageUrl, label;
  final VoidCallback onTap;
  final bool selected;
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1 : .88,
          alignment: Alignment.bottomCenter,
          duration: AppMotion.duration(context),
          child: SizedBox(
            width: 72,
            height: 84,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  bottom: 3,
                  child: Transform.rotate(
                    angle: .785398,
                    child: Container(
                      width: 17,
                      height: 17,
                      color: selected ? AppColors.accent : Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.accent : Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AdaptiveDestinationImage(
                      imagePath: imageUrl,
                      cacheWidth: 160,
                      width: 58,
                      height: 58,
                    ),
                  ),
                ),
                if (count > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.discovery,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
