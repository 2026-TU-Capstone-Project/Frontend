// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_recommendation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherRecommendationItem _$WeatherRecommendationItemFromJson(
  Map<String, dynamic> json,
) => WeatherRecommendationItem(
  taskId: (json['taskId'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
  resultImgUrl: json['resultImgUrl'] as String?,
  styleAnalysis: json['styleAnalysis'] as String?,
  topId: (json['topId'] as num?)?.toInt(),
  bottomId: (json['bottomId'] as num?)?.toInt(),
);

Map<String, dynamic> _$WeatherRecommendationItemToJson(
  WeatherRecommendationItem instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'score': instance.score,
  'resultImgUrl': instance.resultImgUrl,
  'styleAnalysis': instance.styleAnalysis,
  'topId': instance.topId,
  'bottomId': instance.bottomId,
};

WeatherRecommendationData _$WeatherRecommendationDataFromJson(
  Map<String, dynamic> json,
) => WeatherRecommendationData(
  recommendations: (json['recommendations'] as List<dynamic>)
      .map((e) => WeatherRecommendationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WeatherRecommendationDataToJson(
  WeatherRecommendationData instance,
) => <String, dynamic>{'recommendations': instance.recommendations};
