import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/const/data.dart'; // IP 주소
import 'package:capstone_fe/common/model/api_response.dart'; // 👈 만능 응답 모델 import


import '../model/recommend_model.dart'; // 👈 RecommendResult 모델 import

part 'recommend_repository.g.dart';

@RestApi(baseUrl: 'http://$ip')
abstract class RecommendRepository {
  factory RecommendRepository(Dio dio, {String? baseUrl}) = _RecommendRepository;

  // 스타일 추천 API
  // 반환 타입: ApiResponse<RecommendResult> (이미 만들어둔 껍데기 사용)
  @GET('/api/v1/virtual-fitting/recommend')
  @Headers({'accessToken': 'true'}) // 토큰 자동 첨부
  Future<ApiResponse<RecommendResult>> getRecommendations({
    @Query('query') required String query,
  });
}