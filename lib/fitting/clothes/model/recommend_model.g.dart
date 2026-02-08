// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendResponse _$RecommendResponseFromJson(Map<String, dynamic> json) =>
    RecommendResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : RecommendData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RecommendResponseToJson(RecommendResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

RecommendData _$RecommendDataFromJson(Map<String, dynamic> json) =>
    RecommendData(
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecommendDataToJson(RecommendData instance) =>
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
