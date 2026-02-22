import 'package:json_annotation/json_annotation.dart';

part 'clothes_set_model.g.dart';

/// 폴더 목록 응답 한 건 (GET /api/v1/clothes-sets)
@JsonSerializable()
class ClothesSetModel {
  final int id;
  final String? setName;
  final String? representativeImageUrl;
  final List<FittingTaskInSet>? fittingTasks;
  final List<ClothesInSet>? clothes;

  ClothesSetModel({
    required this.id,
    this.setName,
    this.representativeImageUrl,
    this.fittingTasks,
    this.clothes,
  });

  factory ClothesSetModel.fromJson(Map<String, dynamic> json) =>
      _$ClothesSetModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClothesSetModelToJson(this);
}

/// 폴더 내 피팅 결과 한 건 (스펙: id, imageUrl)
@JsonSerializable()
class FittingTaskInSet {
  @JsonKey(name: 'id')
  final int? taskId;
  @JsonKey(name: 'imageUrl')
  final String? resultImgUrl;

  FittingTaskInSet({this.taskId, this.resultImgUrl});

  factory FittingTaskInSet.fromJson(Map<String, dynamic> json) =>
      _$FittingTaskInSetFromJson(json);
  Map<String, dynamic> toJson() => _$FittingTaskInSetToJson(this);
}

/// 폴더 내 옷 한 건 (스펙: id, name, category, imgUrl)
@JsonSerializable()
class ClothesInSet {
  final int? id;
  final String? name;
  final String? category;
  final String? imgUrl;

  ClothesInSet({this.id, this.name, this.category, this.imgUrl});

  factory ClothesInSet.fromJson(Map<String, dynamic> json) =>
      _$ClothesInSetFromJson(json);
  Map<String, dynamic> toJson() => _$ClothesInSetToJson(this);
}

/// POST /api/v1/clothes-sets/save 요청 (스펙: setName, clothesIds[], fittingTaskId)
@JsonSerializable()
class SaveClothesSetRequest {
  final String setName;
  final List<int>? clothesIds;
  final int? fittingTaskId;

  SaveClothesSetRequest({
    required this.setName,
    this.clothesIds,
    this.fittingTaskId,
  });

  factory SaveClothesSetRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveClothesSetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SaveClothesSetRequestToJson(this);
}

/// PATCH /api/v1/clothes-sets/{id} 요청 (폴더 이름 수정)
@JsonSerializable()
class UpdateClothesSetRequest {
  final String newName;

  UpdateClothesSetRequest({required this.newName});

  factory UpdateClothesSetRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateClothesSetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateClothesSetRequestToJson(this);
}
