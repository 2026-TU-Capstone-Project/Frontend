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
  final String? style;
  final String? texture;
  final String? buyUrl;
  final String? createdAt;

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
    this.style,
    this.texture,
    this.buyUrl,
    this.createdAt,
  });

  factory ClothesModel.fromJson(Map<String, dynamic> json) =>
      _$ClothesModelFromJson(json);
}