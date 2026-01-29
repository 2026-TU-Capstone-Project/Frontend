// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FittingRequestResponse _$FittingRequestResponseFromJson(
  Map<String, dynamic> json,
) => FittingRequestResponse(
  success: json['success'] as bool,
  data: FittingRequestData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FittingRequestResponseToJson(
  FittingRequestResponse instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

FittingRequestData _$FittingRequestDataFromJson(Map<String, dynamic> json) =>
    FittingRequestData(taskId: (json['taskId'] as num).toInt());

Map<String, dynamic> _$FittingRequestDataToJson(FittingRequestData instance) =>
    <String, dynamic>{'taskId': instance.taskId};

FittingStatusResponse _$FittingStatusResponseFromJson(
  Map<String, dynamic> json,
) => FittingStatusResponse(
  success: json['success'] as bool,
  data: FittingStatusData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FittingStatusResponseToJson(
  FittingStatusResponse instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

FittingStatusData _$FittingStatusDataFromJson(Map<String, dynamic> json) =>
    FittingStatusData(
      taskId: (json['taskId'] as num).toInt(),
      status: json['status'] as String,
      resultImgUrl: json['resultImgUrl'] as String?,
    );

Map<String, dynamic> _$FittingStatusDataToJson(FittingStatusData instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'status': instance.status,
      'resultImgUrl': instance.resultImgUrl,
    };
