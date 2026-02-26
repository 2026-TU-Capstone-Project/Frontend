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
/// 스펙: 항목에 id, resultImgUrl, topClothes, bottomClothes 등. id를 taskId로 매핑.
@JsonSerializable(createFactory: false)
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

  factory SavedFittingData.fromJson(Map<String, dynamic> json) {
    final taskIdRaw = json['taskId'] ?? json['id'];
    final taskId = taskIdRaw == null
        ? null
        : (taskIdRaw is int ? taskIdRaw : (taskIdRaw as num).toInt());
    return SavedFittingData(
      taskId: taskId,
      resultImgUrl: json['resultImgUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      setName: json['setName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$SavedFittingDataToJson(this);
}