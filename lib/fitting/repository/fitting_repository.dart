import 'dart:io'; // File 사용을 위해 필수
import 'package:dio/dio.dart'; // Dio 사용을 위해 필수
import 'package:retrofit/retrofit.dart'; // ⭐️ @RestApi, @POST 등을 위해 필수!
import 'package:capstone_fe/fitting/model/fitting_model.dart'; // 응답 모델

part 'fitting_repository.g.dart';

@RestApi()
abstract class FittingRepository {
  factory FittingRepository(Dio dio, {String baseUrl}) = _FittingRepository;

  @POST('/api/v1/virtual-fitting')
  @MultiPart()
  Future<FittingRequestResponse> requestFitting({
    @Part(name: "user_image") required File userImage,
    @Part(name: "top_image") File? topImage,
    @Part(name: "bottom_image") File? bottomImage,
  });

  @GET('/api/v1/virtual-fitting/status/{taskId}')
  Future<FittingStatusResponse> checkStatus({
    @Path("taskId") required int taskId,
  });
}