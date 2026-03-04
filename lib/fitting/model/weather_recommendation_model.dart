import 'package:json_annotation/json_annotation.dart';

part 'weather_recommendation_model.g.dart';

@JsonSerializable()
class WeatherRecommendationItem {
  final int taskId;
  final double score;
  final String? resultImgUrl;
  final String? styleAnalysis;
  final int? topId;
  final int? bottomId;

  WeatherRecommendationItem({
    required this.taskId,
    required this.score,
    this.resultImgUrl,
    this.styleAnalysis,
    this.topId,
    this.bottomId,
  });

  factory WeatherRecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$WeatherRecommendationItemFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherRecommendationItemToJson(this);
}

@JsonSerializable()
class WeatherRecommendationData {
  final List<WeatherRecommendationItem> recommendations;

  WeatherRecommendationData({required this.recommendations});

  factory WeatherRecommendationData.fromJson(Map<String, dynamic> json) =>
      _$WeatherRecommendationDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherRecommendationDataToJson(this);
}
