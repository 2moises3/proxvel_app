import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/widgets/auth_form_page.dart';

/// A brief, illustrative guide. It never represents actual recommendation data.
class ProfileCompletionView extends StatefulWidget {
  const ProfileCompletionView({
    super.key,
    required this.onContinue,
    this.isEntering = false,
  });

  final VoidCallback onContinue;
  final bool isEntering;

  @override
  State<ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<ProfileCompletionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _guide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _guide.stop();
      _guide.value = 1;
    } else if (!_guide.isAnimating && _guide.value < 1) {
      _guide.forward();
    }
  }

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  TextStyle _text(
    double size, {
    Color color = const Color(0xFF202020),
    FontWeight weight = FontWeight.w400,
  }) => AppTypography.style(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFAF8),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 52).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.discovery.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: AppColors.discovery,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Preferencias guardadas',
                                    style: _text(
                                      14,
                                      color: AppColors.discovery,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tu próxima aventura,\nmás a tu medida.',
                            textAlign: TextAlign.center,
                            style: _text(32, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nuestro motor de recomendaciones usa tus preferencias para ayudarte a descubrir destinos que van contigo.',
                            textAlign: TextAlign.center,
                            style: _text(16, color: const Color(0xFF626870)),
                          ),
                          const SizedBox(height: 28),
                          Semantics(
                            label:
                                'Guía: en Inicio, abre la pestaña Para ti para consultar tus recomendaciones.',
                            child: ExcludeSemantics(child: _preview()),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Inicio → Para ti',
                            style: _text(20, weight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ahí encontrarás tus recomendaciones.\nPuedes cambiar tus preferencias cuando quieras.',
                            textAlign: TextAlign.center,
                            style: _text(14, color: const Color(0xFF626870)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: AuthSubmitButton(
                  text: 'Ir al inicio',
                  size: AuthSubmitButtonSize.large,
                  isLoading: widget.isEntering,
                  onPressed: widget.onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _preview() => AnimatedBuilder(
    animation: _guide,
    builder: (context, child) {
      final selection = Curves.easeInOutCubic.transform(
        ((_guide.value - .15) / .3).clamp(0, 1),
      );
      final reveal = Curves.easeOutCubic.transform(
        ((_guide.value - .5) / .45).clamp(0, 1),
      );
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE7E7E4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 19),
                const SizedBox(width: 8),
                Text('Inicio', style: _text(15, weight: FontWeight.w500)),
                const Spacer(),
                Text(
                  'VISTA GUÍA',
                  style: _text(10, color: const Color(0xFF626870)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F2),
                borderRadius: BorderRadius.circular(99),
              ),
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(-1 + selection * 2, 0),
                      child: FractionallySizedBox(
                        widthFactor: .5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF202020),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (index, label) in [
                        'Explorar',
                        'Para ti',
                      ].indexed)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: _text(
                                14,
                                weight: FontWeight.w500,
                                color: Color.lerp(
                                  index == 0
                                      ? Colors.white
                                      : const Color(0xFF626870),
                                  index == 0
                                      ? const Color(0xFF626870)
                                      : Colors.white,
                                  selection,
                                )!,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: .18 + reveal * .82,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - reveal)),
                child: Row(
                  children: [
                    for (final scene in ['mountains', 'beach', 'culture'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: .95,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/onboarding_${scene}_scene.webp',
                                    fit: BoxFit.cover,
                                    cacheWidth: 256,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7E7E4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
