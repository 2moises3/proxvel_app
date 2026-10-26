import 'package:flutter/material.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_text_styles.dart';
import '../../../models/announcement_model.dart';
import '../../theme/app_colors.dart';
import '../images/adaptive_destination_image.dart';
import 'announcement_style.dart';

/// Ventana del anuncio al abrir la app ('app_start') o aviso importante ('global_modal').
///
/// Conserva su ciclo de vida en Home, pero se pinta en el Overlay raíz:
/// el anuncio y su barrera cubren también la isla de navegación global.
///
/// Un aviso importante no se cierra tocando fuera ni con X: hay que pulsar «Entendido».
class AnnouncementModalOverlay extends StatefulWidget {
  final AnnouncementModel announcement;

  /// El viajero cerró la ventana (X, fuera, «Ahora no» o «Entendido»).
  final VoidCallback onClose;

  /// El viajero tocó el botón de acción. La ventana se cierra después.
  final VoidCallback onAction;

  const AnnouncementModalOverlay({
    super.key,
    required this.announcement,
    required this.onClose,
    required this.onAction,
  });

  @override
  State<AnnouncementModalOverlay> createState() =>
      _AnnouncementModalOverlayState();
}

class _AnnouncementModalOverlayState extends State<AnnouncementModalOverlay> {
  final _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) => OverlayPortal(
    overlayLocation: OverlayChildLocation.rootOverlay,
    controller: _portal,
    overlayChildBuilder: _buildModal,
    child: const SizedBox.shrink(),
  );

  VoidCallback get onClose => widget.onClose;
  VoidCallback get onAction => widget.onAction;

  Widget _buildModal(BuildContext context) {
    final ann = widget.announcement;
    final style = AnnouncementStyle.of(ann.templateType);
    final showImage = style.allowsImage && ann.hasImage;
    final important = ann.placement == 'global_modal';

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: important ? null : onClose, // tap fuera del card = cerrar
          child: Center(
            child: GestureDetector(
              onTap: () {}, // absorbe taps dentro del card
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Cabecera: imagen real o degradado de la plantilla ──
                    Stack(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: showImage
                              ? AdaptiveDestinationImage(
                                  imagePath: ann.backgroundImageUrl!,
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: style.light
                                          ? const [
                                              AppColors.accentSoft,
                                              AppColors.surface,
                                            ]
                                          : style.gradient,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      style.icon,
                                      color: style.light
                                          ? AppColors.accent
                                          : style.iconColor,
                                      size: 44,
                                    ),
                                  ),
                                ),
                        ),
                        if (!important)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Semantics(
                              button: true,
                              label: 'Cerrar',
                              child: GestureDetector(
                                onTap: onClose,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ── Contenido ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ann.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: SingleChildScrollView(
                              child: Text(
                                ann.message,
                                style: AppTextStyles.bodySecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.card),
                          Row(
                            children: [
                              Expanded(
                                child: _ModalButton(
                                  label: important || !ann.hasAction
                                      ? 'Entendido'
                                      : 'Ahora no',
                                  onTap: onClose,
                                ),
                              ),
                              if (ann.hasAction) ...[
                                const SizedBox(width: AppSpace.content),
                                Expanded(
                                  child: _ModalButton(
                                    label: ann.ctaText!,
                                    filled: true,
                                    onTap: onAction,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ModalButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
              color: filled ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
