import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';
@JsonSerializable()
class LoginBody{
  final String email;
  final String password;


  LoginBody({
    required this.email,
    required this.password
});
    Map<String, dynamic> toJson() => _$LoginBodyToJson(this);
}

@JsonSerializable()
class SignupBody{
  final String email;
  final String password;
  final String nickname;
  final String username;
  SignupBody({
    required this.email,
    required this.password,
    required this.nickname,
    required this.username
});
  Map<String, dynamic> toJson() => _$SignupBodyToJson(this);
}
