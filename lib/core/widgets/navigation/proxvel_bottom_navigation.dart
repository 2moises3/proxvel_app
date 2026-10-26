import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../common/app_icon.dart';

/// Floating navigation island with a frosted backdrop and a single active label.
class ProxvelBottomNavigation extends StatelessWidget {
  const ProxvelBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.islandOffset = 0,
    this.backdropOffset = 0,
  });
  final double islandOffset;
  final double backdropOffset;
  final int currentIndex;
  final ValueChanged<int> onTap;
  static const _labels = ['Inicio', 'Mapa', 'Favoritos', 'Perfil'];
  static const _icons = [
    AppIcons.navHome,
    AppIcons.navMap,
    AppIcons.navHeart,
    AppIcons.navProfile,
  ];
  static const _selectedIcons = [
    AppIcons.navHome,
    AppIcons.navMap,
    AppIcons.heartFilled,
    AppIcons.navProfile,
  ];

  static double _blurAt(double position) {
    if (position <= 0.18) return 0.0;
    final t = ((position - 0.18) / 0.82).clamp(0.0, 1.0);
    return 10 * t * t * (3 - 2 * t);
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          top: backdropOffset,
          bottom: -backdropOffset,
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  // Smoothstep starts with zero blur and zero slope. Disjoint
                  // slices avoid re-blurring an overlapping horizontal seam.
                  for (var band = 0; band < 16; band++)
                    Positioned(
                      top: constraints.maxHeight * band / 16,
                      left: 0,
                      right: 0,
                      height: constraints.maxHeight / 16,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _blurAt(band / 15),
                            sigmaY: _blurAt(band / 15),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: backdropOffset,
          bottom: -backdropOffset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.0),
                    AppColors.background.withValues(alpha: 0.0),
                    AppColors.background.withValues(alpha: 0.04),
                    AppColors.background.withValues(alpha: 0.18),
                    AppColors.background.withValues(alpha: 0.48),
                    AppColors.background.withValues(alpha: 0.82),
                    AppColors.background.withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.18, 0.32, 0.50, 0.70, 0.88, 1.0],
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, islandOffset),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 56, 24, bottom + 18),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFFDADAD6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .09),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFFDADAD6),
                            width: 1,
                          ),
                        ),
                        color: Colors.white.withValues(alpha: .90),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Keep the selected capsule balanced, even on wide phones.
                              final activeWidth = (constraints.maxWidth * .40)
                                  .clamp(0.0, constraints.maxWidth - 144);
                              final inactiveWidth =
                                  (constraints.maxWidth - activeWidth) / 3;
                              return Row(
                                children: [
                                  for (var i = 0; i < _labels.length; i++)
                                    AnimatedContainer(
                                      duration: duration,
                                      curve: Curves.easeOutCubic,
                                      width: i == currentIndex
                                          ? activeWidth
                                          : inactiveWidth,
                                      child: Semantics(
                                        selected: currentIndex == i,
                                        button: true,
                                        label: _labels[i],
                                        child: ExcludeSemantics(
                                          child: Tooltip(
                                            message: _labels[i],
                                            child: Material(
                                              color: currentIndex == i
                                                  ? AppColors.accent
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                              child: InkWell(
                                                onTap: () => onTap(i),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        minHeight: 60,
                                                      ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 14,
                                                        ),
                                                    child: currentIndex == i
                                                        ? Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              AppIcon(
                                                                _selectedIcons[i],
                                                                size: 23,
                                                                color:
                                                                    const Color(
                                                                      0xFF202020,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 7,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  _labels[i],
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: AppTypography.style(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: const Color(
                                                                      0xFF202020,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : AppIcon(
                                                            _icons[i],
                                                            size: 23,
                                                            color: const Color(
                                                              0xFF202020,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
