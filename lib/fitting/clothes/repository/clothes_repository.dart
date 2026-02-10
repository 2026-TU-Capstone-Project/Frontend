import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';

import 'package:capstone_fe/common/model/api_response.dart';

part 'clothes_repository.g.dart';

@RestApi()
abstract class ClothesRepository {
  factory ClothesRepository(Dio dio, {String? baseUrl}) = _ClothesRepository;


  @GET('/api/v1/clothes')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<List<ClothesModel>>> getClothesList();


  @GET('/api/v1/clothes/{id}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<ClothesModel>> getClothDetail({
    @Path("id") required int id,
  });


  @DELETE('/api/v1/clothes/{id}')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> deleteCloth({
    @Path("id") required int id,
  });


  @POST('/api/v1/clothes')
  @MultiPart()
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> uploadSingleCloth({
    @Query("category") required String category,
    @Part(name: "file") required File file,
  });


  @POST('/api/v1/clothes/analysis')
  @MultiPart()
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<String>> uploadAnalysisCloth({
    @Part(name: "top") File? top,
    @Part(name: "bottom") File? bottom,
    @Part(name: "shoes") File? shoes,
  });
}