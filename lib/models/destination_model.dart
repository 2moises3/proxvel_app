class DestinationModel {
  final String id;
  final String name;
  final String city;
  final String region;
  final String category;
  final String description;
  final String imageUrl;
  final double averageCost;
  final String climate;
  final String crowdLevel;
  final double rating;
  final int reviewsCount;
  final List<String> aspects;
  final double? distanceKm;
  final String? estimatedDays;
  final bool isTrending;
  final double? latitude;
  final double? longitude;

  /// Nivel de costo estimado: 'bajo' | 'medio' | 'alto' (dato editorial; null si no está cargado).
  final String? costLevel;

  // ── Campos extendidos para "Sobre el destino" ──
  final double? altitudeM;      // Altitude in meters
  final String? bestSeason;     // e.g. 'Abril - Octubre'
  final List<String> activities;  // e.g. ['Caminata', 'Fotografía', ...]
  final List<String> galleryImages; // Additional image asset paths

  DestinationModel({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.averageCost,
    required this.climate,
    required this.crowdLevel,
    required this.rating,
    this.reviewsCount = 0,
    required this.aspects,
    this.distanceKm,
    this.estimatedDays,
    this.isTrending = false,
    this.latitude,
    this.longitude,
    this.costLevel,
    this.altitudeM,
    this.bestSeason,
    this.activities = const [],
    this.galleryImages = const [],
  });

  /// True si la imagen proviene del backend (URL http) y no de assets.
  bool get isNetworkImage => imageUrl.startsWith('http');

  /// Copia el destino reemplazando imagen principal y galería
  /// (usado para conservar assets locales cuando la API no trae imagen).
  DestinationModel copyWithImage(String newImageUrl, List<String> newGallery) =>
      DestinationModel(
        id: id,
        name: name,
        city: city,
        region: region,
        category: category,
        description: description,
        imageUrl: newImageUrl,
        averageCost: averageCost,
        climate: climate,
        crowdLevel: crowdLevel,
        rating: rating,
        reviewsCount: reviewsCount,
        aspects: aspects,
        distanceKm: distanceKm,
        estimatedDays: estimatedDays,
        isTrending: isTrending,
        latitude: latitude,
        longitude: longitude,
        costLevel: costLevel,
        altitudeM: altitudeM,
        bestSeason: bestSeason,
        activities: activities,
        galleryImages: newGallery.isNotEmpty ? newGallery : galleryImages,
      );

  /// Construye un destino desde un item del ranking contextual del backend
  /// (GET /recommendations/contextual). Respuesta plana con snake_case.
  factory DestinationModel.fromApiRecommendation(Map<String, dynamic> json) {
    final context = json['context'] as Map<String, dynamic>? ?? {};
    final tourism = json['tourism_summary'] as Map<String, dynamic>? ?? {};
    final rawImageUrl = json['cover_image_url'] as String? ?? '';
    final imageUrl = isValidImageUrl(rawImageUrl) ? rawImageUrl : '';

    return DestinationModel(
      id: json['destination_id'] ?? '',
      // El motor V1 manda el nombre en 'name'; 'destination' es respaldo.
      name: json['name'] ?? json['destination'] ?? '',
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      category: json['category'] ?? '',
      description: tourism['description'] ?? '',
      imageUrl: imageUrl,
      averageCost: 0.0,
      climate: context['weather_category'] ?? '',
      crowdLevel: context['crowd_level'] ?? '',
      rating: json['rating']?.toDouble() ?? (tourism['rating']?.toDouble() ?? 0.0),
      reviewsCount: json['reviews_count'] ?? (tourism['reviews_count'] ?? 0),
      aspects: const [],
      latitude: _parseDouble(json['latitude'] ?? tourism['latitude']),
      longitude: _parseDouble(json['longitude'] ?? tourism['longitude']),
    );
  }

  /// Construye un destino desde el catálogo general del backend (GET /api/v1/destinations).
  factory DestinationModel.fromApiCatalog(Map<String, dynamic> json) {
    final rawImageUrl = json['cover_image_url'] as String? ?? '';
    final imageUrl = isValidImageUrl(rawImageUrl) ? rawImageUrl : '';

    return DestinationModel(
      id: json['destination_id'] ?? '',
      name: json['destination'] ?? '',
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      category: json['category'] ?? '',
      description: '', // El listado no trae descripción larga
      imageUrl: imageUrl,
      averageCost: 0.0,
      climate: '', // No disponible en el catálogo base
      crowdLevel: '', // No disponible en el catálogo base
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] ?? 0,
      aspects: const [],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      costLevel: json['cost_level'] as String?,
    );
  }

  /// Construye un destino desde un modelo de favorito (GET /favorites).
  factory DestinationModel.fromFavoriteModel(dynamic fav) {
    final rawImageUrl = fav.coverImageUrl ?? '';
    final imageUrl = isValidImageUrl(rawImageUrl) ? rawImageUrl : '';

    return DestinationModel(
      id: fav.destinationId,
      name: fav.name,
      city: fav.city ?? '',
      region: fav.region ?? '',
      category: fav.category ?? '',
      description: '', 
      imageUrl: imageUrl,
      averageCost: 0.0,
      climate: '', 
      crowdLevel: '', 
      rating: fav.rating ?? 0.0,
      reviewsCount: 0, // FavoriteModel no expone reviewsCount; evita NoSuchMethodError
      aspects: const [],
      latitude: null, // FavoriteModel no los expone aún
      longitude: null,
    );
  }

  /// Construye un destino desde el detalle del backend
  /// (GET /destinations/{id}). Incluye clima/aforo del contexto.
  factory DestinationModel.fromApiDetail(Map<String, dynamic> json) {
    final context = json['context'] as Map<String, dynamic>? ?? {};
    final tourism = json['tourism_info'] as Map<String, dynamic>? ?? {};
    
    final rawGallery = (tourism['gallery_images'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
        
    final gallery = rawGallery.where((url) => isValidImageUrl(url)).toList();
    
    final rawImageUrl = json['cover_image_url'] as String? ?? '';
    final coverImageUrl = isValidImageUrl(rawImageUrl) ? rawImageUrl : '';

    // 1. La portada siempre manda.
    // Solo si no hay portada real, usamos la primera de la galería.
    final finalImageUrl = coverImageUrl.isNotEmpty 
        ? coverImageUrl 
        : (gallery.isNotEmpty ? gallery.first : '');

    // 2. Evitar que la portada aparezca duplicada en la galería.
    if (coverImageUrl.isNotEmpty) {
      gallery.removeWhere((url) => url.trim() == coverImageUrl.trim());
    }

    return DestinationModel(
      id: json['destination_id'] ?? '',
      name: json['destination'] ?? '',
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      category: json['category'] ?? '',
      description: tourism['description'] ?? '',
      imageUrl: finalImageUrl,
      averageCost: 0.0,
      climate: context['weather_category'] ?? '',
      crowdLevel: context['crowd_level'] ?? '',
      rating: json['rating']?.toDouble() ?? (tourism['rating']?.toDouble() ?? 0.0),
      reviewsCount: json['reviews_count'] ?? (tourism['reviews_count'] ?? 0),
      aspects: const [],
      latitude: _parseDouble(json['latitude'] ?? tourism['latitude']),
      longitude: _parseDouble(json['longitude'] ?? tourism['longitude']),
      galleryImages: gallery,
      costLevel: json['cost_level'] as String?,
    );
  }

  factory DestinationModel.fromJson(Map<String, dynamic> json) => DestinationModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        region: json['region'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        averageCost: (json['averageCost'] as num?)?.toDouble() ?? 0.0,
        climate: json['climate'] as String? ?? '',
        crowdLevel: json['crowdLevel'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        aspects: List<String>.from(json['aspects'] ?? const []),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        estimatedDays: json['estimatedDays'] as String?,
        isTrending: json['isTrending'] as bool? ?? false,
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        altitudeM: (json['altitudeM'] as num?)?.toDouble(),
        bestSeason: json['bestSeason'] as String?,
        activities: List<String>.from(json['activities'] ?? const []),
        galleryImages: List<String>.from(json['galleryImages'] ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'region': region,
        'category': category,
        'description': description,
        'imageUrl': imageUrl,
        'averageCost': averageCost,
        'climate': climate,
        'crowdLevel': crowdLevel,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'aspects': aspects,
        'distanceKm': distanceKm,
        'estimatedDays': estimatedDays,
        'isTrending': isTrending,
        'latitude': latitude,
        'longitude': longitude,
        'altitudeM': altitudeM,
        'bestSeason': bestSeason,
        'activities': activities,
        'galleryImages': galleryImages,
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Verifica rígidamente si un string es una URL o asset de imagen válido.
  /// Rechaza páginas HTML (ej. Wikimedia/Wikipedia) y strings mal formados ("null").
  static bool isValidImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
    
    if (!trimmed.startsWith('http')) {
      return trimmed.startsWith('assets/');
    }
    
    final lowerUrl = trimmed.toLowerCase();
    
    // Rechazar explícitamente páginas HTML de Wikipedia/Wikimedia
    if (lowerUrl.contains('/wiki/')) return false;
    if (lowerUrl.contains('wikimedia.org/wiki/file:')) return false;
    
    // Aceptar cualquier URL HTTP válida (Supabase/Railway pueden no tener extensión explícita)
    return true;
  }
}
