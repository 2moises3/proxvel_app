import 'package:flutter/material.dart';

/// Opción de interés mostrada al viajero. Lleva un SVG de `assets/icons` o,
/// si no hay asset propio, un icono de Material.
class InterestOption {
  final String label;
  final String? svgAsset;
  final IconData? icon;

  const InterestOption(this.label, {this.svgAsset, this.icon});
}

/// Vocabulario del perfil viajero. DEBE coincidir con el del motor de
/// recomendación (tesis, Fase 3): un interés fuera de esta lista no suma
/// coincidencias con ningún destino, y un interés que el backend usa pero
/// la app no ofrece nunca se puede elegir.
///
/// Si se cambia aquí, hay que cambiar también `INTEREST_VOCAB` en
/// `proxvel_backend/app/services/recommendation_engine_v1.py`.
class TravelerVocabulary {
  TravelerVocabulary._();

  /// Los 13 intereses de la tesis (etiqueta visible → se guarda en minúsculas).
  static const List<InterestOption> interests = [
    InterestOption('Naturaleza', svgAsset: 'palm_tree.svg'),
    InterestOption('Cultura', svgAsset: 'museum.svg'),
    InterestOption('Historia', icon: Icons.account_balance_rounded),
    InterestOption('Gastronomía', svgAsset: 'pot_of_food.svg'),
    InterestOption('Aventura', svgAsset: 'hiking_boot.svg'),
    InterestOption('Montañismo', icon: Icons.terrain_rounded),
    InterestOption('Fotografía', icon: Icons.photo_camera_outlined),
    InterestOption('Playa', svgAsset: 'beach_20.svg'),
    InterestOption('Urbano', svgAsset: 'cityscape.svg'),
    InterestOption('Rural', svgAsset: 'farm.svg'),
    InterestOption('Académico', svgAsset: 'man_student_2.svg'),
    InterestOption('Relax', svgAsset: 'spa.svg'),
    InterestOption('Familiar', svgAsset: 'family.svg'),
  ];

  static List<String> get interestLabels =>
      interests.map((i) => i.label).toList(growable: false);

  /// Climas que entiende el motor (tesis, Fase 4).
  static const List<String> climates = [
    'Frío',
    'Templado',
    'Cálido',
    'Seco',
    'Indiferente',
  ];

  /// Tolerancia a las multitudes. Se guarda en femenino, como la tesis.
  static const List<String> crowdTolerances = ['Baja', 'Media', 'Alta'];

  /// Valor canónico para guardar: 'Bajo'/'baja'/'moderado'/... → 'baja' | 'media' | 'alta'.
  static String crowdToleranceValue(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'baja' || v == 'bajo') return 'baja';
    if (v == 'alta' || v == 'alto') return 'alta';
    return 'media'; // media, medio, moderado/a o desconocido
  }
}
