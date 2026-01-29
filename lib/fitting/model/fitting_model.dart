// lib/fitting/model/fitting_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'fitting_model.g.dart';

// ==========================================
// 1. [POST] 요청 응답 (껍데기 + 알맹이)
// ==========================================
@JsonSerializable()
class FittingRequestResponse {
  final bool success;
  final FittingRequestData data; // 껍데기 안의 data

  FittingRequestResponse({required this.success, required this.data});

  factory FittingRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$FittingRequestResponseFromJson(json);
}

@JsonSerializable()
class FittingRequestData {
  final int taskId; // ⭐️ String -> int 변경

  FittingRequestData({required this.taskId});

  factory FittingRequestData.fromJson(Map<String, dynamic> json) =>
      _$FittingRequestDataFromJson(json);
}

// ==========================================
// 2. [GET] 상태 조회 응답 (껍데기 + 알맹이)
// ==========================================
@JsonSerializable()
class FittingStatusResponse {
  final bool success;
  final FittingStatusData data; // 껍데기 안의 data

  FittingStatusResponse({required this.success, required this.data});

  factory FittingStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FittingStatusResponseFromJson(json);
}

@JsonSerializable()
class FittingStatusData {
  final int taskId;
  final String status; // 'WAITING', 'COMPLETED' 등
  final String? resultImgUrl; // ⭐️ resultFilename -> resultImgUrl 변경

  FittingStatusData({
    required this.taskId,
    required this.status,
    this.resultImgUrl,
  });

  factory FittingStatusData.fromJson(Map<String, dynamic> json) =>
      _$FittingStatusDataFromJson(json);
}