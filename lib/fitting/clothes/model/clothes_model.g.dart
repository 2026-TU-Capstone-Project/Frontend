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
  style: json['style'] as String?,
  texture: json['texture'] as String?,
  buyUrl: json['buyUrl'] as String?,
  createdAt: json['createdAt'] as String?,
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
      'style': instance.style,
      'texture': instance.texture,
      'buyUrl': instance.buyUrl,
      'createdAt': instance.createdAt,
    };
