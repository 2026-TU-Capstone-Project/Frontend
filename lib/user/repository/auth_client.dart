import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/user/model%20/auth_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_client.g.dart';
@RestApi(baseUrl: 'http://$ip')
abstract class AuthClient {
  factory AuthClient(Dio dio , {String? baseUrl}) = _AuthClient;

  @POST('/api/auth/signup')
  Future<String> signup(@Body() SignupBody body);

  @POST('/api/auth/login')
  Future<String> login(@Body() LoginBody body);

}