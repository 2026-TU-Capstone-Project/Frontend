import 'package:capstone_fe/common/const/data.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../model/auth_model.dart';

part 'auth_client.g.dart';
@RestApi(baseUrl: 'http://$ip')
abstract class AuthClient {
  factory AuthClient(Dio dio , {String? baseUrl}) = _AuthClient;

  @POST('/api/v1/auth/signup')
  Future<String> signup(@Body() SignupBody body);

  @POST('/api/v1/auth/login')
  Future<String> login(@Body() LoginBody body);

}