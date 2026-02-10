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
    @Part(name: "user_image") required File userImage,
    @Part(name: "top_image") required File topImage,
    @Part(name: "bottom_image") File? bottomImage,
  });

  @GET('/api/v1/virtual-fitting/{taskId}/status')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<FittingStatusData>> checkStatus({
    @Path("taskId") required int taskId,
  });
}