import 'dart:ffi' hide Size;

import 'package:capstone_fe/common/Component/custom_text_form_field.dart';
import 'package:capstone_fe/common/Component/social_login_button.dart';
import 'package:capstone_fe/common/const.dart';
import 'package:capstone_fe/view/Home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: screenHeight * 0.25,
                  child: Center(
                      child: Image.asset('asset/img/logo3.png',
                      fit: BoxFit.contain,
                      ),
                  ),
                ),
                CustomTextFormField(
                  onChanged: (String Value) {},
                  hintText: '이메일을 입력해 주세요',
                ),
                SizedBox(height: 16.0),
                CustomTextFormField(
                  onChanged: (StringValue) {},
                  hintText: '비밀번호를 입력해주세요',
                  obscureText: true,
                ),
                SizedBox(height: 14.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: PRIMARYCOLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) =>HomeScreen())
                    );
                  },
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 14.0),
                SvgPicture.asset('asset/img/notice.svg'),
                SocialLoginButton(
                    assetPath: 'asset/img/kakao_original.svg',
                    text: 'Kakao로 시작하기',
                    backgroundColor: Color(0XFFFEE500),
                    textColor: Colors.black
                ),
                SocialLoginButton(
                    assetPath: 'asset/img/google_original.svg',
                    text: 'Google로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                  isBorder: true,
                ),
                SocialLoginButton(
                    assetPath: 'asset/img/apple_original.svg',
                    text: 'Apple로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                  isBorder: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
