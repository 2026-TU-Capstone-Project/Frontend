// lib/clothes/model/clothes_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'clothes_model.g.dart';

@JsonSerializable()
class ClothesModel {
  final int id;
  final String? category;
  final String? name;
  final String? imgUrl;
  final String? brand;
  final int? price;


  final String? color;
  final String? material;
  final String? season;
  final String? fit;
  final String? detail;

  ClothesModel({
    required this.id,
    this.category,
    this.name,
    this.imgUrl,
    this.brand,
    this.price,
    this.color,
    this.material,
    this.season,
    this.fit,
    this.detail,
  });

  factory ClothesModel.fromJson(Map<String, dynamic> json) =>
      _$ClothesModelFromJson(json);
}


@JsonSerializable()
class ClothesListResponse {
  final bool success;
  final String? message;
  final List<ClothesModel> data;

  ClothesListResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory ClothesListResponse.fromJson(Map<String, dynamic> json) =>
      _$ClothesListResponseFromJson(json);
}


@JsonSerializable()
class ClothesDetailResponse {
  final bool success;
  final String? message;
  final ClothesModel data;

  ClothesDetailResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory ClothesDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ClothesDetailResponseFromJson(json);
}