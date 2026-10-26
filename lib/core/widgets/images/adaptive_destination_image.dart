import 'package:flutter/material.dart';
import '../../theme/app_layout.dart';

/// Imagen de destino que resuelve automáticamente la fuente:
/// - URL http(s) → Image.network (imágenes del backend / Wikimedia)
/// - ruta local → Image.asset (mocks y assets del diseño)
///
/// Mantiene el mismo fit/alignment y muestra un placeholder neutro
/// si la imagen de red falla o mientras carga.
class AdaptiveDestinationImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;

  const AdaptiveDestinationImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();
    if (path.isEmpty || path == 'PENDIENTE') return _placeholder();

    if (path.startsWith('http')) {
      return Image.network(
        path,
        cacheWidth: cacheWidth,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        // Fade-in suave al decodificar el primer frame (evita el "pop" brusco).
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: AppMotion.duration(context),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(); // Clean placeholder without eternal spinner
        },
        errorBuilder: (context, error, stack) => _placeholder(
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 40,
              color: Color(0xFFB0BEC5),
            ),
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      cacheWidth: cacheWidth,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stack) => _placeholder(
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 40,
            color: Color(0xFFB0BEC5),
          ),
        ),
      ),
    );
  }

  Widget _placeholder({Widget? child}) => SizedBox(
    width: width,
    height: height,
    child: Container(
      color: const Color(0xFFE8ECEF),
      child:
          child ??
          const Center(
            child: Icon(
              Icons.landscape_outlined,
              size: 40,
              color: Color(0xFFB0BEC5),
            ),
          ),
    ),
  );
}
