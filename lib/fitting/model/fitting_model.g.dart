// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FittingRequestData _$FittingRequestDataFromJson(Map<String, dynamic> json) =>
    FittingRequestData(taskId: (json['taskId'] as num).toInt());

Map<String, dynamic> _$FittingRequestDataToJson(FittingRequestData instance) =>
    <String, dynamic>{'taskId': instance.taskId};

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

Map<String, dynamic> _$SavedFittingDataToJson(SavedFittingData instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'resultImgUrl': instance.resultImgUrl,
      'createdAt': instance.createdAt,
      'setName': instance.setName,
    };
