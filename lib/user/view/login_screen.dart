import 'package:app_links/app_links.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/view/root_tab.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _authRepository = AuthRepository(dio, baseUrl: baseUrl);
    _storage = const FlutterSecureStorage();
    _listenDeepLink();
    _handleInitialLink();
  }

  /// 콜드스타트 시 앱이 딥링크로 열렸을 수 있음 (소셜 로그인 리다이렉트)
  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _tryExchangeAndNavigate(uri);
    } catch (_) {}
  }

  /// 브라우저에서 lookpick://auth?key= 로 복귀할 때 수신
  void _listenDeepLink() {
    _appLinks.uriLinkStream.listen((Uri uri) {
      _tryExchangeAndNavigate(uri);
    });
  }

  /// lookpick://auth?key= 임시키 → token/exchange → 저장 → 서버에서 닉네임 조회 → RootTab
  Future<void> _tryExchangeAndNavigate(Uri uri) async {
    if (uri.scheme != deepLinkScheme || uri.host != deepLinkHost) return;
    final key = uri.queryParameters['key'];
    if (key == null || key.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _authRepository.exchangeTempKey(tempKey: key.trim());
      await _storage.write(key: 'ACCESS_TOKEN', value: response.accessToken);
      await _storage.write(key: 'REFRESH_TOKEN', value: response.refreshToken);
      await _fetchAndSaveNickname();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootTab()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('소셜 로그인 처리 실패: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 토큰 저장 후 서버에서 닉네임 조회 → 메인(루트 탭)으로 이동 (일반 로그인)
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

  /// 소셜 로그인: OAuth2 진입 URL을 브라우저로 열기 → 로그인 후 lookpick://auth?key= 로 앱 복귀 → exchange
  Future<void> _onGooglePressed() async {
    final uri = Uri.parse(oauth2GoogleUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 페이지를 열 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _onKakaoPressed() async {
    final uri = Uri.parse(oauth2KakaoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 페이지를 열 수 없습니다.')),
        );
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
