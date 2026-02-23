import 'dart:convert';

import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/const/colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후에 검증 실행 → 네비게이션 시 context 보장
    WidgetsBinding.instance.addPostFrameCallback((_) => checkToken());
  }

  /// JWT payload의 base64url 디코딩 (패딩·문자 치환 처리)
  static String _decodeBase64Url(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      case 0:
        break;
      default:
        throw FormatException('Invalid base64url length');
    }
    return utf8.decode(base64Url.decode(output));
  }

  /// AccessToken JWT 만료 여부 (검증 실패/파싱 오류 시 만료로 간주)
  bool isTokenExpired(String token) {
    if (token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payloadJson = _decodeBase64Url(parts[1]);
      final payloadMap = json.decode(payloadJson) as Map<String, dynamic>?;
      if (payloadMap == null || !payloadMap.containsKey('exp')) return true;

      final exp = payloadMap['exp'];
      if (exp == null) return true;
      // JWT exp: 초 단위 Unix timestamp → 밀리초로 변환
      final expMs = (exp is int ? exp : (exp as num).round()) * 1000;
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(expMs);
      return DateTime.now().isAfter(expirationDate);
    } catch (_) {
      return true;
    }
  }

  Future<void> checkToken() async {
    final storage = const FlutterSecureStorage();
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');
    final refreshToken = await storage.read(key: 'REFRESH_TOKEN');

    // 토큰 없음 → 로그인 화면 (Native SDK 소셜 로그인은 로그인 화면에서 처리)
    final hasAccess = accessToken != null && accessToken.trim().isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.trim().isNotEmpty;
    if (!hasAccess || !hasRefresh) {
      _moveToLogin();
      return;
    }

    if (!isTokenExpired(accessToken)) {
      await _syncNicknameFromServer(storage);
      if (!mounted) return;
      _moveToRootTab();
      return;
    }

    // Access 만료 → Refresh로 갱신 시도
    try {
      final authRepository = AuthRepository(Dio(), baseUrl: baseUrl);
      final newTokens = await authRepository.refreshTokens(refreshToken: refreshToken);
      await storage.write(key: 'ACCESS_TOKEN', value: newTokens.accessToken);
      await storage.write(key: 'REFRESH_TOKEN', value: newTokens.refreshToken);
      await _syncNicknameFromServer(storage);
      if (!mounted) return;
      _moveToRootTab();
    } catch (_) {
      await storage.deleteAll();
      _moveToLogin();
    }
  }

  /// 서버 "내 정보" API에서 닉네임 조회 후 로컬 저장. API 없으면 무시.
  Future<void> _syncNicknameFromServer(FlutterSecureStorage storage) async {
    try {
      final authDio = createAuthDio();
      final me = await AuthRepository(Dio(), baseUrl: baseUrl).getMe(authDio);
      if (me?.nickname != null && me!.nickname!.isNotEmpty) {
        await storage.write(key: 'NICKNAME', value: me.nickname);
      }
    } catch (_) {}
  }

  void _moveToRootTab() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootTab()),
          (route) => false,
    );
  }

  void _moveToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'asset/img/logo.svg',
              width: MediaQuery.of(context).size.width / 2.0,
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
      backgroundColor: AppColors.PRIMARYCOLOR,
    );
  }
}