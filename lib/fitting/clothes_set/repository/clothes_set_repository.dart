import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';

part 'clothes_set_repository.g.dart';

@RestApi()
abstract class ClothesSetRepository {
  factory ClothesSetRepository(Dio dio, {String? baseUrl}) = _ClothesSetRepository;

  /// 내 폴더 목록 조회
  @GET('/api/v1/clothes-sets')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<ClothesSetModel>>> getClothesSets();

  /// 코디 저장 (새 폴더 생성 후 저장). 응답 data = 생성된 폴더 ID(숫자)
  @POST('/api/v1/clothes-sets/save')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<int>> saveClothesSet(
    @Body() SaveClothesSetRequest body,
  );

  /// 폴더 이름 수정
  @PATCH('/api/v1/clothes-sets/{id}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> updateClothesSet(
    @Path('id') int id,
    @Body() UpdateClothesSetRequest body,
  );

  /// 폴더 전체 삭제
  @DELETE('/api/v1/clothes-sets/{id}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> deleteClothesSet(@Path('id') int id);

  /// 폴더 내 착장(피팅 결과) 개별 삭제
  @DELETE('/api/v1/clothes-sets/fitting/{fittingTaskId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> deleteFittingFromSet(
    @Path('fittingTaskId') int fittingTaskId,
  );
}
