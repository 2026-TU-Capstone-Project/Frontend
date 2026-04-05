import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:capstone_fe/fitting/util/weather_util.dart';

export 'package:capstone_fe/fitting/util/weather_util.dart' show WeatherInfo;

/// POST /api/v1/virtual-fitting/recommendation/weather-style 응답 data
class WeatherStyleResult {
  final WeatherInfo? weatherInfo;
  final List<RecommendationModel>? recommendations;

  const WeatherStyleResult({this.weatherInfo, this.recommendations});

  factory WeatherStyleResult.fromJson(Map<String, dynamic> json) {
    List<RecommendationModel>? recs;
    final recsJson = json['recommendations'];
    if (recsJson is List) {
      recs = recsJson
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return WeatherStyleResult(recommendations: recs);
  }
}
