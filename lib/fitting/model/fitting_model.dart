import 'package:json_annotation/json_annotation.dart';

part 'fitting_model.g.dart';

// 껍데기(Response) 클래스들은 모두 지우고, 데이터(Data) 클래스만 남깁니다.

@JsonSerializable()
class FittingRequestData {
  final int taskId;

  FittingRequestData({required this.taskId});

  factory FittingRequestData.fromJson(Map<String, dynamic> json) =>
      _$FittingRequestDataFromJson(json);
}

@JsonSerializable()
class FittingStatusData {
  final int taskId;
  final String status;
  final String? resultImgUrl;

  FittingStatusData({
    required this.taskId,
    required this.status,
    this.resultImgUrl,
  });

  factory FittingStatusData.fromJson(Map<String, dynamic> json) =>
      _$FittingStatusDataFromJson(json);
}

/// 내가 저장한 코디 목록 응답 (GET /api/v1/virtual-fitting/my-closet)
@JsonSerializable()
class SavedFittingData {
  final int? taskId;
  final String? resultImgUrl;
  final String? createdAt;
  final String? setName;

  SavedFittingData({
    this.taskId,
    this.resultImgUrl,
    this.createdAt,
    this.setName,
  });

  factory SavedFittingData.fromJson(Map<String, dynamic> json) =>
      _$SavedFittingDataFromJson(json);
  Map<String, dynamic> toJson() => _$SavedFittingDataToJson(this);
}