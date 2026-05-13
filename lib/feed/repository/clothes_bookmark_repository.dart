import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';

part 'clothes_bookmark_repository.g.dart';

@RestApi()
abstract class ClothesBookmarkRepository {
  factory ClothesBookmarkRepository(Dio dio, {String? baseUrl}) =
      _ClothesBookmarkRepository;

  /// 내 옷 북마크 목록 조회 (position: TOP | BOTTOM | null)
  @GET('/api/v1/clothes-bookmarks')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<ClothesBookmarkDto>>> listBookmarks({
    @Query('position') String? position,
  });

  /// 피드 옷 북마크 저장
  @POST('/api/v1/clothes-bookmarks')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<ClothesBookmarkDto>> saveBookmark({
    @Query('feedId') required int feedId,
    @Query('position') required String position,
  });

  /// 옷 북마크 삭제
  @DELETE('/api/v1/clothes-bookmarks/{bookmarkId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<void>> deleteBookmark({
    @Path('bookmarkId') required int bookmarkId,
  });
}
