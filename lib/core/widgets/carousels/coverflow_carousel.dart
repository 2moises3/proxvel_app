import 'dart:ui';
import '../../theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/destination_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../cards/coverflow_destination_card.dart';
import '../images/adaptive_destination_image.dart';

class CoverflowCarousel extends StatefulWidget {
  final List<DestinationModel> destinations;
  final Function(DestinationModel) onDestinationTap;

  const CoverflowCarousel({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
  });

  @override
  State<CoverflowCarousel> createState() => _CoverflowCarouselState();
}

class _CoverflowCarouselState extends State<CoverflowCarousel> {
  late PageController _pageController;
  int _currentIndex = 10000;
  double _currentPage = 10000.0;

  @override
  void initState() {
    super.initState();
    // viewportFraction limits the hit area for gestures and affects page offset math
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: _currentIndex,
    );
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0.0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 500, // Ajustado para dar espacio al bloom sin invadir otras secciones
          child: Stack(
            clipBehavior: Clip.none, // IMPORTANTE para que el bloom no se corte
            alignment: Alignment.center,
            children: [
              // 1. Las tarjetas visuales, ordenadas por Z-Index (las más lejanas al fondo)
              ..._buildVisualCards(),

              // 2. El PageView invisible en la parte superior que captura todos los gestos
              PageView.builder(
                controller: _pageController,
                itemCount: null, // Efecto Infinito
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final actualIndex = index % widget.destinations.length;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_currentIndex == index) {
                        widget.onDestinationTap(widget.destinations[actualIndex]);
                      } else {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: const SizedBox.expand(), // Hitbox transparente
                  );
                },
              ),

              // 3. Hitbox del corazón para la tarjeta CENTRADA, ENCIMA de la capa
              //    de gestos (si no, el PageView se come el tap). El ícono visual
              //    lo dibuja la propia tarjeta y refleja el estado.
              _buildActiveFavoriteHitbox(),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.section),
        // Minimalist Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.destinations.length, (dotIndex) {
            final isActive = (_currentIndex % widget.destinations.length) == dotIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 24 : 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.black87 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Tap target invisible sobre el corazón de la tarjeta centrada (300x460),
  /// colocado encima del PageView para que el toque llegue al favorito.
  Widget _buildActiveFavoriteHitbox() {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();
    final dest = widget.destinations[_currentIndex % widget.destinations.length];
    return Center(
      child: SizedBox(
        width: 300,
        height: 460,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<FavoritesController>().toggleFavorite(dest.id, dest),
              child: const SizedBox(width: 46, height: 46),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVisualCards() {
    final List<Widget> cards = [];
    final int baseIndex = _currentPage.round();

    List<int> visibleIndices = [
      baseIndex - 2,
      baseIndex - 1,
      baseIndex,
      baseIndex + 1,
      baseIndex + 2,
    ];

    visibleIndices.sort((a, b) {
      final distA = (a - _currentPage).abs();
      final distB = (b - _currentPage).abs();
      return distB.compareTo(distA);
    });

    for (int i in visibleIndices) {
      if (i < 0) continue;

      final double diff = (i - _currentPage);
      final double absDiff = diff.abs();

      if (absDiff > 1.4) continue; 

      final double scale = (1 - (absDiff * 0.20)).clamp(0.0, 1.0);
      
      double offsetMultiplier;
      if (absDiff <= 1.0) {
        offsetMultiplier = absDiff;
      } else {
        offsetMultiplier = 1.0 + (absDiff - 1.0) * 0.1;
      }
      final double translateX = 65.0 * diff.sign * offsetMultiplier;

      final double opacity = (1 - (absDiff * 0.3)).clamp(0.0, 1.0);

      final actualIndex = i % widget.destinations.length;

      cards.add(
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(translateX, 0.0, 0.0, 1.0)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: 300, // Ligeramente más ancho
              height: 460, // Un poco más alto
              child: Stack(
                clipBehavior: Clip.none, // IMPORTANTE para el bloom
                fit: StackFit.expand,
                children: [
                  // Efecto Bloom iOS (Aura sutil, luminosa, centrada detrás de la tarjeta)
                  if (absDiff < 1.0)
                    Positioned(
                      top: 15, // Más arriba para que escape más
                      bottom: -20, // Más abajo para iluminar la base
                      left: -5, // Ligeramente más ancho que la tarjeta
                      right: -5,
                      child: Opacity(
                        // Incrementamos la opacidad a 0.85 para que sea vívido y colorido
                        opacity: 0.85 * (1 - absDiff).clamp(0.0, 1.0),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30, tileMode: TileMode.decal),
                          child: AdaptiveDestinationImage(
                            imagePath: widget.destinations[actualIndex].imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  CoverflowDestinationCard(
                    destination: widget.destinations[actualIndex],
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return cards;
  }
}
