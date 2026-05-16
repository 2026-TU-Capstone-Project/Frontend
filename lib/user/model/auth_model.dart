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

// 7. 로그아웃 요청 Body (서버의 Redis 토큰 파기용, Swagger RefreshTokenRequestDto)
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
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final double? height;
  final double? weight;
  final String? gender;

  UserMe({
    this.userId,
    this.email,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.height,
    this.weight,
    this.gender,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) => _$UserMeFromJson(json);
  Map<String, dynamic> toJson() => _$UserMeToJson(this);
}

// 10. 공개 프로필 조회 응답 (GET /api/v1/users/{userId})
// API: followStatus(null | PENDING | ACCEPTED). 구버전 키(isFollowing/isRequested)도 호환.
@JsonSerializable()
class UserPublicProfile {
  final int? userId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final int? followerCount;
  final int? followingCount;
  final String? followStatus; // null | PENDING | ACCEPTED
  final bool? followsMeBack;
  final bool? me;

  UserPublicProfile({
    this.userId,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.followerCount,
    this.followingCount,
    this.followStatus,
    this.followsMeBack,
    this.me,
  });

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) =>
      _$UserPublicProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserPublicProfileToJson(this);

  // 구버전 호환용 getter
  bool get isFollowing => followStatus == 'ACCEPTED';
  bool get isRequested => followStatus == 'PENDING';
}

// 11. 유저 검색 응답 item (GET /api/v1/users/search)
@JsonSerializable()
class UserSearchItem {
  final int? userId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final String? followStatus;

  UserSearchItem({
    this.userId,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.followStatus,
  });

  factory UserSearchItem.fromJson(Map<String, dynamic> json) =>
      _$UserSearchItemFromJson(json);
  Map<String, dynamic> toJson() => _$UserSearchItemToJson(this);
}