// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatHistoryItem _$ChatHistoryItemFromJson(Map<String, dynamic> json) =>
    ChatHistoryItem(
      role: json['role'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$ChatHistoryItemToJson(ChatHistoryItem instance) =>
    <String, dynamic>{'role': instance.role, 'content': instance.content};

ChatRequestDto _$ChatRequestDtoFromJson(Map<String, dynamic> json) =>
    ChatRequestDto(
      message: json['message'] as String?,
      history: (json['history'] as List<dynamic>?)
          ?.map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      temp: (json['temp'] as num?)?.toDouble(),
      rain: (json['rain'] as num?)?.toDouble(),
      snow: (json['snow'] as num?)?.toDouble(),
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toInt(),
      tempOrDefault: json['tempOrDefault'] as bool?,
      rainOrDefault: json['rainOrDefault'] as bool?,
      snowOrDefault: json['snowOrDefault'] as bool?,
      windSpeedOrDefault: json['windSpeedOrDefault'] as bool?,
      humidityOrDefault: json['humidityOrDefault'] as bool?,
    );

Map<String, dynamic> _$ChatRequestDtoToJson(ChatRequestDto instance) =>
    <String, dynamic>{
      'message': ?instance.message,
      'history': ?instance.history,
      'temp': ?instance.temp,
      'rain': ?instance.rain,
      'snow': ?instance.snow,
      'windSpeed': ?instance.windSpeed,
      'humidity': ?instance.humidity,
      'tempOrDefault': ?instance.tempOrDefault,
      'rainOrDefault': ?instance.rainOrDefault,
      'snowOrDefault': ?instance.snowOrDefault,
      'windSpeedOrDefault': ?instance.windSpeedOrDefault,
      'humidityOrDefault': ?instance.humidityOrDefault,
    };

ChatResponseData _$ChatResponseDataFromJson(Map<String, dynamic> json) =>
    ChatResponseData(
      message: json['message'] as String?,
      recommendations: json['recommendations'] == null
          ? null
          : RecommendationsWrapper.fromJson(
              json['recommendations'] as Map<String, dynamic>,
            ),
      recommendationsTops: json['recommendationsTops'] == null
          ? null
          : ClothesItemsWrapper.fromJson(
              json['recommendationsTops'] as Map<String, dynamic>,
            ),
      recommendationsBottoms: json['recommendationsBottoms'] == null
          ? null
          : ClothesItemsWrapper.fromJson(
              json['recommendationsBottoms'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ChatResponseDataToJson(ChatResponseData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'recommendations': instance.recommendations,
      'recommendationsTops': instance.recommendationsTops,
      'recommendationsBottoms': instance.recommendationsBottoms,
    };

RecommendationsWrapper _$RecommendationsWrapperFromJson(
  Map<String, dynamic> json,
) => RecommendationsWrapper(
  recommendations: (json['recommendations'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : RecommendationItem.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$RecommendationsWrapperToJson(
  RecommendationsWrapper instance,
) => <String, dynamic>{'recommendations': instance.recommendations};

RecommendationItem _$RecommendationItemFromJson(Map<String, dynamic> json) =>
    RecommendationItem(
      taskId: (json['taskId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble(),
      resultImgUrl: json['resultImgUrl'] as String?,
      styleAnalysis: json['styleAnalysis'] as String?,
      topId: (json['topId'] as num?)?.toInt(),
      bottomId: (json['bottomId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecommendationItemToJson(RecommendationItem instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'score': instance.score,
      'resultImgUrl': instance.resultImgUrl,
      'styleAnalysis': instance.styleAnalysis,
      'topId': instance.topId,
      'bottomId': instance.bottomId,
    };

ClothesItemsWrapper _$ClothesItemsWrapperFromJson(Map<String, dynamic> json) =>
    ClothesItemsWrapper(
      items: (json['items'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : ClothesScoreItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ClothesItemsWrapperToJson(
  ClothesItemsWrapper instance,
) => <String, dynamic>{'items': instance.items};

ClothesScoreItem _$ClothesScoreItemFromJson(Map<String, dynamic> json) =>
    ClothesScoreItem(
      clothes: json['clothes'] == null
          ? null
          : ClothesModel.fromJson(json['clothes'] as Map<String, dynamic>),
      score: (json['score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ClothesScoreItemToJson(ClothesScoreItem instance) =>
    <String, dynamic>{'clothes': instance.clothes, 'score': instance.score};
