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


    if (accessToken == null) {
      _moveToLogin();
      return;
    }

    try {
      final dio = Dio();

      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      await dio.get('http://$ip/api/clothes');


      _moveToRootTab();

    } catch (e) {

      print("토큰 만료 또는 에러 발생: $e");


      await storage.deleteAll();


      _moveToLogin();
    }
  }

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