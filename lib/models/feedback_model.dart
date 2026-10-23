class FeedbackModel {
  final String userId;
  final String destinationId;
  final double rating;
  final String comment;

  FeedbackModel({
    required this.userId,
    required this.destinationId,
    required this.rating,
    required this.comment,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
        userId: json['userId'],
        destinationId: json['destinationId'],
        rating: json['rating'].toDouble(),
        comment: json['comment'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'destinationId': destinationId,
        'rating': rating,
        'comment': comment,
      };

  Map<String, dynamic> toApiJson() => {
        'user_id': userId,
        'destination_id': destinationId,
        'rating_general': rating,
        'review_text': comment,
        'aspect_ratings': [],
      };
}
