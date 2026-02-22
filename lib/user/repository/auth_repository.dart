import 'package:dio/dio.dart';
import 'package:capstone_fe/user/repository/auth_client.dart';
import '../model/auth_model.dart';

/// 서버 "내 정보" 응답 (닉네임 등). API 경로/필드는 백엔드 스펙에 맞게 수정.
class MeResponse {
  final String? nickname;

  MeResponse({this.nickname});

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
        nickname: json['nickname'] as String?,
      );
}

class AuthRepository {
  final AuthClient _client;
  final String? baseUrl;

  AuthRepository(Dio dio, {String? baseUrl})
      : _client = AuthClient(dio, baseUrl: baseUrl),
        baseUrl = baseUrl;


  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,

  }) async {
    try {
      await _client.signup(SignupBody(
        email: email,
        password: password,
        nickname: nickname,

      ));
      return true;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }


  Future<TokenResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.login(LoginBody(
        email: email,
        password: password,
      ));
      return response;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('이메일 또는 비밀번호가 잘못되었습니다.');
      }
      throw Exception('로그인 실패: $e');
    }
  }


  Future<void> logout({required String refreshToken}) async {
    try {
      await _client.logout(LogoutBody(refreshToken: refreshToken));
    } catch (e) {
      throw Exception('로그아웃 서버 처리 실패: $e');
    }
  }


  Future<TokenResponse> refreshTokens({required String refreshToken}) async {
    try {
      final response = await _client.refreshToken(
          RefreshTokenBody(refreshToken: refreshToken)
      );
      return response;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('만료된 Refresh Token입니다. 다시 로그인해주세요.');
      }
      throw Exception('토큰 갱신 실패: $e');
    }
  }


  Future<TokenResponse> exchangeTempKey({required String tempKey}) async {
    try {
      return await _client.exchangeTempKey(ExchangeBody(tempKey: tempKey));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('유효하지 않거나 만료된 임시 키입니다.');
      }
      throw Exception('토큰 교환 실패: $e');
    }
  }


  Future<TokenResponse> loginWithGoogle({required String idToken}) async {
    try {
      return await _client.loginWithGoogle(GoogleLoginBody(idToken: idToken));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Google 로그인 검증에 실패했습니다.');
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('idToken이 올바르지 않습니다.');
      }
      throw Exception('Google 로그인 실패: $e');
    }
  }


  Future<TokenResponse> loginWithKakao({required String accessToken}) async {
    try {
      return await _client.loginWithKakao(KakaoLoginBody(accessToken: accessToken));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Kakao 로그인 검증에 실패했습니다.');
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('accessToken이 올바르지 않습니다.');
      }
      throw Exception('Kakao 로그인 실패: $e');
    }
  }

  /// 내 정보 조회 (Bearer 필요). 서버에 GET /api/v1/users/me 등이 있으면 호출.
  /// 없거나 404면 null 반환 → 닉네임은 회원가입 시 로컬 저장분만 사용.
  Future<MeResponse?> getMe(Dio authDio) async {
    try {
      final response = await authDio.get<Map<String, dynamic>>(
        '/api/v1/users/me',
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data == null) return null;
      return MeResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}