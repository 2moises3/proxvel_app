class MapMarkerModel {
  final String destinationId;
  final String destination;
  final double latitude;
  final double longitude;
  final String? category;
  final String? label;

  // Campos adicionales que podrían agregarse en el futuro
  final String? city;
  final String? region;
  final String? coverImageUrl;
  final double? rating;
  final String? description;
  final String? recommendedDuration;

  MapMarkerModel({
    required this.destinationId,
    required this.destination,
    required this.latitude,
    required this.longitude,
    this.category,
    this.label,
    this.city,
    this.region,
    this.coverImageUrl,
    this.rating,
    this.description,
    this.recommendedDuration,
  });

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  String get locationLabel => [
    city,
    region,
  ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().join(' · ');

  MapMarkerModel withCatalog(Map<String, dynamic> item) => MapMarkerModel(
    destinationId: destinationId,
    destination: destination,
    latitude: latitude,
    longitude: longitude,
    category: category,
    label: label,
    city: item['city'] as String?,
    region: item['region'] as String?,
    coverImageUrl: item['cover_image_url'] as String?,
    description: item['description'] as String?,
    recommendedDuration: item['recommended_duration'] as String?,
    // The tourism catalog does not supply review ratings.
    rating: rating,
  );

  factory MapMarkerModel.fromJson(Map<String, dynamic> json) {
    return MapMarkerModel(
      destinationId: json['destination_id'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
      label: json['label'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      description: json['description'] as String?,
      recommendedDuration: json['recommended_duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination_id': destinationId,
      'destination': destination,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'label': label,
      'city': city,
      'region': region,
      'cover_image_url': coverImageUrl,
      'rating': rating,
      'description': description,
      'recommended_duration': recommendedDuration,
    };
  }
}
