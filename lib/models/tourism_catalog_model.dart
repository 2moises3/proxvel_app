class TourismCatalogModel {
  final String? city;
  final String? region;
  final String? category;
  final double? altitudeM;
  final String? description;
  final String? activitiesSummary;
  final String? visitorInfoSummary;
  final String? accessibilitySummary;

  /// Ej. "Medio día", "2 a 3 días".
  final String? recommendedDuration;
  final String? howToGet;

  /// 'facil' | 'moderada' | 'exigente'.
  final String? difficulty;
  final String? officialWebsite;

  /// 'bajo' | 'medio' | 'alto'.
  final String? costLevel;
  final double? latitude;
  final double? longitude;
  final List<String> galleryImages;

  /// Intereses del vocabulario de la tesis con los que encaja el destino (en minúsculas).
  final List<String> interestTags;
  final String? dataStatus;

  TourismCatalogModel({
    this.city,
    this.region,
    this.category,
    this.altitudeM,
    this.description,
    this.activitiesSummary,
    this.visitorInfoSummary,
    this.accessibilitySummary,
    this.recommendedDuration,
    this.howToGet,
    this.difficulty,
    this.officialWebsite,
    this.costLevel,
    this.latitude,
    this.longitude,
    this.galleryImages = const [],
    this.interestTags = const [],
    this.dataStatus,
  });

  /// Texto visible de la dificultad, o null si no está cargada.
  String? get difficultyLabel {
    switch (difficulty) {
      case 'facil':
        return 'Fácil';
      case 'moderada':
        return 'Moderada';
      case 'exigente':
        return 'Exigente';
      default:
        return null;
    }
  }

  /// Texto visible del costo estimado, o null si no está cargado.
  String? get costLabel {
    switch (costLevel) {
      case 'bajo':
        return 'Económico';
      case 'medio':
        return 'Costo medio';
      case 'alto':
        return 'Costo alto';
      default:
        return null;
    }
  }

  static String? _clean(dynamic v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  factory TourismCatalogModel.fromJson(Map<String, dynamic> json) {
    return TourismCatalogModel(
      city: _clean(json['city']),
      region: _clean(json['region']),
      category: _clean(json['category']),
      altitudeM: (json['altitude_m'] as num?)?.toDouble(),
      description: _clean(json['description']),
      activitiesSummary: _clean(json['activities_summary']),
      visitorInfoSummary: _clean(json['visitor_info_summary']),
      accessibilitySummary: _clean(json['accessibility_summary']),
      recommendedDuration: _clean(json['recommended_duration']),
      howToGet: _clean(json['how_to_get']),
      difficulty: _clean(json['difficulty']),
      officialWebsite: _clean(json['official_website']),
      costLevel: _clean(json['cost_level']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      galleryImages: (json['gallery_images'] as List<dynamic>?)
              ?.whereType<String>()
              .where((url) => url.isNotEmpty && !url.contains('wikimedia.org/wiki/File:'))
              .toList() ??
          [],
      interestTags:
          (json['interest_tags'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
      dataStatus: json['data_status'] as String?,
    );
  }
}
