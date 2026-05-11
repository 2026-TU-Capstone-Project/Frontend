import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/user/model/auth_model.dart';

part 'user_repository.g.dart';

@RestApi()
abstract class UserRepository {
  factory UserRepository(Dio dio, {String? baseUrl}) = _UserRepository;

  /// 닉네임/username 키워드 유저 검색
  @GET('/api/v1/users/search')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<UserSearchItem>>> search(
    @Query('keyword') String keyword,
  );

  /// 공개 프로필 조회
  @GET('/api/v1/users/{userId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<UserPublicProfile>> getPublicProfile(
    @Path('userId') int userId,
  );
}
