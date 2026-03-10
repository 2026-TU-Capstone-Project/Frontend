import 'dart:async';

import 'package:capstone_fe/common/app_router.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bearer 자동 부착 + 401 시 토큰 갱신 후 재시도를 적용한 Dio 인스턴스 생성.
/// 인증이 필요한 API 호출에는 이 Dio를 사용하세요.
Dio createAuthDio() {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  const storage = FlutterSecureStorage();

  /// Bearer를 붙이지 않을 Auth 경로
  bool isAuthPath(String path) {
    final p = path.toLowerCase();
    return p.contains('auth/login') ||
        p.contains('auth/signup') ||
        p.contains('auth/logout') ||
        p.contains('auth/token/refresh') ||
        p.contains('auth/token/exchange') ||
        p.contains('auth/google') ||
        p.contains('auth/kakao');
  }

  /// 401 시 refresh 재시도용 락 (동시 다중 401이면 refresh 한 번만 수행)
  Completer<String?>? _refreshCompleter;

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      if (isAuthPath(options.path)) {
        return handler.next(options);
      }
      final token = await storage.read(key: 'ACCESS_TOKEN');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode != 401) {
        return handler.next(error);ㅈ
      }

      final path = error.requestOptions.path;
      if (path.contains('auth/token/refresh')) {
        await storage.deleteAll();
        _navigateToLogin();
        return handler.next(error);
      }

      if (_refreshCompleter != null) {
        try {
          final newToken = await _refreshCompleter!.future;
          if (newToken != null && newToken.isNotEmpty) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        } catch (_) {}
        return handler.next(error);
      }

      _refreshCompleter = Completer<String?>();
      String? newToken;

      try {
        final refreshToken = await storage.read(key: 'REFRESH_TOKEN');
        if (refreshToken == null || refreshToken.isEmpty) {
          await storage.deleteAll();
          _refreshCompleter!.complete(null);
          _navigateToLogin();
          return handler.next(error);
        }
        final authRepo = AuthRepository(Dio(BaseOptions(baseUrl: baseUrl)), baseUrl: baseUrl);
        final tokens = await authRepo.refreshTokens(refreshToken: refreshToken);
        await storage.write(key: 'ACCESS_TOKEN', value: tokens.accessToken);
        await storage.write(key: 'REFRESH_TOKEN', value: tokens.refreshToken);
        newToken = tokens.accessToken;
      } catch (_) {
        await storage.deleteAll();
        _navigateToLogin();
      }

      _refreshCompleter!.complete(newToken);
      _refreshCompleter = null;

      if (newToken != null && newToken.isNotEmpty) {
        error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e is DioException ? e : error);
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}

void _navigateToLogin() {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
