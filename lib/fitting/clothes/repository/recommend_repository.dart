import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import '../model/weather_recommend_model.dart';

part 'recommend_repository.g.dart';

/// 스타일 추천 API. baseUrl은 Provider에서 주입한다.
@RestApi()
abstract class RecommendRepository {
  factory RecommendRepository(Dio dio, {String? baseUrl}) = _RecommendRepository;

  /// POST /api/v1/virtual-fitting/recommendation/weather-style
  @POST('/api/v1/virtual-fitting/recommendation/weather-style')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<WeatherStyleResult>> getWeatherStyleRecommendations({
    @Query('query') required String query,
    @Query('temp') required double temp,
    @Query('rain') required double rain,
    @Query('snow') required double snow,
    @Query('windSpeed') required double windSpeed,
    @Query('humidity') required int humidity,
  });
}
