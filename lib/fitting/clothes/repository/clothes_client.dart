import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:dio/dio.dart'hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/const/data.dart'; // IP 주소

part 'clothes_client.g.dart';

@RestApi(baseUrl: 'http://$ip')
abstract class ClothesClient {
  factory ClothesClient(Dio dio, {String? baseUrl}) = _ClothesClient;

  // 스타일 추천 API
  @GET('/api/v1/virtual-fitting/recommend')
  @Headers({'accessToken': 'true'}) // 토큰 자동 첨부
  Future<RecommendResponse> getRecommendations({
    @Query('query') required String query,
  });
}