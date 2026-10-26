class FeedbackModel {
  final String userId;
  final String destinationId;
  final double rating;
  final String comment;
  final Map<String, double> aspectRatings;

  FeedbackModel({
    required this.userId,
    required this.destinationId,
    required this.rating,
    required this.comment,
    this.aspectRatings = const {},
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
        userId: json['userId'] ?? json['user_id'] ?? '',
        destinationId: json['destinationId'] ?? json['destination_id'] ?? '',
        rating: (json['rating'] ?? json['rating_general'] ?? 0).toDouble(),
        comment: json['comment'] ?? json['review_text'] ?? '',
        aspectRatings: json['aspect_ratings'] is List
            ? {
                for (var item in json['aspect_ratings'])
                  if (item is Map &&
                      item['aspect'] != null &&
                      item['rating'] != null)
                    item['aspect'].toString():
                        (item['rating'] as num).toDouble(),
              }
            : {},
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'destinationId': destinationId,
        'rating': rating,
        'comment': comment,
        'aspectRatings': aspectRatings,
      };

  Map<String, dynamic> toApiJson() => {
        'user_id': userId,
        'destination_id': destinationId,
        'rating_general': rating,
        'review_text': comment,
        'aspect_ratings': aspectRatings.entries
            .map((e) => {
                  'aspect': e.key,
                  'rating': e.value,
                })
            .toList(),
      };
}
