// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupBody _$SignupBodyFromJson(Map<String, dynamic> json) => SignupBody(
  email: json['email'] as String,
  password: json['password'] as String,
  gender: json['gender'] as String,
);

Map<String, dynamic> _$SignupBodyToJson(SignupBody instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'gender': instance.gender,
    };

LoginBody _$LoginBodyFromJson(Map<String, dynamic> json) => LoginBody(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginBodyToJson(LoginBody instance) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
};

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

RefreshTokenBody _$RefreshTokenBodyFromJson(Map<String, dynamic> json) =>
    RefreshTokenBody(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$RefreshTokenBodyToJson(RefreshTokenBody instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

GoogleLoginBody _$GoogleLoginBodyFromJson(Map<String, dynamic> json) =>
    GoogleLoginBody(idToken: json['idToken'] as String);

Map<String, dynamic> _$GoogleLoginBodyToJson(GoogleLoginBody instance) =>
    <String, dynamic>{'idToken': instance.idToken};

KakaoLoginBody _$KakaoLoginBodyFromJson(Map<String, dynamic> json) =>
    KakaoLoginBody(accessToken: json['accessToken'] as String);

Map<String, dynamic> _$KakaoLoginBodyToJson(KakaoLoginBody instance) =>
    <String, dynamic>{'accessToken': instance.accessToken};

ExchangeBody _$ExchangeBodyFromJson(Map<String, dynamic> json) =>
    ExchangeBody(tempKey: json['tempKey'] as String);

Map<String, dynamic> _$ExchangeBodyToJson(ExchangeBody instance) =>
    <String, dynamic>{'tempKey': instance.tempKey};

LogoutBody _$LogoutBodyFromJson(Map<String, dynamic> json) =>
    LogoutBody(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$LogoutBodyToJson(LogoutBody instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

UserMe _$UserMeFromJson(Map<String, dynamic> json) => UserMe(
  userId: (json['userId'] as num?)?.toInt(),
  email: json['email'] as String?,
  nickname: json['nickname'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  height: (json['height'] as num?)?.toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
  gender: json['gender'] as String?,
);

Map<String, dynamic> _$UserMeToJson(UserMe instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'nickname': instance.nickname,
  'profileImageUrl': instance.profileImageUrl,
  'height': instance.height,
  'weight': instance.weight,
  'gender': instance.gender,
};
