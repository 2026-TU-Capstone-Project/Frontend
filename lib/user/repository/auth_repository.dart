import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:capstone_fe/user/repository/auth_client.dart';
import '../model/auth_model.dart';

class AuthRepository {
  final AuthClient _client;
  final String? baseUrl;

  AuthRepository(Dio dio, {this.baseUrl})
    : _client = AuthClient(_withUnwrap(dio), baseUrl: baseUrl);

  /// 서버가 { "success": true, "data": { ... } } 형태로 응답을 래핑할 때
  /// Retrofit이 파싱하기 전에 data 필드만 꺼내도록 인터셉터를 추가한다.
  /// 동일 Dio에 여러 번 호출돼도 인터셉터가 중복 등록되지 않도록 보장.
  static Dio _withUnwrap(Dio dio) {
    if (dio.interceptors.any((i) => i is _AuthUnwrapInterceptor)) {
      return dio;
    }
    dio.interceptors.add(_AuthUnwrapInterceptor());
    return dio;
  }

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
  ///
  /// - 200: UserMe 반환 (data 없으면 null)
  /// - 401(authDio refresh 후에도 실패): [UnauthorizedException] 던짐
  /// - 그 외(네트워크/파싱): [Exception] 던짐
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      }
      throw Exception('마이페이지 조회 실패: ${e.message ?? e}');
    }
  }

  /// 최초 온보딩 프로필 등록 (POST /api/v1/users/me).
  /// Query params: height, weight, gender. Body: multipart file(선택).
  Future<UserMe?> submitOnboardingProfile(
    Dio authDio, {
    required double height,
    required double weight,
    required String gender,
    File? profileImage,
  }) async {
    try {
      FormData? formData;
      if (profileImage != null) {
        formData = FormData();
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
      final response = await authDio.post<Map<String, dynamic>>(
        '/api/v1/users/me',
        queryParameters: {
          'height': height,
          'weight': weight,
          'gender': gender,
        },
        data: formData,
        options: Options(responseType: ResponseType.json),
      );
      final body = response.data;
      if (body == null) return null;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return UserMe.fromJson(data);
    } catch (e) {
      debugPrint('온보딩 프로필 전송 실패: $e');
      return null;
    }
  }

  /// 마이페이지 수정 (PATCH /api/v1/users/me).
  /// multipart/form-data: nickname, height, weight, gender(MALE|FEMALE) 필드 + file(선택). 보낸 필드만 수정.
  /// (서버가 쿼리가 아닌 본문 필드만 읽는 경우가 많아, 모두 form 필드로 전송)
  Future<UserMe?> patchMe(
    Dio authDio, {
    String? username,
    String? nickname,
    double? height,
    double? weight,
    String? gender,
    File? profileImage,
  }) async {
    try {
      final formData = FormData();

      if (username != null && username.isNotEmpty) {
        formData.fields.add(MapEntry('username', username));
      }
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

/// 401 Unauthorized — 토큰이 만료/유효하지 않을 때 호출자가 명시적으로 분기하기 위한 예외.
/// authDio가 refresh를 시도하고도 실패한 경우에만 노출된다.
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = '인증이 필요합니다.']);
  @override
  String toString() => 'UnauthorizedException: $message';
}

/// `{success, message, data}` 응답에서 data를 꺼내 Retrofit이 파싱할 수 있게 한다.
/// 인스턴스 타입으로 중복 등록 여부를 식별하기 위한 전용 클래스.
class _AuthUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic> &&
        body['data'] is Map<String, dynamic>) {
      response.data = body['data'] as Map<String, dynamic>;
    }
    handler.next(response);
  }
}
