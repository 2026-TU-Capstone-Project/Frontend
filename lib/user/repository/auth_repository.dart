import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:capstone_fe/user/repository/auth_client.dart';
import '../model/auth_model.dart';


class AuthRepository {
  final AuthClient _client;

  AuthRepository(Dio dio, {String? baseUrl})
      : _client = AuthClient(dio, baseUrl: baseUrl);

  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
    required String username,
  }) async {
    try {
      await _client.signup(SignupBody(
        email: email,
        password: password,
        nickname: nickname,
        username: username,
      ));
      return true;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {

      final responseString = await _client.login(LoginBody(
        email: email,
        password: password,
      ));

      final Map<String, dynamic> json = jsonDecode(responseString);


      final accessToken = json['accessToken'];

      return accessToken;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('이메일 또는 비밀번호가 잘못되었습니다.');
      }
      throw Exception('로그인 실패: $e');
    }
  }
}