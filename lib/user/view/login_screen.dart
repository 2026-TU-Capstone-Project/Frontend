import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
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

  late final AuthRepository _authRepository;
  late final FlutterSecureStorage _storage;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _authRepository = AuthRepository(dio, baseUrl: baseUrl);
    _storage = const FlutterSecureStorage();
    _googleSignIn = GoogleSignIn(
      serverClientId: googleServerClientId.isNotEmpty ? googleServerClientId : null,
    );
  }

  /// 토큰 저장 후 서버에서 닉네임 조회 → 메인(루트 탭)으로 이동
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

  /// 서버 "내 정보" API에서 닉네임 조회 후 로컬 저장. API 없으면 무시.
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

  /// [Native SDK] Google 로그인 → idToken → POST /api/v1/auth/google → 토큰 저장 → 메인
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
            const SnackBar(content: Text('Google idToken을 받지 못했습니다. data.dart에 googleServerClientId(Web 클라이언트 ID)를 설정해 주세요.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      final response = await _authRepository.loginWithGoogle(idToken: idToken);
      await _saveTokensAndNavigate(response);
    } on PlatformException catch (e) {
      if (mounted) {
        final isChannelError = e.code == 'channel-error' || (e.message ?? '').contains('connection on channel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChannelError
                  ? 'Google 로그인: 네이티브 연결 실패. 실기기에서 실행하거나, Google Cloud Console에서 Android OAuth 클라이언트 ID·SHA-1 등록을 확인해 주세요.'
                  : 'Google 로그인 실패: ${e.message ?? e.code}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll(RegExp(r'^Exception: '), '');
        final isNetworkOrSafari = msg.contains('network') ||
            msg.contains('Network') ||
            msg.contains('Safari') ||
            msg.contains('연결') ||
            msg.contains('유실');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkOrSafari
                  ? 'Google 로그인 중 연결이 끊겼습니다. 네트워크를 확인하고, 가능하면 실기기에서 다시 시도해 주세요.'
                  : 'Google 로그인 실패: $msg',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// [Native SDK] 카카오 로그인: 앱 설치 시 카카오톡 앱 로그인, 미설치(시뮬레이터 등) 시 카카오계정 웹 로그인
  Future<void> _onKakaoPressed() async {
    if (!mounted) return;
    if (kakaoNativeAppKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('data.dart에 kakaoNativeAppKey(카카오 네이티브 앱 키)를 설정해 주세요.')),
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
      final response = await _authRepository.loginWithKakao(accessToken: token.accessToken);
      await _saveTokensAndNavigate(response);
    } on KakaoAuthException catch (e) {
      final msg = e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.contains('cancel') || msg.contains('취소') ? '카카오 로그인이 취소되었습니다.' : '카카오 로그인 실패: $msg')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isHostsNotInit = msg.contains("'hosts' has not been initialized") || msg.contains('LateInitializationError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHostsNotInit
                  ? '카카오 SDK 초기화 오류. main.dart에서 KakaoSdk.init(nativeAppKey: kakaoNativeAppKey)가 호출되는지, data.dart에 kakaoNativeAppKey가 설정돼 있는지 확인해 주세요.'
                  : '카카오 로그인 실패: ${msg.replaceAll(RegExp(r'^Exception: '), '')}',
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

                const SizedBox(height: 20.0),

                SvgPicture.asset('asset/img/notice.svg'),
                SocialLoginButton(
                  assetPath: 'asset/img/kakao_original.svg',
                  text: 'Kakao로 시작하기',
                  backgroundColor: const Color(0XFFFEE500),
                  textColor: Colors.black,
                  onPressed: _isLoading ? null : _onKakaoPressed,
                ),
                SocialLoginButton(
                  assetPath: 'asset/img/google_original.svg',
                  text: 'Google로 시작하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  isBorder: true,
                  onPressed: _isLoading ? null : _onGooglePressed,
                ),
                SocialLoginButton(
                  assetPath: 'asset/img/apple_original.svg',
                  text: 'Apple로 시작하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  isBorder: true,
                  onPressed: _isLoading
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Apple 로그인은 준비 중입니다.')),
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
