// Clima y afluencia por mes (tesis, Fase 4). Solo informativo: no modifica el motor.

/// Umbral de la tesis: un clima es «Favorable» desde 0.70.
const double kFavorableThreshold = 0.70;

/// Preferencias de clima que entiende el motor (clave del backend → etiqueta).
const Map<String, String> kClimateOptions = {
  'frio': 'Frío',
  'templado': 'Templado',
  'calido': 'Cálido',
  'seco': 'Seco',
};

/// Nivel de afluencia de la tesis (Bajo/Medio/Alto) → palabra para el viajero.
const Map<String, String> kCrowdOptions = {
  'Bajo': 'Tranquilo',
  'Medio': 'Moderado',
  'Alto': 'Concurrido',
};

/// Nivel de costo estimado (clave del backend → etiqueta).
const Map<String, String> kCostOptions = {
  'bajo': 'Bajo',
  'medio': 'Medio',
  'alto': 'Alto',
};

const List<String> kMonthShort = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const List<String> kMonthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

double? _num(dynamic v) => v is num ? v.toDouble() : null;

/// Clima/afluencia de un destino en un mes (para los filtros del buscador).
class MonthContext {
  final String destinationId;
  final int month;
  final Map<String, double> climaPorPreferencia;
  final String? climaNivel;
  final String? climaRiesgo;
  final String? aforoNivel; // Bajo | Medio | Alto
  final double? visitantesMedios;

  const MonthContext({
    required this.destinationId,
    required this.month,
    required this.climaPorPreferencia,
    this.climaNivel,
    this.climaRiesgo,
    this.aforoNivel,
    this.visitantesMedios,
  });

  factory MonthContext.fromJson(Map<String, dynamic> json) {
    final raw = (json['clima_por_preferencia'] as Map?) ?? const {};
    return MonthContext(
      destinationId: (json['destination_id'] ?? '') as String,
      month: (json['month'] as num?)?.toInt() ?? 0,
      climaPorPreferencia: {
        for (final e in raw.entries)
          if (_num(e.value) != null) e.key as String: _num(e.value)!,
      },
      climaNivel: json['clima_nivel'] as String?,
      climaRiesgo: json['clima_riesgo'] as String?,
      aforoNivel: json['aforo_nivel'] as String?,
      visitantesMedios: _num(json['visitantes_medios']),
    );
  }

  /// ¿El clima del mes es favorable (>= 0.70) para esa preferencia?
  bool climateFavorable(String preference) =>
      (climaPorPreferencia[preference] ?? -1) >= kFavorableThreshold;
}

/// Un mes del calendario de un destino.
class CalendarMonth {
  final int month;
  final bool hasData;
  final double? climaScore;
  final String? climaNivel;
  final String? climaRiesgo;
  final String? climaExplicacion;
  final double? tempProm;
  final double? lluviaMm;
  final double? aforoScore;
  final String? aforoNivel;
  final String? aforoExplicacion;
  final double? visitantesMedios;
  final double? combined;

  const CalendarMonth({
    required this.month,
    required this.hasData,
    this.climaScore,
    this.climaNivel,
    this.climaRiesgo,
    this.climaExplicacion,
    this.tempProm,
    this.lluviaMm,
    this.aforoScore,
    this.aforoNivel,
    this.aforoExplicacion,
    this.visitantesMedios,
    this.combined,
  });

  factory CalendarMonth.fromJson(Map<String, dynamic> json) => CalendarMonth(
        month: (json['month'] as num?)?.toInt() ?? 0,
        hasData: json['has_data'] == true,
        climaScore: _num(json['clima_score']),
        climaNivel: json['clima_nivel'] as String?,
        climaRiesgo: json['clima_riesgo'] as String?,
        climaExplicacion: json['clima_explicacion'] as String?,
        tempProm: _num(json['temp_prom']),
        lluviaMm: _num(json['lluvia_mm']),
        aforoScore: _num(json['aforo_score']),
        aforoNivel: json['aforo_nivel'] as String?,
        aforoExplicacion: json['aforo_explicacion'] as String?,
        visitantesMedios: _num(json['visitantes_medios']),
        combined: _num(json['combined']),
      );
}

/// Los 12 meses de un destino, personalizados con la preferencia y tolerancia del usuario.
class DestinationCalendar {
  final String destinationId;
  final String preference;
  final String tolerance;
  final int? bestMonth;
  final int? worstMonth;
  final List<CalendarMonth> months;

  const DestinationCalendar({
    required this.destinationId,
    required this.preference,
    required this.tolerance,
    required this.bestMonth,
    required this.worstMonth,
    required this.months,
  });

  bool get hasAnyData => months.any((m) => m.hasData && m.combined != null);

  factory DestinationCalendar.fromJson(Map<String, dynamic> json) =>
      DestinationCalendar(
        destinationId: (json['destination_id'] ?? '') as String,
        preference: (json['preference'] ?? 'indiferente') as String,
        tolerance: (json['tolerance'] ?? 'media') as String,
        bestMonth: (json['best_month'] as num?)?.toInt(),
        worstMonth: (json['worst_month'] as num?)?.toInt(),
        months: [
          for (final m in (json['months'] as List? ?? const []))
            if (m is Map<String, dynamic>) CalendarMonth.fromJson(m),
        ],
      );
}
