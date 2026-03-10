import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common/const/Component/custom_text_form_field.dart';
import '../../common/const/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  late final AuthRepository _authRepository;
  late final FlutterSecureStorage _storage;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(Dio(), baseUrl: baseUrl);
    _storage = const FlutterSecureStorage();
  }

  Future<void> _saveTokensAndNavigate(TokenResponse response) async {
    await _storage.write(key: 'ACCESS_TOKEN', value: response.accessToken);
    await _storage.write(key: 'REFRESH_TOKEN', value: response.refreshToken);
    debugPrint('[Auth] 토큰 저장 완료 (accessToken: ${response.accessToken.isNotEmpty ? "있음" : "없음"}, refreshToken: ${response.refreshToken.isNotEmpty ? "있음" : "없음"})');
    await _fetchAndSaveNickname();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootTab()),
      (route) => false,
    );
  }

  Future<void> _fetchAndSaveNickname() async {
    try {
      final authDio = createAuthDio();
      final me = await _authRepository.getMe(authDio);
      if (me?.nickname != null && me!.nickname!.isNotEmpty) {
        await _storage.write(key: 'NICKNAME', value: me.nickname);
      }
    } catch (_) {}
  }

  Future<void> _onLoginPressed() async {
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _authRepository.login(
        email: _email,
        password: _password,
      );
      await _saveTokensAndNavigate(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("아이디 또는 비밀번호를 확인해주세요.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: screenHeight * 0.12,
                  child: Center(
                    child: Image.asset(
                      'asset/img/diverva_logo.jpg',
                      width: 80,
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
                    backgroundColor: AppColors.PRIMARYCOLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: _isLoading ? null : _onLoginPressed,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
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
                          color: AppColors.PRIMARYCOLOR,
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
