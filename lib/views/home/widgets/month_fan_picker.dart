import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Tap to open, or hold and glide. Only releasing on an option commits a month.
class MonthFanPicker extends StatefulWidget {
  const MonthFanPicker({
    super.key,
    required this.month,
    required this.onChanged,
  });
  final int? month;
  final ValueChanged<int?> onChanged;
  static const labels = [
    'Actual',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  @override
  State<MonthFanPicker> createState() => _MonthFanPickerState();
}

class _MonthFanPickerState extends State<MonthFanPicker>
    with SingleTickerProviderStateMixin {
  final _anchor = GlobalKey();
  final _options = List.generate(13, (_) => GlobalKey());
  final _focus = FocusNode();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 180),
  );
  OverlayEntry? _entry;
  LocalHistoryEntry? _history;
  int? _hover;
  bool _closing = false;
  void _open() {
    if (_entry != null) return;
    _hover = null;
    _closing = false;
    final render = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final center = render.localToGlobal(render.size.center(Offset.zero));
    _entry = OverlayEntry(
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        // Keep the fan in bounds even after the header/scroll position changes.
        // Compact landscape screens scroll the same fan instead of changing controls.
        final canvasHeight = math.max(
          size.height,
          520.0 + safe.top + safe.bottom,
        );
        final radius = math.min(180.0, size.width - 76);
        final origin = Offset(
          center.dx.clamp(radius + 32, size.width - 36),
          center.dy.clamp(
            safe.top + radius + 82,
            canvasHeight - safe.bottom - radius - 36,
          ),
        );
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: _animation,
                  child: GestureDetector(
                    onTap: _close,
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: .94),
                    ),
                  ),
                ),
              ),
              Focus(
                autofocus: true,
                focusNode: _focus,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _close();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _hover = ((_hover ?? widget.month ?? 0) + 1) % 13;
                    _entry?.markNeedsBuild();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _hover = ((_hover ?? widget.month ?? 0) + 12) % 13;
                    _entry?.markNeedsBuild();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _commit(_hover ?? widget.month ?? 0);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: size.width,
                    height: canvasHeight,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        final t = Curves.easeOutCubic.transform(
                          _animation.value,
                        );
                        return Stack(
                          children: [
                            Positioned(
                              top: safe.top + 12,
                              left: 24,
                              right: 24,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: t,
                                  child: const Text(
                                    'Desliza hasta tu mes y suelta\nActual usa el mes de hoy.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left:
                                  center.dx + (origin.dx - center.dx) * t - 24,
                              top: center.dy + (origin.dy - center.dy) * t - 24,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: t,
                                  child: const CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.accent,
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF202020),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            for (var i = 0; i < 13; i++)
                              Builder(
                                builder: (context) {
                                  final outer = i >= 6;
                                  final angle =
                                      -math.pi / 2 +
                                      (outer ? (i - 6) / 6 : i / 5) * math.pi;
                                  final r = outer
                                      ? radius
                                      : radius * (104 / 180);
                                  final step = ((t - i * .015) / (1 - i * .015))
                                      .clamp(0.0, 1.0);
                                  return Positioned(
                                    left:
                                        center.dx +
                                        (origin.dx -
                                                math.cos(angle) * r -
                                                center.dx) *
                                            step -
                                        30,
                                    top:
                                        center.dy +
                                        (origin.dy +
                                                math.sin(angle) * r -
                                                center.dy) *
                                            step -
                                        30,
                                    child: Opacity(
                                      opacity: step,
                                      child: Transform.scale(
                                        scale: .65 + .35 * step,
                                        child: _option(i),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _history = LocalHistoryEntry(
      onRemove: () {
        _history = null;
        _close();
      },
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_history!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null) _focus.requestFocus();
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  Widget _option(int i) => Semantics(
    button: true,
    selected: i == (widget.month ?? 0),
    label: i == 0 ? 'Mes actual' : MonthFanPicker.labels[i],
    child: MouseRegion(
      onEnter: (_) {
        _hover = i;
        _entry?.markNeedsBuild();
      },
      child: Material(
        key: _options[i],
        color: _hover == i ? AppColors.accent : Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: i == (widget.month ?? 0)
                ? AppColors.discovery
                : AppColors.border,
            width: 1.5,
          ),
        ),
        elevation: 0,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () => _commit(i),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  MonthFanPicker.labels[i],
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  void _track(Offset position) {
    if (_closing) return;
    int? hit;
    for (var i = 0; i < _options.length; i++) {
      final render = _options[i].currentContext?.findRenderObject();
      if (render is RenderBox &&
          (render.localToGlobal(Offset.zero) & render.size).contains(
            position,
          )) {
        hit = i;
        break;
      }
    }
    if (hit != _hover) {
      _hover = hit;
      _entry?.markNeedsBuild();
    }
  }

  Future<void> _commit(int i) async {
    if (_closing) return;
    await _close();
    if (mounted) widget.onChanged(i == 0 ? null : i);
  }

  Future<void> _close() async {
    if (_closing || _entry == null) return;
    _closing = true;
    _history?.remove();
    _history = null;
    _focus.unfocus();
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _animation.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void dispose() {
    _closing = true;
    _history?.remove();
    _entry?.remove();
    _entry?.dispose();
    _animation.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: (_) => _open(),
    onLongPressMoveUpdate: (details) => _track(details.globalPosition),
    onLongPressEnd: (details) {
      _track(details.globalPosition);
      if (_hover != null) {
        _commit(_hover!);
      } else {
        _close();
      }
    },
    onLongPressCancel: _close,
    child: OutlinedButton.icon(
      key: _anchor,
      onPressed: _open,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: const Color(0xFF202020),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      icon: const Icon(
        Icons.calendar_month_rounded,
        size: 20,
        color: AppColors.discovery,
      ),
      label: Text(MonthFanPicker.labels[widget.month ?? 0]),
    ),
  );
}
