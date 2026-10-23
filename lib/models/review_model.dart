class ReviewModel {
  /// Identificador de la reseña (para reportarla).
  final String? reviewId;
  final double ratingGeneral;
  final String reviewText;
  final String userId;
  final String? destinationId;
  /// Nombre visible del destino (null si el backend no lo envía).
  final String? destinationName;
  /// Autor visible («Lucía P.»); null si el backend no lo envía.
  final String? authorName;
  final String? createdAt;
  final String? status;
  final String? processingMonth;
  final Map<String, dynamic> aspectRatings;

  ReviewModel({
    this.reviewId,
    required this.ratingGeneral,
    required this.reviewText,
    required this.userId,
    this.destinationId,
    this.destinationName,
    this.authorName,
    this.createdAt,
    this.status,
    this.processingMonth,
    this.aspectRatings = const {},
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedAspects = {};
    if (json['aspect_ratings'] is List) {
      for (var item in json['aspect_ratings']) {
        if (item is Map<String, dynamic> && item.containsKey('aspect') && item.containsKey('rating')) {
          parsedAspects[item['aspect'].toString()] = item['rating'];
        }
      }
    } else if (json['aspect_ratings'] is Map) {
      parsedAspects = Map<String, dynamic>.from(json['aspect_ratings']);
    }

    return ReviewModel(
      reviewId: json['review_id'] as String?,
      ratingGeneral: (json['rating_general'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['review_text'] as String? ?? '',
      userId: json['user_id'] as String? ?? 'Anónimo',
      destinationId: json['destination_id'] as String?,
      destinationName: json['destination_name'] as String?,
      authorName: json['author_name'] as String?,
      createdAt: json['created_at'] as String?,
      status: json['status'] as String?,
      processingMonth: json['processing_month'] as String?,
      aspectRatings: parsedAspects,
    );
  }
}
