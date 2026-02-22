import 'package:json_annotation/json_annotation.dart';

part 'recommend_model.g.dart';

@JsonSerializable()
class RecommendResult {
  final List<RecommendationModel>? recommendations;

  RecommendResult({this.recommendations});

  factory RecommendResult.fromJson(Map<String, dynamic> json) =>
      _$RecommendResultFromJson(json);
}

/// 스타일 추천 한 건 (camelCase / snake_case 둘 다 처리)
@JsonSerializable(createFactory: false)
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

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      taskId: _intFromJson(json, 'taskId', 'task_id'),
      score: _doubleFromJson(json, 'score'),
      resultImgUrl: json['resultImgUrl'] as String? ?? json['result_img_url'] as String?,
      styleAnalysis: json['styleAnalysis'] as String? ?? json['style_analysis'] as String?,
      topId: _intFromJson(json, 'topId', 'top_id'),
      bottomId: _intFromJson(json, 'bottomId', 'bottom_id'),
    );
  }

  static int? _intFromJson(Map<String, dynamic> json, String key, String keySnake) {
    final v = json[key] ?? json[keySnake];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static double? _doubleFromJson(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }
}