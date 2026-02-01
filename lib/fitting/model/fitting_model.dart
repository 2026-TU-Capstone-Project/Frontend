
import 'package:json_annotation/json_annotation.dart';

part 'fitting_model.g.dart';

@JsonSerializable()
class FittingRequestResponse {
  final bool success;
  final FittingRequestData data;

  FittingRequestResponse({required this.success, required this.data});

  factory FittingRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$FittingRequestResponseFromJson(json);
}

@JsonSerializable()
class FittingRequestData {
  final int taskId;

  FittingRequestData({required this.taskId});

  factory FittingRequestData.fromJson(Map<String, dynamic> json) =>
      _$FittingRequestDataFromJson(json);
}


@JsonSerializable()
class FittingStatusResponse {
  final bool success;
  final FittingStatusData data;

  FittingStatusResponse({required this.success, required this.data});

  factory FittingStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FittingStatusResponseFromJson(json);
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