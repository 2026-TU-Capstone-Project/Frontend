import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';

part 'feed_repository.g.dart';

@RestApi()
abstract class FeedRepository {
  factory FeedRepository(Dio dio, {String? baseUrl}) = _FeedRepository;

  /// 피드 전체 목록 (삭제되지 않은)
  @GET('/api/v1/feeds')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FeedListItem>>> getFeeds();

  /// 피드 상세
  @GET('/api/v1/feeds/{feedId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FeedDetailData>> getFeedDetail(@Path('feedId') int feedId);

  /// 피드 게시 전 미리보기 (가상 피팅 task 기준)
  @GET('/api/v1/feeds/preview/{fittingTaskId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FeedPreviewData>> getFeedPreview(
    @Path('fittingTaskId') int fittingTaskId,
  );

  /// 내 피드 목록
  @GET('/api/v1/feeds/me')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<FeedListItem>>> getMyFeeds();

  /// 피드 작성 (body: fittingTaskId, feedTitle, feedContent)
  @POST('/api/v1/feeds')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> createFeed(@Body() Map<String, dynamic> body);

  /// 피드 수정 (제목·내용만)
  @PATCH('/api/v1/feeds/{feedId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> updateFeed(
    @Path('feedId') int feedId,
    @Body() Map<String, dynamic> body,
  );

  /// 피드 삭제 (소프트 삭제)
  @DELETE('/api/v1/feeds/{feedId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> deleteFeed(@Path('feedId') int feedId);
}

/// POST /api/v1/feeds 요청 body
class CreateFeedBody {
  final int fittingTaskId;
  final String feedTitle;
  final String feedContent;

  CreateFeedBody({
    required this.fittingTaskId,
    required this.feedTitle,
    required this.feedContent,
  });

  Map<String, dynamic> toJson() => {
        'fittingTaskId': fittingTaskId,
        'feedTitle': feedTitle,
        'feedContent': feedContent,
      };
}

/// PATCH /api/v1/feeds/{feedId} 요청 body
class UpdateFeedBody {
  final String feedTitle;
  final String feedContent;

  UpdateFeedBody({
    required this.feedTitle,
    required this.feedContent,
  });

  Map<String, dynamic> toJson() => {
        'feedTitle': feedTitle,
        'feedContent': feedContent,
      };
}
