// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothes_set_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClothesSetModel _$ClothesSetModelFromJson(Map<String, dynamic> json) =>
    ClothesSetModel(
      id: (json['id'] as num).toInt(),
      setName: json['setName'] as String?,
      representativeImageUrl: json['representativeImageUrl'] as String?,
      fittingTasks: (json['fittingTasks'] as List<dynamic>?)
          ?.map((e) => FittingTaskInSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      clothes: (json['clothes'] as List<dynamic>?)
          ?.map((e) => ClothesInSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClothesSetModelToJson(ClothesSetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'setName': instance.setName,
      'representativeImageUrl': instance.representativeImageUrl,
      'fittingTasks': instance.fittingTasks,
      'clothes': instance.clothes,
    };

FittingTaskInSet _$FittingTaskInSetFromJson(Map<String, dynamic> json) =>
    FittingTaskInSet(
      taskId: (json['id'] as num?)?.toInt(),
      resultImgUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$FittingTaskInSetToJson(FittingTaskInSet instance) =>
    <String, dynamic>{'id': instance.taskId, 'imageUrl': instance.resultImgUrl};

ClothesInSet _$ClothesInSetFromJson(Map<String, dynamic> json) => ClothesInSet(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  category: json['category'] as String?,
  imgUrl: json['imgUrl'] as String?,
);

Map<String, dynamic> _$ClothesInSetToJson(ClothesInSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'imgUrl': instance.imgUrl,
    };

SaveClothesSetRequest _$SaveClothesSetRequestFromJson(
  Map<String, dynamic> json,
) => SaveClothesSetRequest(
  setName: json['setName'] as String,
  clothesIds: (json['clothesIds'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  fittingTaskId: (json['fittingTaskId'] as num?)?.toInt(),
);

Map<String, dynamic> _$SaveClothesSetRequestToJson(
  SaveClothesSetRequest instance,
) => <String, dynamic>{
  'setName': instance.setName,
  'clothesIds': instance.clothesIds,
  'fittingTaskId': instance.fittingTaskId,
};

UpdateClothesSetRequest _$UpdateClothesSetRequestFromJson(
  Map<String, dynamic> json,
) => UpdateClothesSetRequest(newName: json['newName'] as String);

Map<String, dynamic> _$UpdateClothesSetRequestToJson(
  UpdateClothesSetRequest instance,
) => <String, dynamic>{'newName': instance.newName};
