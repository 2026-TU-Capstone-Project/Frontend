import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';

/// 날씨 정보 (API가 반환할 경우 파싱, 없으면 null)
class WeatherInfo {
  final int? temperature;
  final String? condition;
  final String? location;

  const WeatherInfo({this.temperature, this.condition, this.location});

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: json['temperature'] is num
          ? (json['temperature'] as num).toInt()
          : null,
      condition:
          json['condition'] as String? ?? json['weatherCondition'] as String?,
      location: json['location'] as String?,
    );
  }
}

/// GET /api/v1/virtual-fitting/recommendation/weather-style 응답 data
class WeatherStyleResult {
  final WeatherInfo? weatherInfo;
  final List<RecommendationModel>? recommendations;

  const WeatherStyleResult({this.weatherInfo, this.recommendations});

  factory WeatherStyleResult.fromJson(Map<String, dynamic> json) {
    WeatherInfo? weather;
    final weatherJson = json['weatherInfo'] ?? json['weather'];
    if (weatherJson is Map<String, dynamic>) {
      weather = WeatherInfo.fromJson(weatherJson);
    }

    List<RecommendationModel>? recs;
    final recsJson = json['recommendations'];
    if (recsJson is List) {
      recs = recsJson
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return WeatherStyleResult(weatherInfo: weather, recommendations: recs);
  }
}
