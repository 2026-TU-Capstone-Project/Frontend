// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothes_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClothesModel _$ClothesModelFromJson(Map<String, dynamic> json) => ClothesModel(
  id: (json['id'] as num).toInt(),
  category: json['category'] as String?,
  name: json['name'] as String?,
  imgUrl: json['imgUrl'] as String?,
  brand: json['brand'] as String?,
  price: (json['price'] as num?)?.toInt(),
  color: json['color'] as String?,
  material: json['material'] as String?,
  season: json['season'] as String?,
  fit: json['fit'] as String?,
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$ClothesModelToJson(ClothesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'imgUrl': instance.imgUrl,
      'brand': instance.brand,
      'price': instance.price,
      'color': instance.color,
      'material': instance.material,
      'season': instance.season,
      'fit': instance.fit,
      'detail': instance.detail,
    };

ClothesListResponse _$ClothesListResponseFromJson(Map<String, dynamic> json) =>
    ClothesListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>)
          .map((e) => ClothesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClothesListResponseToJson(
  ClothesListResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ClothesDetailResponse _$ClothesDetailResponseFromJson(
  Map<String, dynamic> json,
) => ClothesDetailResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: ClothesModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ClothesDetailResponseToJson(
  ClothesDetailResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
