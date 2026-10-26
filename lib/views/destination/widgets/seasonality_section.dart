import 'package:flutter/material.dart';
import '../../../core/widgets/common/app_icon.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../integration/services/destination_service.dart';
import '../../../models/seasonality_model.dart';

/// «Mejor época para ir»: explicación del clima y la afluencia del mes (texto de la
/// tesis) y calendario de 12 meses con el mejor y el peor mes para el viajero.
///
/// Solo informa: no modifica el motor. Si el destino no tiene datos, no se muestra nada.
class SeasonalitySection extends StatefulWidget {
  final String destinationId;

  /// Preferencia de clima y tolerancia a multitudes del usuario (null = neutro).
  final String? clima;
  final String? tolerancia;
  final int? initialMonth;

  const SeasonalitySection({
    super.key,
    required this.destinationId,
    this.clima,
    this.tolerancia,
    this.initialMonth,
  });

  @override
  State<SeasonalitySection> createState() => _SeasonalitySectionState();
}

class _SeasonalitySectionState extends State<SeasonalitySection> {
  late Future<DestinationCalendar?> _future;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMonth ?? DateTime.now().month;
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant SeasonalitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationId != widget.destinationId ||
        oldWidget.clima != widget.clima ||
        oldWidget.tolerancia != widget.tolerancia) {
      _future = _load();
    }
    if (oldWidget.initialMonth != widget.initialMonth) {
      _selected = widget.initialMonth ?? DateTime.now().month;
    }
  }

  Future<DestinationCalendar?> _load() =>
      context.read<DestinationService>().getCalendar(
        widget.destinationId,
        clima: widget.clima,
        tolerancia: widget.tolerancia,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DestinationCalendar?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return TextButton.icon(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('No pudimos cargar la temporada. Reintentar'),
          );
        }
        final calendar = snapshot.data;
        if (calendar == null || calendar.months.isEmpty) {
          return const SizedBox.shrink();
        }
        return _content(calendar);
      },
    );
  }

  Widget _content(DestinationCalendar cal) {
    final month = cal.months.firstWhere(
      (m) => m.month == _selected,
      orElse: () => cal.months.first,
    );
    final best = cal.bestMonth;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mejor época para ir', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpace.micro),
          const Text(
            'Toca un mes y descubre cómo cambia la experiencia.',
            style: AppTextStyles.bodySecondary,
          ),
          if (best != null && best >= 1 && best <= 12)
            TextButton.icon(
              onPressed: () => setState(() => _selected = best),
              icon: const AppIcon(
                AppIcons.sparkles,
                color: AppColors.discovery,
                size: 18,
              ),
              label: Text('Tu mejor contexto: ${kMonthNames[best - 1]}'),
            ),
          const SizedBox(height: 14),
          _chart(cal),
          const SizedBox(height: AppSpace.field),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              child: KeyedSubtree(
                key: ValueKey(month.month),
                child: _monthCard(month),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.content),
          Text(
            'Basado en el clima típico (SENAMHI 1991-2020) y las llegadas históricas de '
            'visitantes (MINCETUR). Personalizado con tu clima '
            '${_climateLabel(cal.preference)} y tu tolerancia a multitudes ${cal.tolerance}. '
            'Describe lo habitual de cada mes, no un pronóstico.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _climateLabel(String key) =>
      (kClimateOptions[key] ?? (key == 'indiferente' ? 'indiferente' : key))
          .toLowerCase();

  Widget _chart(DestinationCalendar cal) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Afinidad del contexto mensual', style: AppTextStyles.label),
        const SizedBox(height: 6),
        const Text(
          'Arriba: más favorable · Abajo: menos favorable',
          style: AppTextStyles.body2,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 132,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (details) => setState(
                () => _selected =
                    ((details.localPosition.dx / constraints.maxWidth) * 12)
                        .floor()
                        .clamp(0, 11) +
                    1,
              ),
              onHorizontalDragUpdate: (details) => setState(
                () => _selected =
                    ((details.localPosition.dx / constraints.maxWidth) * 12)
                        .floor()
                        .clamp(0, 11) +
                    1,
              ),
              child: CustomPaint(painter: _SeasonCurve(cal.months, _selected)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Two rows retain comfortable targets instead of twelve tiny tap areas.
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var month = 1; month <= 12; month++)
                SizedBox(
                  width: (constraints.maxWidth - 20) / 6,
                  child: TextButton(
                    onPressed: () => setState(() => _selected = month),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: EdgeInsets.zero,
                      backgroundColor: month == _selected
                          ? AppColors.accent
                          : Colors.transparent,
                      foregroundColor: month == _selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      kMonthShort[month - 1],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Color _levelColor(String? level) {
    switch (level) {
      case 'Favorable':
        return AppColors.success;
      case 'Moderado':
        return AppColors.accent;
      case 'Desfavorable':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _crowdColor(String? level) {
    switch (level) {
      case 'Bajo':
        return AppColors.success;
      case 'Medio':
        return AppColors.accent;
      case 'Alto':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _monthCard(CalendarMonth m) {
    final monthName = kMonthNames[m.month - 1];
    final title = monthName[0].toUpperCase() + monthName.substring(1);

    if (!m.hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Text(
          'Aún no tenemos datos de $monthName para este destino.',
          style: AppTextStyles.body2,
        ),
      );
    }

    final risk = m.climaRiesgo;
    final hasRisk =
        risk != null && risk.isNotEmpty && !risk.startsWith('sin riesgo');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpace.content),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (m.tempProm != null)
                _metric(
                  'assets/icons/app/thermometer.svg',
                  '${m.tempProm!.toStringAsFixed(1)} °C',
                  'Temperatura media',
                ),
              if (m.lluviaMm != null)
                _metric(
                  'assets/icons/app/droplets.svg',
                  '${m.lluviaMm!.toStringAsFixed(0)} mm',
                  'Lluvia mensual',
                ),
              if (m.visitantesMedios != null)
                _metric(
                  AppIcons.navProfile,
                  '${m.visitantesMedios!.round()}',
                  'Visitantes promedio',
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Clima',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpace.related),
              if (m.climaNivel != null)
                _chip(m.climaNivel!, _levelColor(m.climaNivel)),
              if (hasRisk) ...[
                const SizedBox(width: 6),
                _chip('Ojo: $risk', AppColors.textSecondary),
              ],
            ],
          ),
          if ((m.climaExplicacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              m.climaExplicacion!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Afluencia',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpace.related),
              if (m.aforoNivel != null)
                _chip(
                  kCrowdOptions[m.aforoNivel] ?? m.aforoNivel!,
                  _crowdColor(m.aforoNivel),
                ),
            ],
          ),
          if ((m.aforoExplicacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              m.aforoExplicacion!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String icon, String value, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.discovery.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 20, color: AppColors.discovery),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.cardTitle),
        Text(label, style: AppTextStyles.body2),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 1),
  );
}

class _SeasonCurve extends CustomPainter {
  const _SeasonCurve(this.months, this.selected);
  final List<CalendarMonth> months;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = 12 + (size.height - 24) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final x = (selected - .5) * size.width / 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - size.width / 24, 0, size.width / 12, size.height),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.discovery.withValues(alpha: .07),
    );
    Offset? previous;
    final stroke = Paint()
      ..color = AppColors.discovery
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var month = 1; month <= 12; month++) {
      final found = months.where((m) => m.month == month);
      final m = found.isEmpty ? null : found.first;
      if (m == null || !m.hasData || m.combined == null) {
        previous = null;
        continue;
      }
      final point = Offset(
        (month - .5) * size.width / 12,
        12 + (1 - m.combined!.clamp(0, 1)) * (size.height - 24),
      );
      if (previous != null) canvas.drawLine(previous, point, stroke);
      canvas.drawCircle(
        point,
        month == selected ? 7 : 4,
        Paint()
          ..color = month == selected ? AppColors.accent : AppColors.discovery,
      );
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonCurve oldDelegate) =>
      selected != oldDelegate.selected || months != oldDelegate.months;
}
