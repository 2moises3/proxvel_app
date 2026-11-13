import 'destination_names.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_es.dart';
import '../../models/seasonality_model.dart';
import '../../models/traveler_types.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEs();

  String destinationTitle(String? id, String original) =>
      l10n.localeName == 'en'
      ? englishDestinationNames[id] ?? original
      : original;

  String errorText(String original, {String? fallback}) {
    if (original.trim().isEmpty && fallback != null) return fallback;
    if (l10n.localeName != 'en') return original;
    final text = original.toLowerCase();
    if (text.contains('correo o contraseña incorrectos')) {
      return 'Incorrect email or password. Check your details.';
    }
    if (text.contains('sesión expiró')) {
      return 'Your session expired. Sign in again.';
    }
    if (text.contains('desactivada') ||
        text.contains('proceso de eliminación')) {
      return 'Your account is disabled or pending deletion.';
    }
    if (text.contains('permiso')) {
      return 'You do not have permission to do this.';
    }
    if (text.contains('ubicación tardó')) {
      return 'Location timed out. Check your GPS and try again.';
    }
    if (text.contains('ubicación está bloqueada')) {
      return 'Location is blocked in your browser. Allow it in the site settings.';
    }
    if (text.contains('ubicación')) {
      return fallback ??
          'Could not get your location. Check your location settings and try again.';
    }
    if (text.contains('conexión') ||
        text.contains('conectar con el servidor')) {
      return l10n.uiNoHayConexionConElServidor;
    }
    return fallback ?? l10n.uiNoPudimosCompletarLaAccionIntenta;
  }

  String fullMonth(int month) => l10n.localeName == 'en'
      ? DateFormat.MMMM('en').format(DateTime(2000, month))
      : kMonthNames[month - 1];

  String aspectLabel(String value) {
    if (l10n.localeName != 'en') return value;
    final key = value.trim().toLowerCase();
    if (key.startsWith('atractivo')) return 'Attractions and scenery';
    if (key.startsWith('seguridad')) return 'Safety';
    if (key.startsWith('gastronom')) return 'Food';
    if (key.startsWith('limpieza')) return 'Cleanliness';
    if (key.startsWith('accesibilidad')) return 'Accessibility and transport';
    if (key.startsWith('costo') || key.startsWith('valoración de precios')) {
      return 'Costs and prices';
    }
    if (key.startsWith('atención') || key.startsWith('atencion')) {
      return 'Service and guides';
    }
    if (key.startsWith('clima')) return 'Weather';
    if (key.startsWith('alojamiento')) return 'Accommodation';
    if (key.startsWith('aforo') || key.startsWith('tranquilidad')) {
      return 'Crowd levels';
    }
    return value;
  }

  String categoryLabel(String category) => switch (category.toLowerCase()) {
    'arqueología' => l10n.archaeology,
    'naturaleza' => l10n.nature,
    'museo' => l10n.museum,
    'recreación' => l10n.recreation,
    _ => category,
  };

  String shortMonth(int month) => l10n.localeName == 'en'
      ? DateFormat.MMM('en').format(DateTime(2000, month))
      : kMonthShort[month - 1];

  String travelerLabel(String code) => switch (code) {
    'cultural' => l10n.culturalTraveler,
    'naturalista' => l10n.natureTraveler,
    'familiar' => l10n.familyTraveler,
    'economico_mochilero' => l10n.backpacker,
    'gastronomico' => l10n.foodTraveler,
    'aventurero' => l10n.adventureTraveler,
    'urbano_recreativo' => l10n.urbanTraveler,
    _ => travelerTypes[code] ?? code,
  };

  String interestLabel(String label) => switch (label.toLowerCase()) {
    'naturaleza' => l10n.nature,
    'cultura' => l10n.culture,
    'historia' => l10n.history,
    'gastronomía' || 'gastronomia' => l10n.food,
    'aventura' => l10n.adventure,
    'montañismo' || 'montanismo' => l10n.mountaineering,
    'fotografía' || 'fotografia' => l10n.photography,
    'playa' => l10n.beach,
    'urbano' => l10n.urban,
    'rural' => l10n.rural,
    'académico' || 'academico' => l10n.academic,
    'relax' => l10n.relaxation,
    'familiar' => l10n.familyTraveler,
    _ => label,
  };

  String preferenceLabel(String label) => switch (label) {
    'Bajo' => l10n.low,
    'Medio' => l10n.medium,
    'Alto' => l10n.high,
    'Lujo' => l10n.luxury,
    'Frío' => l10n.cold,
    'Templado' => l10n.mild,
    'Cálido' => l10n.warm,
    'Seco' => l10n.dry,
    'Indiferente' => l10n.anyWeather,
    _ => label,
  };
}
