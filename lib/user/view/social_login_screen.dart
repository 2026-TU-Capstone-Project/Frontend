import 'package:capstone_fe/common/const/data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../common/const/colors.dart';
import '../component/social_login_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  bool _isLoading = false;

  late final AuthRepository _authRepository;
  late final FlutterSecureStorage _storage;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(Dio(), baseUrl: baseUrl);
    _storage = const FlutterSecureStorage();
    _googleSignIn = GoogleSignIn(
      serverClientId: googleServerClientId.isNotEmpty
          ? googleServerClientId
          : null,
    );
  }

  Future<void> _saveTokensAndNavigate(TokenResponse response) async {
    await _storage.write(key: 'ACCESS_TOKEN', value: response.accessToken);
    await _storage.write(key: 'REFRESH_TOKEN', value: response.refreshToken);
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

  Future<void> _onGooglePressed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google idToken을 받지 못했습니다.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      final response = await _authRepository.loginWithGoogle(idToken: idToken);
      await _saveTokensAndNavigate(response);
    } on PlatformException catch (e) {
      if (mounted) {
        final isChannelError =
            e.code == 'channel-error' ||
            (e.message ?? '').contains('connection on channel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChannelError
                  ? 'Google 로그인: 네이티브 연결 실패. 실기기에서 실행하거나 OAuth 클라이언트 ID를 확인해 주세요.'
                  : 'Google 로그인 실패: ${e.message ?? e.code}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll(RegExp(r'^Exception: '), '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google 로그인 실패: $msg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onKakaoPressed() async {
    if (!mounted) return;
    if (kakaoNativeAppKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('data.dart에 kakaoNativeAppKey를 설정해 주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      if (!mounted) return;
      final response = await _authRepository.loginWithKakao(
        accessToken: token.accessToken,
      );
      await _saveTokensAndNavigate(response);
    } on KakaoAuthException catch (e) {
      final msg = e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.contains('cancel') || msg.contains('취소')
                  ? '카카오 로그인이 취소되었습니다.'
                  : '카카오 로그인 실패: $msg',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '카카오 로그인 실패: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'asset/img/diverva_logo.jpg',
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '다이버바',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 36,
                    color: AppColors.BLACK,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '나만의 스타일을 찾아보세요',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Spacer(),
              SocialLoginButton(
                assetPath: 'asset/img/kakao_original.svg',
                text: '카카오로 계속하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: Colors.black,
                onPressed: _isLoading ? null : _onKakaoPressed,
              ),
              SocialLoginButton(
                assetPath: 'asset/img/google_original.svg',
                text: 'Google로 계속하기',
                backgroundColor: Colors.white,
                textColor: Colors.black,
                isBorder: true,
                onPressed: _isLoading ? null : _onGooglePressed,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      '다이버바 회원 로그인',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '로그인 시 개인정보 제공에 동의합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
