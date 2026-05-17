import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
part 'fitting_repository.g.dart';

@RestApi()
abstract class FittingRepository {
  factory FittingRepository(Dio dio, {String? baseUrl}) = _FittingRepository;

  @POST('/api/v1/virtual-fitting')
  @MultiPart()
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FittingRequestData>> requestFitting({
    @Query("top_fit_type") required String topFitType,
    @Query("bottom_fit_type") String? bottomFitType,
    @Part(name: "user_image") required File userImage,
    @Part(name: "top_image") required File topImage,
    @Part(name: "bottom_image") File? bottomImage,
  });

  /// 스타일 사진 기반 피팅: 사용자 사진에 참조 스타일 사진의 룩을 입힘
  @POST('/api/v1/virtual-fitting/style-photo')
  @MultiPart()
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FittingRequestData>> requestStyleFitting({
    @Part(name: "user_image") required File userImage,
    @Part(name: "style_image") required File styleImage,
  });

  @GET('/api/v1/virtual-fitting/{taskId}/status')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FittingStatusData>> checkStatus({
    @Path("taskId") required int taskId,
  });

  /// 피팅 결과 삭제(닫기)
  @DELETE('/api/v1/virtual-fitting/{taskId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> deleteFittingResult({
    @Path("taskId") required int taskId,
  });

  /// 피팅 결과 옷장 저장
  @PATCH('/api/v1/virtual-fitting/{taskId}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> saveFittingToWardrobe({
    @Path("taskId") required int taskId,
  });

  /// 내가 저장한 코디 목록 (가상 피팅 결과)
  @GET('/api/v1/virtual-fitting/my-closet')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<SavedFittingData>>> getMyCloset();
}
