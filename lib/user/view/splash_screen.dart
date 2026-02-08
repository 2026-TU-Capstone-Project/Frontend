import 'package:dio/dio.dart'; // Dio 추가
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/common/const/data.dart'; // IP 주소 가져오기

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
    checkToken();
  }

  void checkToken() async {
    final storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    // 1. 토큰이 아예 없으면 -> 로그인 화면으로
    if (accessToken == null) {
      _moveToLogin();
      return;
    }

    // 2. 토큰이 있으면 -> 서버에 유효한지 찔러보기 (검증)
    try {
      final dio = Dio();

      // 헤더에 토큰 심기
      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      // 💡 꿀팁: 로그인이 필요한 가벼운 API 아무거나 호출해보면 됩니다.
      // (여기서는 '내 옷장 목록 조회' API를 사용해서 테스트합니다)
      await dio.get('http://$ip/api/clothes');

      // 여기까지 에러 없이 왔다면 토큰은 살아있는 것! -> 홈으로
      _moveToRootTab();

    } catch (e) {
      // 3. 에러 발생 (토큰 만료 or 서버 오류)
      print("토큰 만료 또는 에러 발생: $e");

      // 썩은 토큰 삭제 (청소)
      await storage.deleteAll();

      // 다시 로그인 하러 가라
      _moveToLogin();
    }
  }

  // 화면 이동 함수들 (코드 깔끔하게 분리)
  void _moveToRootTab() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RootTab()),
          (route) => false,
    );
  }

  void _moveToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PRIMARYCOLOR,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'asset/img/logo.svg',
              width: MediaQuery.of(context).size.width / 2.0,
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}