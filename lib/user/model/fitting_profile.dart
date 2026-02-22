import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 온보딩에서 입력한 가상 피팅용 유저 정보 (전신 사진 경로 + 신체 스펙)
/// iOS 채널 오류 방지를 위해 SharedPreferences 대신 파일(JSON)로 저장
class FittingProfile {
  final String? frontImagePath;
  final String? sideImagePath;
  final String? height;
  final String? weight;
  final String? topSize;
  final String? bottomSize;
  final String? shoeSize;

  FittingProfile({
    this.frontImagePath,
    this.sideImagePath,
    this.height,
    this.weight,
    this.topSize,
    this.bottomSize,
    this.shoeSize,
  });

  Map<String, dynamic> toJson() => {
        'frontImagePath': frontImagePath,
        'sideImagePath': sideImagePath,
        'height': height,
        'weight': weight,
        'topSize': topSize,
        'bottomSize': bottomSize,
        'shoeSize': shoeSize,
      };

  factory FittingProfile.fromJson(Map<String, dynamic> json) => FittingProfile(
        frontImagePath: json['frontImagePath'] as String?,
        sideImagePath: json['sideImagePath'] as String?,
        height: json['height'] as String?,
        weight: json['weight'] as String?,
        topSize: json['topSize'] as String?,
        bottomSize: json['bottomSize'] as String?,
        shoeSize: json['shoeSize'] as String?,
      );

  bool get hasAnyData =>
      frontImagePath != null ||
      sideImagePath != null ||
      (height != null && height!.isNotEmpty) ||
      (weight != null && weight!.isNotEmpty) ||
      (topSize != null && topSize!.isNotEmpty) ||
      (bottomSize != null && bottomSize!.isNotEmpty) ||
      (shoeSize != null && shoeSize!.isNotEmpty);

  static const String _fileName = 'fitting_profile.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${dir.path}/fitting_profile');
    if (!await profileDir.exists()) await profileDir.create(recursive: true);
    return File('${profileDir.path}/$_fileName');
  }

  static Future<void> save(FittingProfile profile) async {
    try {
      final file = await _getFile();
      await file.writeAsString(
        jsonEncode(profile.toJson()),
        flush: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<FittingProfile?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return FittingProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
