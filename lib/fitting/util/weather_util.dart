import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

const _owmApiKey = '40591f2fa4b059a5ac307fc839eafc7f';

// ─────────────────────────────────────────────────────────
// 날씨 DTO
// ─────────────────────────────────────────────────────────
class WeatherInfo {
  final double temp;
  final String description;
  final String cityName;
  final int conditionCode;

  const WeatherInfo({
    required this.temp,
    required this.description,
    required this.cityName,
    this.conditionCode = 800,
  });
}

// ─────────────────────────────────────────────────────────
// conditionCode → 이모지 + 한국어 설명
// ─────────────────────────────────────────────────────────
({String emoji, String description}) weatherLabel(int code) {
  if (code >= 200 && code < 300) return (emoji: '⛈', description: '천둥번개');
  if (code >= 300 && code < 400) return (emoji: '🌦', description: '이슬비');
  if (code >= 500 && code < 600) return (emoji: '🌧', description: '비');
  if (code >= 600 && code < 700) return (emoji: '❄️', description: '눈');
  if (code == 701) return (emoji: '🌫', description: '안개');
  if (code == 711) return (emoji: '🌫', description: '연기');
  if (code == 721) return (emoji: '☁️', description: '실안개');
  if (code == 741) return (emoji: '🌫', description: '짙은 안개');
  if (code >= 751 && code <= 762) return (emoji: '😷', description: '먼지');
  if (code == 771) return (emoji: '💨', description: '돌풍');
  if (code == 781) return (emoji: '🌪', description: '토네이도');
  if (code == 800) return (emoji: '☀️', description: '맑음');
  if (code == 801) return (emoji: '🌤', description: '구름 조금');
  if (code == 802) return (emoji: '⛅', description: '구름 낀');
  if (code >= 803) return (emoji: '☁️', description: '흐림');
  return (emoji: '☀️', description: '맑음');
}

// ─────────────────────────────────────────────────────────
// OpenWeatherMap 호출
// ─────────────────────────────────────────────────────────
Future<WeatherInfo> fetchWeather(double lat, double lon) async {
  try {
    final dio = Dio();
    final res = await dio.get(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': _owmApiKey,
        'units': 'metric',
      },
    );
    final body = res.data is String ? jsonDecode(res.data) : res.data;
    final temp = (body['main']['temp'] as num).toDouble();
    final conditionCode = body['weather'][0]['id'] as int? ?? 800;
    final city = body['name'] as String? ?? '';
    final desc = weatherLabel(conditionCode).description;
    return WeatherInfo(
      temp: temp,
      description: desc,
      cityName: city,
      conditionCode: conditionCode,
    );
  } catch (_) {
    return const WeatherInfo(
      temp: 15.0,
      description: '맑음',
      cityName: '서울',
      conditionCode: 800,
    );
  }
}

// ─────────────────────────────────────────────────────────
// 현재 위치 기반 날씨 조회 (권한 없으면 null 반환)
// ─────────────────────────────────────────────────────────
Future<WeatherInfo?> fetchWeatherFromCurrentPosition() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return fetchWeather(position.latitude, position.longitude);
  } catch (_) {
    return null;
  }
}
