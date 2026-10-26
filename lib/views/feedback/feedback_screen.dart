import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/feedback_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/destination_controller.dart';
import '../../models/destination_model.dart';
import '../../models/feedback_model.dart';
import '../../integration/services/destination_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common/app_icon.dart';
import '../../core/widgets/images/adaptive_destination_image.dart';

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
  DestinationModel? _destination;
  final Map<String, double> _aspectRatings = {};
  bool _showAspects = false;

  static const _aspectsConfig = [
    (key: 'atractivos', label: 'Atractivos y paisajes', icon: Icons.landscape_rounded),
    (key: 'seguridad', label: 'Seguridad', icon: Icons.shield_outlined),
    (key: 'gastronomia', label: 'Gastronomía y comida', icon: Icons.restaurant_rounded),
    (key: 'limpieza', label: 'Limpieza y cuidado', icon: Icons.cleaning_services_rounded),
    (key: 'accesibilidad', label: 'Accesibilidad y transporte', icon: Icons.directions_bus_rounded),
    (key: 'costos', label: 'Costos y precios', icon: Icons.payments_outlined),
    (key: 'atencion_servicio', label: 'Atención y guiado', icon: Icons.support_agent_rounded),
    (key: 'clima', label: 'Clima durante la visita', icon: Icons.wb_sunny_outlined),
    (key: 'alojamiento', label: 'Alojamiento en la zona', icon: Icons.hotel_rounded),
    (key: 'aforo_multitudes', label: 'Tranquilidad y aforo', icon: Icons.groups_outlined),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDestination());
  }

  Future<void> _loadDestination() async {
    if (!mounted) return;
    final current = context.read<DestinationController>().destination;
    if (current?.id == widget.destinationId) {
      setState(() => _destination = current);
      return;
    }
    try {
      final destination = await context
          .read<DestinationService>()
          .getDestinationById(widget.destinationId);
      if (mounted) setState(() => _destination = destination);
    } catch (_) {
      /* A direct link can still submit a review without the photo. */
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _rating >= 1 && _commentController.text.trim().isNotEmpty;
  @override
  Widget build(BuildContext context) {
    final busy = context.watch<FeedbackController>().isSubmitting;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF202020),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          onPressed: busy ? null : () => context.pop(_submitted),
          tooltip: 'Volver',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202020),
            size: 24,
          ),
        ),
        title: const Text('Tu experiencia', style: AppTextStyles.sectionTitle),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _submitted
              ? Column(
                  children: [
                    const SizedBox(height: 48),
                    const AppIcon(
                      AppIcons.sparkles,
                      color: AppColors.discovery,
                      size: 56,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gracias por compartir tu viaje.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu reseña ayuda a otros viajeros a conocer mejor este destino.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 32),
                    _button('Volver al destino', () => context.pop(true)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_destination != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 1.8,
                          child: AdaptiveDestinationImage(
                            imagePath: _destination!.imageUrl,
                            cacheWidth: 960,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(_destination!.name, style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      '¿Cómo fue tu visita?',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige una puntuación y cuenta lo que te gustaría que otro viajero supiera.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Flexible(
                            child: IconButton(
                              tooltip: '$i de 5 estrellas',
                              onPressed: busy
                                  ? null
                                  : () =>
                                        setState(() => _rating = i.toDouble()),
                              icon: AppIcon(
                                _rating >= i
                                    ? AppIcons.starFilled
                                    : AppIcons.star,
                                size: 34,
                                color: _rating >= i
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _rating == 0
                            ? 'Toca las estrellas para calificar'
                            : [
                                'Muy mala',
                                'Mala',
                                'Regular',
                                'Buena',
                                'Excelente',
                              ][_rating.toInt() - 1],
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAspectsSection(busy),
                    const SizedBox(height: 24),
                    const Text('Tu reseña', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      enabled: !busy,
                      minLines: 5,
                      maxLines: 10,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            '¿Qué disfrutaste? ¿Qué recomendarías antes de ir?',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Se mostrará tu nombre y la inicial de tu apellido cuando estén disponibles. Evita incluir datos personales en el comentario.',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 24),
                    _button(
                      busy ? 'Enviando reseña…' : 'Publicar reseña',
                      _canSubmit && !busy ? _submit : null,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback? onPressed) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, 56),
        shape: const StadiumBorder(),
      ),
      child: Text(text),
    ),
  );

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
      aspectRatings: _aspectRatings,
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

  Widget _buildAspectsSection(bool busy) {
    final count = _aspectRatings.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: busy ? null : () => setState(() => _showAspects = !_showAspects),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: AppIcon(
                        AppIcons.sliders,
                        size: 18,
                        color: count > 0 ? const Color(0xFFB87D0F) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aspectos específicos',
                          style: AppTypography.style(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF202020),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == 0
                              ? 'Opcional · Toca para calificar'
                              : '$count ${count == 1 ? 'aspecto calificado' : 'aspectos calificados'}',
                          style: AppTypography.style(
                            fontSize: 12,
                            color: count > 0 ? const Color(0xFFB87D0F) : AppColors.textSecondary,
                            fontWeight: count > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAspects
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6B7280),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_showAspects) ...[
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evalúa los aspectos que hayas vivido en este lugar:',
                    style: AppTypography.style(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in _aspectsConfig) ...[
                    _buildAspectRow(item.key, item.label, item.icon, busy),
                    if (item != _aspectsConfig.last)
                      const Divider(height: 14, color: Color(0xFFF9FAFB)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAspectRow(String key, String label, IconData icon, bool busy) {
    final currentVal = _aspectRatings[key] ?? 0.0;
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.style(
              fontSize: 13,
              fontWeight: currentVal > 0 ? FontWeight.w600 : FontWeight.w400,
              color: currentVal > 0 ? const Color(0xFF202020) : const Color(0xFF4B5563),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              GestureDetector(
                onTap: busy
                    ? null
                    : () {
                        setState(() {
                          if (currentVal == i) {
                            _aspectRatings.remove(key);
                          } else {
                            _aspectRatings[key] = i.toDouble();
                          }
                        });
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: AppIcon(
                    currentVal >= i ? AppIcons.starFilled : AppIcons.star,
                    size: 19,
                    color: currentVal >= i
                        ? AppColors.accent
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
