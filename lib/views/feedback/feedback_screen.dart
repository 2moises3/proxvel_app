import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/feedback_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/feedback_model.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/rating_selector.dart';

class FeedbackScreen extends StatefulWidget {
  final String destinationId;
  const FeedbackScreen({super.key, required this.destinationId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _submitted = false;


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final fbCtrl = context.watch<FeedbackController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _submitted
                ? _buildSuccessState()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 24, AppSpace.screen, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ═══ RATING ═══
                        _sectionTitle('¿Cómo fue tu experiencia?'),
                        const SizedBox(height: AppSpace.field),
                        RatingSelector(
                          rating: _rating,
                          onChanged: (v) => setState(() => _rating = v),
                        ),

                        const SizedBox(height: 28),

                        // ═══ COMMENT ═══
                        _sectionTitle('Comentario breve'),
                        const SizedBox(height: AppSpace.content),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            onChanged: (_) => setState(() {}),
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Escribe un comentario breve para enviar tu reseña...',
                              hintStyle: AppTextStyles.bodyMuted,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            style: AppTextStyles.body1,
                          ),
                        ),

                        const SizedBox(height: AppSpace.related),
                        const Text(
                          'Tu reseña será visible con tu nombre y la inicial de tu apellido. Sin tu nombre, podemos usarla para mejorar las recomendaciones.',
                          style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                        ),

                        const SizedBox(height: 28),

                        // ═══ SUBMIT BUTTON ═══
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: GestureDetector(
                            onTap: _canSubmit && !fbCtrl.isSubmitting
                                ? _submit
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _canSubmit
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _canSubmit
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: fbCtrl.isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Enviar Reseña',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _canSubmit
                                            ? Colors.white
                                            : AppColors.textMuted,
                                      ),
                                    ),
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
  }

  bool get _canSubmit =>
      _rating > 0 &&
      _commentController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final currentUser = context.read<AuthController>().currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró un usuario activo. Regístrate o inicia sesión para continuar.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final userId = currentUser.id;

    final feedback = FeedbackModel(
      userId: userId,
      destinationId: widget.destinationId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    final success = await context.read<FeedbackController>().submitFeedback(
      feedback,
    );

    if (mounted) {
      if (success) {
        setState(() => _submitted = true);
      } else {
        final errorMsg = context.read<FeedbackController>().error ?? '';
        String displayMsg =
            'No se pudo enviar la reseña. Inténtalo nuevamente.';

        if (errorMsg.isNotEmpty) {
          displayMsg = errorMsg;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 24, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpace.micro),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calificar experiencia',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu opinión ayuda a otros viajeros',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textOnDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 50,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '¡Gracias por tu reseña!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu opinión ayuda a otros viajeros\ny puede apoyar futuras mejoras del modelo.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.group),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Volver al destino',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle,
    );
  }
}
