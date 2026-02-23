import 'package:capstone_fe/common/const/data.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../model/auth_model.dart';

part 'auth_client.g.dart';

@RestApi(baseUrl: 'https://$ip')
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;


  @POST('/api/v1/auth/signup')
  Future<void> signup(@Body() SignupBody body);


  @POST('/api/v1/auth/login')
  Future<TokenResponse> login(@Body() LoginBody body);


  @POST('/api/v1/auth/logout')
  Future<void> logout(@Body() LogoutBody body);


  @POST('/api/v1/auth/token/refresh')
  Future<TokenResponse> refreshToken(@Body() RefreshTokenBody body);

  /// OAuth2 리다이렉트 후 받은 임시 키로 accessToken/refreshToken 발급 (소셜 로그인)
  @POST('/api/v1/auth/token/exchange')
  Future<TokenResponse> exchangeTempKey(@Body() ExchangeBody body);

  /// Google Sign-In SDK에서 받은 idToken으로 우리 서버 토큰 발급 (Swagger: loginWithGoogle, Native SDK용)
  @POST('/api/v1/auth/google')
  Future<TokenResponse> loginWithGoogle(@Body() GoogleLoginBody body);

  /// Kakao SDK에서 받은 accessToken으로 우리 서버 토큰 발급 (Swagger: loginWithKakao, Native SDK용)
  @POST('/api/v1/auth/kakao')
  Future<TokenResponse> loginWithKakao(@Body() KakaoLoginBody body);
}