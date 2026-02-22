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
