import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';

import '../../common/const/Component/custom_text_form_field.dart';
import '../../common/const/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  String _email = '';
  String _password = '';
  String _nickname = '';

  bool _isLoading = false;

  Future<void> _onSignupPressed() async {

    if (_email.isEmpty || _password.isEmpty || _nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 정보를 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();



      final repository = AuthRepository(dio, baseUrl: 'http://$ip');


      await repository.signUp(
        email: _email,
        password: _password,
        nickname: _nickname,
        username: _email,
      );

      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원가입이 완료되었습니다! 로그인해주세요.")),
      );


      Navigator.of(context).pop();

    } catch (e) {

      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원가입 실패: ${e.toString()}")),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("회원가입", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "환영합니다!\n정보를 입력하고 시작해보세요.",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32.0),

              const Text("이메일", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8.0),
              CustomTextFormField(
                onChanged: (String value) {
                  _email = value;
                },
                hintText: '이메일을 입력해 주세요',
              ),
              const SizedBox(height: 24.0),

              const Text("비밀번호", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8.0),
              CustomTextFormField(
                onChanged: (String value) {
                  _password = value;
                },
                hintText: '비밀번호를 입력해 주세요',
                obscureText: true,
              ),
              const SizedBox(height: 24.0),

              const Text("닉네임", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8.0),
              CustomTextFormField(
                onChanged: (String value) {
                  _nickname = value;
                },
                hintText: '닉네임을 입력해 주세요',
              ),
              const SizedBox(height: 40.0),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: PRIMARYCOLOR,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _onSignupPressed,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '가입하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}