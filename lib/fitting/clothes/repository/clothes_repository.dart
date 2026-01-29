// lib/clothes/repository/clothes_repository.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';

part 'clothes_repository.g.dart';

@RestApi()
abstract class ClothesRepository {
  factory ClothesRepository(Dio dio, {String baseUrl}) = _ClothesRepository;


  @GET('/api/clothes')
  Future<ClothesListResponse> getClothesList();

  @GET('/api/clothes/{id}')
  Future<ClothesDetailResponse> getClothDetail({
    @Path("id") required int id,
  });
}