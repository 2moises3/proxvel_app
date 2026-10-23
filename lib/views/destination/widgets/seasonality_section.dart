import 'package:flutter/material.dart';
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

  const SeasonalitySection({
    super.key,
    required this.destinationId,
    this.clima,
    this.tolerancia,
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
    _selected = DateTime.now().month;
    _future = _load();
  }

  Future<DestinationCalendar?> _load() => context
      .read<DestinationService>()
      .getCalendar(widget.destinationId, clima: widget.clima, tolerancia: widget.tolerancia);

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
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
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
        if (calendar == null) return const SizedBox.shrink();
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
    final worst = cal.worstMonth;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mejor época para ir',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpace.micro),
        if (best != null)
          Text(
            worst != null
                ? 'Lo mejor para ti: ${kMonthNames[best - 1]}. Lo menos conveniente: ${kMonthNames[worst - 1]}.'
                : 'Lo mejor para ti: ${kMonthNames[best - 1]}.',
            style: AppTextStyles.body2,
          ),
        const SizedBox(height: 14),
        _chart(cal),
        const SizedBox(height: AppSpace.field),
        _monthCard(month),
        const SizedBox(height: AppSpace.content),
        Text(
          'Basado en el clima típico (SENAMHI 1991-2020) y las llegadas históricas de '
          'visitantes (MINCETUR). Personalizado con tu clima '
          '${_climateLabel(cal.preference)} y tu tolerancia a multitudes ${cal.tolerance}. '
          'Describe lo habitual de cada mes, no un pronóstico.',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    ),
    );
  }

  String _climateLabel(String key) =>
      (kClimateOptions[key] ?? (key == 'indiferente' ? 'indiferente' : key)).toLowerCase();

  Widget _chart(DestinationCalendar cal) {
    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in cal.months) Expanded(child: _bar(m, cal)),
        ],
      ),
    );
  }

  Widget _bar(CalendarMonth m, DestinationCalendar cal) {
    final isBest = m.month == cal.bestMonth;
    final isWorst = m.month == cal.worstMonth;
    final isSelected = m.month == _selected;
    final score = (m.combined ?? 0).clamp(0.0, 1.0);
    final color = isBest
        ? AppColors.success
        : isWorst
            ? AppColors.error
            : AppColors.primary.withValues(alpha: 0.35);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = m.month),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 14,
              child: isBest
                  ? const Icon(Icons.star_rounded, size: 14, color: AppColors.success)
                  : null,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 14 + 52 * score,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpace.micro),
            Text(
              kMonthShort[m.month - 1],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final hasRisk = risk != null && risk.isNotEmpty && !risk.startsWith('sin riesgo');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpace.content),
          Row(children: [
            const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text('Clima', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpace.related),
            if (m.climaNivel != null) _chip(m.climaNivel!, _levelColor(m.climaNivel)),
            if (hasRisk) ...[
              const SizedBox(width: 6),
              _chip('Ojo: $risk', AppColors.textSecondary),
            ],
          ]),
          if ((m.climaExplicacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              m.climaExplicacion!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.groups_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text('Afluencia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpace.related),
            if (m.aforoNivel != null)
              _chip(kCrowdOptions[m.aforoNivel] ?? m.aforoNivel!, _crowdColor(m.aforoNivel)),
          ]),
          if ((m.aforoExplicacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              m.aforoExplicacion!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      );
}
