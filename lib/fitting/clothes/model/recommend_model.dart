import 'package:json_annotation/json_annotation.dart';

part 'recommend_model.g.dart';

@JsonSerializable()
class RecommendResponse {
  final bool success;
  final String? message; // String? 으로 변경
  final RecommendData? data;

  RecommendResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> json) => _$RecommendResponseFromJson(json);
}

@JsonSerializable()
class RecommendData {
  final List<RecommendationModel>? recommendations; // List? 로 변경

  RecommendData({
    this.recommendations,
  });

  factory RecommendData.fromJson(Map<String, dynamic> json) => _$RecommendDataFromJson(json);
}

@JsonSerializable()
class RecommendationModel {
  final int? taskId;         // int? 로 변경
  final double? score;       // double? 로 변경
  final String? resultImgUrl; // String? 로 변경
  final String? styleAnalysis;// String? 로 변경
  final int? topId;          // int? 로 변경
  final int? bottomId;       // int? 로 변경

  RecommendationModel({
    this.taskId,
    this.score,
    this.resultImgUrl,
    this.styleAnalysis,
    this.topId,
    this.bottomId,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) => _$RecommendationModelFromJson(json);
}