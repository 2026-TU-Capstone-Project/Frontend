import 'package:json_annotation/json_annotation.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';

part 'chat_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Request
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class ChatRequestDto {
  final String? message;

  ChatRequestDto({this.message});

  factory ChatRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRequestDtoToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Response root: ApiResponse<ChatResponseData>.data
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class ChatResponseData {
  /// 챗봇 응답 메시지 텍스트
  final String? message;

  /// 코디 추천 (resultImgUrl 포함 전체 세트)
  final RecommendationsWrapper? recommendations;

  /// 상의 단품 추천 목록
  final ClothesItemsWrapper? recommendationsTops;

  /// 하의 단품 추천 목록
  final ClothesItemsWrapper? recommendationsBottoms;

  ChatResponseData({
    this.message,
    this.recommendations,
    this.recommendationsTops,
    this.recommendationsBottoms,
  });

  factory ChatResponseData.fromJson(Map<String, dynamic> json) =>
      _$ChatResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatResponseDataToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper: recommendations.recommendations (1-depth 래퍼)
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class RecommendationsWrapper {
  final List<RecommendationItem?>? recommendations;

  RecommendationsWrapper({this.recommendations});

  factory RecommendationsWrapper.fromJson(Map<String, dynamic> json) =>
      _$RecommendationsWrapperFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationsWrapperToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Item: 코디 추천 개별 항목
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class RecommendationItem {
  final int? taskId;
  final double? score;
  final String? resultImgUrl;
  final String? styleAnalysis;
  final int? topId;
  final int? bottomId;

  RecommendationItem({
    this.taskId,
    this.score,
    this.resultImgUrl,
    this.styleAnalysis,
    this.topId,
    this.bottomId,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$RecommendationItemFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationItemToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper: recommendationsTops.items / recommendationsBottoms.items (1-depth 래퍼)
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class ClothesItemsWrapper {
  final List<ClothesScoreItem?>? items;

  ClothesItemsWrapper({this.items});

  factory ClothesItemsWrapper.fromJson(Map<String, dynamic> json) =>
      _$ClothesItemsWrapperFromJson(json);

  Map<String, dynamic> toJson() => _$ClothesItemsWrapperToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Item: 상의/하의 단품 + 유사도 점수 쌍
// ClothesModel은 lib/fitting/clothes/model/clothes_model.dart에서 임포트
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class ClothesScoreItem {
  final ClothesModel? clothes;
  final double? score;

  ClothesScoreItem({this.clothes, this.score});

  factory ClothesScoreItem.fromJson(Map<String, dynamic> json) =>
      _$ClothesScoreItemFromJson(json);

  Map<String, dynamic> toJson() => _$ClothesScoreItemToJson(this);
}
