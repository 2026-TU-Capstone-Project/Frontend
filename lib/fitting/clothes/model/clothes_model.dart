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

  /// 두께감 (API 추가 필드)
  final String? thickness;

  /// 넥라인 (API 추가 필드)
  final String? neckLine;

  /// 소매 타입 (API 추가 필드)
  final String? sleeveType;

  /// 패턴 (API 추가 필드)
  final String? pattern;

  /// 잠금/단추 방식 (API 추가 필드)
  final String? closure;

  /// 기장 (API 추가 필드)
  final String? length;

  /// 착용 상황 (API 추가 필드)
  final String? occasion;

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
    this.thickness,
    this.neckLine,
    this.sleeveType,
    this.pattern,
    this.closure,
    this.length,
    this.occasion,
  });

  factory ClothesModel.fromJson(Map<String, dynamic> json) =>
      _$ClothesModelFromJson(json);
}
