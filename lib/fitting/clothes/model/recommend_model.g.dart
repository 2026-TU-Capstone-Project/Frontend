// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendResult _$RecommendResultFromJson(Map<String, dynamic> json) =>
    RecommendResult(
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecommendResultToJson(RecommendResult instance) =>
    <String, dynamic>{'recommendations': instance.recommendations};

RecommendationModel _$RecommendationModelFromJson(Map<String, dynamic> json) =>
    RecommendationModel(
      taskId: (json['taskId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble(),
      resultImgUrl: json['resultImgUrl'] as String?,
      styleAnalysis: json['styleAnalysis'] as String?,
      topId: (json['topId'] as num?)?.toInt(),
      bottomId: (json['bottomId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecommendationModelToJson(
  RecommendationModel instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'score': instance.score,
  'resultImgUrl': instance.resultImgUrl,
  'styleAnalysis': instance.styleAnalysis,
  'topId': instance.topId,
  'bottomId': instance.bottomId,
};
