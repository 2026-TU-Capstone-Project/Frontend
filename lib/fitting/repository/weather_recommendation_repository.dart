import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/fitting/model/weather_recommendation_model.dart';

part 'weather_recommendation_repository.g.dart';

@RestApi()
abstract class WeatherRecommendationRepository {
  factory WeatherRecommendationRepository(Dio dio, {String? baseUrl}) =
      _WeatherRecommendationRepository;

  @GET('/api/v1/virtual-fitting/recommendation/weather-style')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<WeatherRecommendationData>> getWeatherRecommendation({
    @Query('query') required String query,
    @Query('temp') required double temp,
  });
}
