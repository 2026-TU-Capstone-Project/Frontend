import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';

part 'follow_repository.g.dart';

@RestApi()
abstract class FollowRepository {
  factory FollowRepository(Dio dio, {String? baseUrl}) = _FollowRepository;

  @POST('/api/v1/follows/{targetUserId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> sendFollowRequest(
    @Path('targetUserId') int targetUserId,
  );

  @DELETE('/api/v1/follows/{targetUserId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> cancelOrUnfollow(
    @Path('targetUserId') int targetUserId,
  );

  @PATCH('/api/v1/follows/requests/{followId}/accept')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> acceptFollow(
    @Path('followId') int followId,
  );

  @DELETE('/api/v1/follows/requests/{followId}/reject')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> rejectFollow(
    @Path('followId') int followId,
  );

  @GET('/api/v1/follows/requests')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FollowRequestResponse>>> getPendingRequests();

  @GET('/api/v1/follows/followings')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FollowResponse>>> getFollowings();

  @GET('/api/v1/follows/followers')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FollowResponse>>> getFollowers();

  @GET('/api/v1/follows/{userId}/followings')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FollowResponse>>> getUserFollowings(
    @Path('userId') int userId,
  );

  @GET('/api/v1/follows/{userId}/followers')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FollowResponse>>> getUserFollowers(
    @Path('userId') int userId,
  );
}
