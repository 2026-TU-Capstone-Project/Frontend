import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 가상 피팅용 유저 정보: 정면 사진 + 상의/하의 사이즈 3가지
/// iOS 채널 오류 방지를 위해 SharedPreferences 대신 파일(JSON)로 저장
class FittingProfile {
  final String? frontImagePath;
  final String? topSize;
  final String? bottomSize;
  final bool onboardingCompleted;

  FittingProfile({
    this.frontImagePath,
    this.topSize,
    this.bottomSize,
    this.onboardingCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'frontImagePath': frontImagePath,
    'topSize': topSize,
    'bottomSize': bottomSize,
    'onboardingCompleted': onboardingCompleted,
  };

  factory FittingProfile.fromJson(Map<String, dynamic> json) => FittingProfile(
    frontImagePath: json['frontImagePath'] as String?,
    topSize: json['topSize'] as String?,
    bottomSize: json['bottomSize'] as String?,
    onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  );

  bool get hasAnyData =>
      onboardingCompleted ||
      frontImagePath != null ||
      (topSize != null && topSize!.isNotEmpty) ||
      (bottomSize != null && bottomSize!.isNotEmpty);

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
      await file.writeAsString(jsonEncode(profile.toJson()), flush: true);
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
      return FittingProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
