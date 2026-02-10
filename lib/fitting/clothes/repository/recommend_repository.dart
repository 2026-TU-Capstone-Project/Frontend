import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import '../model/recommend_model.dart';

part 'recommend_repository.g.dart';

@RestApi(baseUrl: 'http://$ip')
abstract class RecommendRepository {
  factory RecommendRepository(Dio dio, {String? baseUrl}) = _RecommendRepository;


  @GET('/api/v1/virtual-fitting/recommendation/style')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<RecommendResult>> getRecommendations({
    @Query('query') required String query,
  });
}