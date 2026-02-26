import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

// 1. 회원가입 요청 Body (POST /api/v1/auth/signup: email, password, gender)
@JsonSerializable(includeIfNull: false)
class SignupBody {
  final String email;
  final String password;
  final String gender;

  SignupBody({
    required this.email,
    required this.password,
    required this.gender,
  });

  Map<String, dynamic> toJson() => _$SignupBodyToJson(this);
}

// 2. 로그인 요청 Body
@JsonSerializable()
class LoginBody {
  final String email;
  final String password;

  LoginBody({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$LoginBodyToJson(this);
}

// 3. 토큰 응답 모델 (로그인, 갱신, 교환 성공 시)
@JsonSerializable()
class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);
}

// 4. 토큰 갱신 요청 Body
@JsonSerializable()
class RefreshTokenBody {
  final String refreshToken;

  RefreshTokenBody({required this.refreshToken});

  Map<String, dynamic> toJson() => _$RefreshTokenBodyToJson(this);
}

// 5. Google 로그인 요청 Body (Swagger: idToken)
@JsonSerializable()
class GoogleLoginBody {
  final String idToken;

  GoogleLoginBody({required this.idToken});

  Map<String, dynamic> toJson() => _$GoogleLoginBodyToJson(this);
}

// 6. Kakao 로그인 요청 Body (Swagger: accessToken)
@JsonSerializable()
class KakaoLoginBody {
  final String accessToken;

  KakaoLoginBody({required this.accessToken});

  Map<String, dynamic> toJson() => _$KakaoLoginBodyToJson(this);
}

// 7. 소셜 로그인 임시 키 교환 Body (OAuth2 리다이렉트 후 ?key= 로 받은 값)
@JsonSerializable()
class ExchangeBody {
  final String tempKey;

  ExchangeBody({required this.tempKey});

  Map<String, dynamic> toJson() => _$ExchangeBodyToJson(this);
}

// 8. 로그아웃 요청 Body (서버의 Redis 토큰 파기용, Swagger RefreshTokenRequestDto)
@JsonSerializable()
class LogoutBody {
  final String refreshToken;

  LogoutBody({required this.refreshToken});

  Map<String, dynamic> toJson() => _$LogoutBodyToJson(this);
}

// 9. 마이페이지 조회 응답 (GET /api/v1/users/me data)
@JsonSerializable()
class UserMe {
  final int? userId;
  final String? email;
  final String? nickname;
  final String? profileImageUrl;
  final double? height;
  final double? weight;
  final String? gender;

  UserMe({
    this.userId,
    this.email,
    this.nickname,
    this.profileImageUrl,
    this.height,
    this.weight,
    this.gender,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) => _$UserMeFromJson(json);
  Map<String, dynamic> toJson() => _$UserMeToJson(this);
}