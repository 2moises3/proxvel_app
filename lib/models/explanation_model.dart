class RecommendationAspectContributionModel {
  final String aspect;
  final double userWeight;
  final double destinationScore;
  final double contribution;

  RecommendationAspectContributionModel({
    required this.aspect,
    required this.userWeight,
    required this.destinationScore,
    required this.contribution,
  });

  factory RecommendationAspectContributionModel.fromJson(Map<String, dynamic> json) =>
      RecommendationAspectContributionModel(
        aspect: json['aspect'] ?? '',
        userWeight: (json['user_weight'] as num?)?.toDouble() ?? 0.0,
        destinationScore: (json['destination_score'] as num?)?.toDouble() ?? 0.0,
        contribution: (json['contribution'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'aspect': aspect,
        'user_weight': userWeight,
        'destination_score': destinationScore,
        'contribution': contribution,
      };
}

class ExplanationModel {
  final double? shapBase;
  final Map<String, double> shapValues;
  final String summary;
  final List<RecommendationAspectContributionModel> topAspects;

  ExplanationModel({
    this.shapBase,
    this.shapValues = const {},
    required this.summary,
    required this.topAspects,
  });

  factory ExplanationModel.fromJson(Map<String, dynamic> json) {
    var aspectsList = json['top_aspects'] as List? ?? [];
    return ExplanationModel(
      shapBase: (json['shap_base'] as num?)?.toDouble(),
      shapValues: {for (final e in (json['shap_values'] as Map? ?? {}).entries) if (e.value is num) e.key.toString(): (e.value as num).toDouble()},
      summary: json['summary'] ?? '',
      topAspects: aspectsList
          .map((i) => RecommendationAspectContributionModel.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'shap_base': shapBase,
        'shap_values': shapValues,
        'summary': summary,
        'top_aspects': topAspects.map((i) => i.toJson()).toList(),
      };
}
