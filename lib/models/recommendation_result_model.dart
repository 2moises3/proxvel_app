import 'destination_model.dart';
import 'aspect_score_model.dart';
import 'context_signal_model.dart';
import 'explanation_model.dart';

class RecommendationResultModel {
  final String id;
  final int? rankingPosition;
  final DestinationModel destination;
  final double compatibilityPercentage;
  final double finalScore;
  final String label;
  bool get isEligible => const {
    'recomendado',
    'parcialmente recomendado',
    'parcialmente_recomendado',
  }.contains(label.trim().toLowerCase());
  final String? monthName; // mes objetivo de la recomendación
  final String? bestMonthName; // mejor mes para ir, según el perfil
  final String? contextStatus; // "Clima X · Aforo Y · mes"
  final List<String> reasons;
  final List<AspectScoreModel> aspectScores;
  final List<ContextSignalModel> contextSignals;
  final ExplanationModel? explanation;

  RecommendationResultModel({
    required this.id,
    this.rankingPosition,
    required this.destination,
    required this.compatibilityPercentage,
    required this.finalScore,
    required this.label,
    this.monthName,
    this.bestMonthName,
    this.contextStatus,
    required this.reasons,
    required this.aspectScores,
    required this.contextSignals,
    this.explanation,
  });

  factory RecommendationResultModel.fromApiJson(Map<String, dynamic> json) {
    // Para /recommendations/me (engine_v0)
    final isEngineV0 = json.containsKey('compatibility_percent');

    final compat = isEngineV0
        ? (json['compatibility_percent'] as num?)?.toDouble() ?? 0.0
        : (json['compatibility_percentage'] as num?)?.toDouble() ?? 0.0;

    final score = isEngineV0
        ? (json['compatibility_score'] as num?)?.toDouble() ?? 0.0
        : (json['final_score'] as num?)?.toDouble() ?? 0.0;

    final context = json['context'] as Map<String, dynamic>? ?? {};

    String label =
        json['label'] ??
        (compat >= 55
            ? 'Recomendado'
            : compat >= 45
            ? 'Parcialmente recomendado'
            : 'No recomendado');

    final reasons = <String>[];

    ExplanationModel? parsedExplanation;
    if (json.containsKey('explanation') && json['explanation'] != null) {
      parsedExplanation = ExplanationModel.fromJson(json['explanation']);
      if (parsedExplanation.summary.isNotEmpty) {
        reasons.add(parsedExplanation.summary);
      }
    } else {
      final contextReason = context['context_reason'];
      if (contextReason is String && contextReason.isNotEmpty) {
        reasons.add(contextReason);
      }
      final explanationStr = json['short_explanation'];
      if (explanationStr is String && explanationStr.isNotEmpty) {
        reasons.add(explanationStr);
      }
    }

    final signals = <ContextSignalModel>[];

    if (isEngineV0) {
      final contextStatus = json['context_status'];
      if (contextStatus is String && contextStatus.isNotEmpty) {
        signals.add(
          ContextSignalModel(
            type: 'climate', // default for context_status right now
            value: contextStatus,
            weight: 0.0,
          ),
        );
      }
    } else {
      final weatherCat = context['weather_category'];
      final weatherScore = (context['weather_score'] as num?)?.toDouble();
      if (weatherCat is String && weatherCat.isNotEmpty) {
        signals.add(
          ContextSignalModel(
            type: 'climate',
            value: weatherCat,
            weight: weatherScore ?? 0.0,
          ),
        );
      }
      final crowdLevel = context['crowd_level'];
      final crowdScore = (context['crowd_score'] as num?)?.toDouble();
      if (crowdLevel is String && crowdLevel.isNotEmpty) {
        signals.add(
          ContextSignalModel(
            type: 'crowdLevel',
            value: crowdLevel,
            weight: crowdScore ?? 0.0,
          ),
        );
      }
    }

    final aspects = <AspectScoreModel>[];
    if (parsedExplanation != null) {
      for (var top in parsedExplanation.topAspects) {
        aspects.add(
          AspectScoreModel(aspect: top.aspect, score: top.destinationScore),
        );
      }
    } else {
      final aspectMap = json['aspect_scores'] as Map<String, dynamic>?;
      if (aspectMap != null) {
        aspectMap.forEach((key, value) {
          if (value is num) {
            aspects.add(AspectScoreModel(aspect: key, score: value.toDouble()));
          }
        });
      }
    }

    return RecommendationResultModel(
      id: json['destination_id'] ?? '',
      rankingPosition: json['ranking_position'] as int?,
      destination: DestinationModel.fromApiRecommendation(json),
      compatibilityPercentage: compat,
      finalScore: score,
      label: label,
      monthName: json['month_name'] as String?,
      bestMonthName: json['best_month_name'] as String?,
      contextStatus: json['context_status'] as String?,
      reasons: reasons,
      aspectScores: aspects,
      contextSignals: signals,
      explanation: parsedExplanation,
    );
  }

  factory RecommendationResultModel.fromJson(Map<String, dynamic> json) =>
      RecommendationResultModel(
        id: json['id'],
        rankingPosition: json['rankingPosition'] as int?,
        destination: DestinationModel.fromJson(json['destination']),
        compatibilityPercentage: json['compatibilityPercentage'].toDouble(),
        finalScore: json['finalScore'].toDouble(),
        label: json['label'],
        reasons: List<String>.from(json['reasons'] ?? []),
        aspectScores: (json['aspectScores'] as List)
            .map((i) => AspectScoreModel.fromJson(i))
            .toList(),
        contextSignals: (json['contextSignals'] as List)
            .map((i) => ContextSignalModel.fromJson(i))
            .toList(),
        explanation: json['explanation'] != null
            ? ExplanationModel.fromJson(json['explanation'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'rankingPosition': rankingPosition,
    'destination': destination.toJson(),
    'compatibilityPercentage': compatibilityPercentage,
    'finalScore': finalScore,
    'label': label,
    'reasons': reasons,
    'aspectScores': aspectScores.map((i) => i.toJson()).toList(),
    'contextSignals': contextSignals.map((i) => i.toJson()).toList(),
    'explanation': explanation?.toJson(),
  };
}
