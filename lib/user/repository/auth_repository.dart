import 'dart:io';

import 'package:dio/dio.dart';
import 'package:capstone_fe/user/repository/auth_client.dart';
import '../model/auth_model.dart';

class AuthRepository {
  final AuthClient _client;
  final String? baseUrl;

  AuthRepository(Dio dio, {String? baseUrl})
    : _client = AuthClient(dio, baseUrl: baseUrl),
      baseUrl = baseUrl;

  Future<bool> signUp({
    required String email,
    required String password,
    required String gender,
  }) async {
    try {
      await _client.signup(
        SignupBody(email: email, password: password, gender: gender),
      );
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
      final response = await _client.login(
        LoginBody(email: email, password: password),
      );
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
        RefreshTokenBody(refreshToken: refreshToken),
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
      return await _client.loginWithKakao(
        KakaoLoginBody(accessToken: accessToken),
      );
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

  /// 마이페이지 조회 (GET /api/v1/users/me). Bearer 필요.
  /// 응답이 { success, message, data } 래핑이면 data 안 객체로 파싱.
  Future<UserMe?> getMe(Dio authDio) async {
    try {
      final response = await authDio.get<Map<String, dynamic>>(
        '/api/v1/users/me',
        options: Options(responseType: ResponseType.json),
      );
      final body = response.data;
      if (body == null) return null;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return UserMe.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 마이페이지 수정 (PATCH /api/v1/users/me).
  /// multipart/form-data: nickname, height, weight, gender(MALE|FEMALE) 필드 + file(선택). 보낸 필드만 수정.
  /// (서버가 쿼리가 아닌 본문 필드만 읽는 경우가 많아, 모두 form 필드로 전송)
  Future<UserMe?> patchMe(
    Dio authDio, {
    String? nickname,
    double? height,
    double? weight,
    String? gender,
    File? profileImage,
  }) async {
    try {
      final formData = FormData();

      if (nickname != null && nickname.isNotEmpty) {
        formData.fields.add(MapEntry('nickname', nickname));
      }
      if (height != null) {
        formData.fields.add(MapEntry('height', height.toString()));
      }
      if (weight != null) {
        formData.fields.add(MapEntry('weight', weight.toString()));
      }
      if (gender != null && (gender == 'MALE' || gender == 'FEMALE')) {
        formData.fields.add(MapEntry('gender', gender));
      }
      if (profileImage != null) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(
              profileImage.path,
              filename: 'profile.jpg',
            ),
          ),
        );
      }

      final response = await authDio.patch<Map<String, dynamic>>(
        '/api/v1/users/me',
        data: formData.fields.isEmpty && formData.files.isEmpty
            ? null
            : formData,
        options: Options(responseType: ResponseType.json),
      );
      final body = response.data;
      if (body == null) return null;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return UserMe.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }
}
