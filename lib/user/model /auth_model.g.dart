// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginBody _$LoginBodyFromJson(Map<String, dynamic> json) => LoginBody(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginBodyToJson(LoginBody instance) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
};

SignupBody _$SignupBodyFromJson(Map<String, dynamic> json) => SignupBody(
  email: json['email'] as String,
  password: json['password'] as String,
  nickname: json['nickname'] as String,
  username: json['username'] as String,
);

Map<String, dynamic> _$SignupBodyToJson(SignupBody instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'nickname': instance.nickname,
      'username': instance.username,
    };
