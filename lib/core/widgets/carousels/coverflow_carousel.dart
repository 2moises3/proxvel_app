import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../models/destination_model.dart';
import '../cards/coverflow_destination_card.dart';

/// A hand of cards: lateral cards tilt while the selected destination stays flat.
class CoverflowCarousel extends StatefulWidget {
  const CoverflowCarousel({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
  });
  final List<DestinationModel> destinations;
  final ValueChanged<DestinationModel> onDestinationTap;
  @override
  State<CoverflowCarousel> createState() => _CoverflowCarouselState();
}

class _CoverflowCarouselState extends State<CoverflowCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
  );
  double _dragStart = 0;

  @override
  void didUpdateWidget(covariant CoverflowCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinations.map((d) => d.id).join(',') !=
        widget.destinations.map((d) => d.id).join(',')) {
      _position.stop();
      _position.value = 0;
    }
  }

  void _go(double index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = index;
    } else {
      _position.animateTo(
        index,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();
    final count = widget.destinations.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * .78).clamp(220.0, 380.0);
        final height =
            width * 1.27 +
            (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0, 14) * 5;
        return AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final page = _position.value;
            final center = page.round();
            final indices = count == 1 ? [0] : [center - 1, center, center + 1]
              ..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));
            return Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: count == 1
                      ? null
                      : (_) {
                          _position.stop();
                          _dragStart = _position.value;
                        },
                  onHorizontalDragUpdate: count == 1
                      ? null
                      : (details) {
                          _position.value -= details.delta.dx / (width * .85);
                        },
                  onHorizontalDragEnd: count == 1
                      ? null
                      : (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          final target = velocity.abs() > 300
                              ? (velocity < 0
                                    ? _position.value.floor() + 1
                                    : _position.value.ceil() - 1)
                              : _position.value.round();
                          _go(target.toDouble());
                        },
                  onHorizontalDragCancel: count == 1
                      ? null
                      : () => _go(_dragStart.roundToDouble()),
                  child: SizedBox(
                    height: height + 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final index in indices)
                          Builder(
                            builder: (context) {
                              final diff = index - page;
                              final distance = diff.abs().clamp(0.0, 1.0);
                              final active = index == center;
                              final destination =
                                  widget.destinations[index % count];
                              return Transform(
                                key: ValueKey(index),
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.identity()
                                  ..translateByDouble(
                                    diff.clamp(-1.0, 1.0) * width * .08,
                                    distance * 7,
                                    0,
                                    1,
                                  )
                                  ..rotateZ(
                                    MediaQuery.disableAnimationsOf(context)
                                        ? 0
                                        : diff.clamp(-1.0, 1.0) * .065,
                                  )
                                  ..scaleByDouble(
                                    1 - distance * .08,
                                    1 - distance * .08,
                                    1,
                                    1,
                                  ),
                                child: ExcludeSemantics(
                                  excluding: !active,
                                  child: IgnorePointer(
                                    ignoring: !active,
                                    child: HeroMode(
                                      enabled: active,
                                      child: SizedBox(
                                        width: width,
                                        height: height,
                                        child: CoverflowDestinationCard(
                                          destination: destination,
                                          onTap: () => widget.onDestinationTap(
                                            destination,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (count > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Destino anterior',
                        onPressed: () => _go((center - 1).toDouble()),
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      ),
                      for (var i = 0; i < count; i++)
                        Semantics(
                          label: 'Destino ${i + 1} de $count',
                          selected: center % count == i,
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                _go((center + i - center % count).toDouble()),
                            child: SizedBox(
                              width: 32,
                              height: 44,
                              child: Center(
                                child: AnimatedContainer(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 200),
                                  width: center % count == i ? 26 : 6,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: center % count == i
                                        ? AppColors.accent
                                        : const Color(0xFFDADAD6),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Destino siguiente',
                        onPressed: () => _go((center + 1).toDouble()),
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
