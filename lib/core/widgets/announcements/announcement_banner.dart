import 'dart:async';
import '../../theme/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/announcement_controller.dart';
import '../../../models/announcement_model.dart';
import '../../theme/app_colors.dart';
import '../images/adaptive_destination_image.dart';
import 'announcement_style.dart';

/// Anuncios en tarjeta: carrusel en Explorar ('home_top') o dentro del detalle
/// de un destino ('destination_detail').
/// - No bloquea la navegación y, si no hay anuncios, no ocupa espacio.
/// - Con varios anuncios rota solo cada `durationSeconds` del anuncio visible.
/// - La X cierra el anuncio y no vuelve a aparecer en este teléfono.
class AnnouncementBanner extends StatefulWidget {
  final String placement;
  final String? destinationId;
  final EdgeInsetsGeometry padding;

  const AnnouncementBanner({
    super.key,
    this.placement = 'home_top',
    this.destinationId,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 20),
  });

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  final PageController _pages = PageController();
  Timer? _timer;
  int _index = 0;
  List<int> _shownIds = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnnouncementController>().load(
            placement: widget.placement,
            destinationId: widget.destinationId,
          );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _schedule(List<AnnouncementModel> items) {
    _timer?.cancel();
    if (items.length < 2) return;
    final current = items[_index.clamp(0, items.length - 1)];
    _timer = Timer(Duration(seconds: current.durationSeconds.clamp(3, 60)), () {
      if (!mounted || !_pages.hasClients) return;
      final next = (_index + 1) % items.length;
      _pages.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  void _onShown(AnnouncementController ctrl, List<AnnouncementModel> items) {
    if (items.isEmpty) return;
    final i = _index.clamp(0, items.length - 1);
    ctrl.markViewed(items[i]);
    _schedule(items);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AnnouncementController>();
    final items = ctrl.visibleFor(widget.placement, destinationId: widget.destinationId);
    if (items.isEmpty) {
      _timer?.cancel();
      return const SizedBox.shrink();
    }

    // Si cambió la lista (se cerró uno o llegó otro), se reinicia la rotación.
    final ids = items.map((a) => a.id).toList();
    if (!_sameIds(ids, _shownIds)) {
      _shownIds = ids;
      if (_index >= items.length) _index = items.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onShown(ctrl, items);
      });
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: PageView.builder(
              controller: _pages,
              itemCount: items.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _onShown(ctrl, items);
              },
              itemBuilder: (context, i) => _AnnouncementCard(
                ann: items[i],
                onClose: () => ctrl.dismiss(items[i]),
                onAction: () {
                  ctrl.markClicked(items[i]);
                  openAnnouncementAction(context, items[i]);
                },
              ),
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: AppSpace.related),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final VoidCallback onClose;
  final VoidCallback onAction;

  const _AnnouncementCard({required this.ann, required this.onClose, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final style = AnnouncementStyle.of(ann.templateType);
    final showImage = style.allowsImage && ann.hasImage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        children: [
          // ── Fondo: imagen real o degradado de la plantilla ──
          Positioned.fill(
            child: showImage
                ? AdaptiveDestinationImage(imagePath: ann.backgroundImageUrl!)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: style.gradient,
                      ),
                      border: style.light ? Border.all(color: AppColors.border) : null,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
          ),
          if (showImage)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

          // ── Contenido ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(style.icon, color: style.iconColor, size: 18),
                    const SizedBox(width: AppSpace.related),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          ann.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.related),
                Expanded(
                  child: Text(
                    ann.message,
                    maxLines: ann.hasAction ? 3 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: style.bodyColor, fontSize: 13, height: 1.4),
                  ),
                ),
                if (ann.hasAction)
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: style.light ? AppColors.primary : AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Text(
                        ann.ctaText!,
                        style: TextStyle(
                          color: style.light ? Colors.white : AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Cerrar ──
          Positioned(
            top: 6,
            right: 6,
            child: Semantics(
              button: true,
              label: 'Cerrar anuncio',
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: style.light
                        ? AppColors.surfaceVariant
                        : Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: style.light ? AppColors.textSecondary : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
