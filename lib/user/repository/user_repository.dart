import 'dart:io';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/user/model/user_model.dart';

part 'user_repository.g.dart';

@RestApi()
abstract class UserRepository {
  factory UserRepository(Dio dio, {String? baseUrl}) = _UserRepository;

  /// 마이페이지 조회
  @GET('/api/v1/users/me')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<UserModel>> getMe();

  /// 마이페이지 수정 (query params + multipart file)
  @PATCH('/api/v1/users/me')
  @MultiPart()
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<UserModel>> updateProfile({
    @Query('nickname') String? nickname,
    @Query('height') double? height,
    @Query('weight') double? weight,
    @Query('gender') String? gender,
    @Part(name: 'file') File? file,
  });

  /// 닉네임/username 키워드 유저 검색
  @GET('/api/v1/users/search')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<UserSearchItem>>> search(
    @Query('keyword') String keyword,
  );

  /// 공개 프로필 조회
  @GET('/api/v1/users/{userId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<PublicUserInfo>> getPublicProfile(
    @Path('userId') int userId,
  );
}
