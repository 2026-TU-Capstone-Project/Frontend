import 'package:capstone_fe/user/view/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import '../../common/const/Component/custom_text_form_field.dart';
import '../../common/const/colors.dart';
import '../component/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  String _email = '';
  String _password = '';

  bool _isLoading = false;


  Future<void> _onLoginPressed() async {

    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();

      final repository = AuthRepository(dio, baseUrl: 'http://$ip');


      final accessToken = await repository.login(
        email: _email,
        password: _password,
      );


      final storage = const FlutterSecureStorage();
      await storage.write(key: 'ACCESS_TOKEN', value: accessToken);

      print("로그인 성공! 토큰 저장 완료.");

      if (!mounted) return;


      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootTab()),
            (route) => false,
      );

    } catch (e) {

      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아이디 또는 비밀번호를 확인해주세요.")),
      );
    } finally {

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                    child: Image.asset(
                      'asset/img/logo3.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),


                CustomTextFormField(
                  onChanged: (String value) {
                    _email = value;
                  },
                  hintText: '이메일을 입력해 주세요',
                ),
                const SizedBox(height: 16.0),


                CustomTextFormField(
                  onChanged: (String value) {
                    _password = value;
                  },
                  hintText: '비밀번호를 입력해주세요',
                  obscureText: true,
                ),
                const SizedBox(height: 14.0),


                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: PRIMARYCOLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),

                  onPressed: _isLoading ? null : _onLoginPressed,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                SvgPicture.asset('asset/img/notice.svg'),
                SocialLoginButton(
                    assetPath: 'asset/img/kakao_original.svg',
                    text: 'Kakao로 시작하기',
                    backgroundColor: const Color(0XFFFEE500),
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
                SizedBox(height: 30,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("계정이 없으신가요? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {

                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        "회원가입",
                        style: TextStyle(
                          color: PRIMARYCOLOR,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}