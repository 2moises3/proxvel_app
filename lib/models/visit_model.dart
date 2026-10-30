class VisitModel {
  final String visitId;
  final String destinationId;
  final String? destinationName;
  final String visitStatus; // in_progress | verified | rejected
  final String validationMethod;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int dwellMinutes;
  final int minDwellMinutes;
  final int remainingMinutes;
  final double? distanceMeters;
  final int? geofenceRadiusMeters;

  VisitModel({
    required this.visitId,
    required this.destinationId,
    this.destinationName,
    required this.visitStatus,
    this.validationMethod = 'gps_geofence',
    this.startedAt,
    this.completedAt,
    this.dwellMinutes = 0,
    this.minDwellMinutes = 20,
    this.remainingMinutes = 20,
    this.distanceMeters,
    this.geofenceRadiusMeters,
  });

  bool get isVerified => visitStatus == 'verified';
  bool get isInProgress => visitStatus == 'in_progress';

  /// Progreso de 0.0 a 1.0 hacia la certificación de visita
  double get progress {
    if (isVerified) return 1.0;
    if (minDwellMinutes <= 0) return 1.0;
    final total = minDwellMinutes.toDouble();
    final elapsed = dwellMinutes.toDouble();
    final ratio = elapsed / total;
    return ratio.clamp(0.0, 1.0);
  }

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      visitId: json['visit_id'] ?? '',
      destinationId: json['destination_id'] ?? '',
      destinationName: json['destination_name'],
      visitStatus: json['visit_status'] ?? 'in_progress',
      validationMethod: json['validation_method'] ?? 'gps_geofence',
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      dwellMinutes: (json['dwell_minutes'] as num?)?.toInt() ?? 0,
      minDwellMinutes: (json['min_dwell_minutes'] as num?)?.toInt() ?? 20,
      remainingMinutes: (json['remaining_minutes'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      geofenceRadiusMeters: (json['geofence_radius_meters'] as num?)?.toInt(),
    );
  }
}

class AtlasItemModel {
  final String visitId;
  final String destinationId;
  final String destinationName;
  final String? region;
  final String? city;
  final String? category;
  final String? coverImageUrl;
  final DateTime completedAt;
  final int dwellMinutes;
  final String validationMethod;

  AtlasItemModel({
    required this.visitId,
    required this.destinationId,
    required this.destinationName,
    this.region,
    this.city,
    this.category,
    this.coverImageUrl,
    required this.completedAt,
    required this.dwellMinutes,
    this.validationMethod = 'gps_geofence',
  });

  factory AtlasItemModel.fromJson(Map<String, dynamic> json) {
    return AtlasItemModel(
      visitId: json['visit_id'] ?? '',
      destinationId: json['destination_id'] ?? '',
      destinationName: json['destination_name'] ?? json['destination_id'] ?? 'Destino',
      region: json['region'],
      city: json['city'],
      category: json['category'],
      coverImageUrl: json['cover_image_url'],
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at']) ?? DateTime.now()
          : DateTime.now(),
      dwellMinutes: (json['dwell_minutes'] as num?)?.toInt() ?? 0,
      validationMethod: json['validation_method'] ?? 'gps_geofence',
    );
  }
}

class AtlasSummaryModel {
  final int totalVerifiedVisits;
  final int regionsVisited;
  final List<AtlasItemModel> visits;

  AtlasSummaryModel({
    required this.totalVerifiedVisits,
    required this.regionsVisited,
    required this.visits,
  });

  factory AtlasSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = (json['visits'] as List<dynamic>?)
            ?.map((e) => AtlasItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return AtlasSummaryModel(
      totalVerifiedVisits: (json['total_verified_visits'] as num?)?.toInt() ?? list.length,
      regionsVisited: (json['regions_visited'] as num?)?.toInt() ?? 0,
      visits: list,
    );
  }
}

class PendingSealDestination {
  final String destinationId;
  final String destinationName;
  final double latitude;
  final double longitude;
  final String? region;
  final String? coverImageUrl;
  final double? distanceMeters;
  final int geofenceRadiusMeters;
  final int minDwellMinutes;

  PendingSealDestination({
    required this.destinationId,
    required this.destinationName,
    required this.latitude,
    required this.longitude,
    this.region,
    this.coverImageUrl,
    this.distanceMeters,
    this.geofenceRadiusMeters = 250,
    this.minDwellMinutes = 20,
  });

  PendingSealDestination copyWith({double? distanceMeters}) {
    return PendingSealDestination(
      destinationId: destinationId,
      destinationName: destinationName,
      latitude: latitude,
      longitude: longitude,
      region: region,
      coverImageUrl: coverImageUrl,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      geofenceRadiusMeters: geofenceRadiusMeters,
      minDwellMinutes: minDwellMinutes,
    );
  }
}
