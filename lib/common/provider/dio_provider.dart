import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱 전체에서 공유되는 인증 Dio 인스턴스.
/// 401 자동 토큰 갱신 인터셉터가 내장되어 있으며,
/// 모든 Repository는 이 Provider를 통해 Dio를 주입받아야 한다.
final authDioProvider = Provider<Dio>((ref) => createAuthDio());
