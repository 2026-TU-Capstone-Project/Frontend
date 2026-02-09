// lib/fitting/recommend/model/recommend_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'recommend_model.g.dart';

@JsonSerializable()
class RecommendResult {
  final List<RecommendationModel>? recommendations; // 이름을 Model로 통일

  RecommendResult({this.recommendations});

  factory RecommendResult.fromJson(Map<String, dynamic> json) =>
      _$RecommendResultFromJson(json);
}

@JsonSerializable()
class RecommendationModel { // Item -> RecommendationModel로 변경
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