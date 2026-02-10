
import 'package:json_annotation/json_annotation.dart';

part 'recommend_model.g.dart';

@JsonSerializable()
class RecommendResult {
  final List<RecommendationModel>? recommendations;

  RecommendResult({this.recommendations});

  factory RecommendResult.fromJson(Map<String, dynamic> json) =>
      _$RecommendResultFromJson(json);
}

@JsonSerializable()
class RecommendationModel {
  final int? taskId;
  final double? score;
  final String? resultImgUrl;
  final String? styleAnalysis;
  final int? topId;
  final int? bottomId;

  RecommendationModel({
    this.taskId,
    this.score,
    this.resultImgUrl,
    this.styleAnalysis,
    this.topId,
    this.bottomId,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      _$RecommendationModelFromJson(json);
}