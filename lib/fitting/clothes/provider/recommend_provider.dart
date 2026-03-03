import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/fitting/clothes/model/weather_recommend_model.dart';
import 'package:capstone_fe/fitting/clothes/repository/recommend_repository.dart';

final recommendRepositoryProvider = Provider<RecommendRepository>((ref) {
  return RecommendRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

class WeatherStyleNotifier extends AsyncNotifier<WeatherStyleResult> {
  @override
  Future<WeatherStyleResult> build() => _fetch();

  Future<WeatherStyleResult> _fetch() async {
    try {
      final resp = await ref
          .read(recommendRepositoryProvider)
          .getWeatherStyleRecommendations();
      if (resp.data == null) throw Exception(resp.message);
      return resp.data!;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 500) {
        throw Exception('서버에서 날씨 추천을 처리하는 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
      }
      if (status == 401) {
        throw Exception('로그인이 필요합니다.');
      }
      throw Exception('네트워크 오류가 발생했습니다.\n인터넷 연결을 확인해주세요.');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final weatherStyleRecommendProvider =
    AsyncNotifierProvider<WeatherStyleNotifier, WeatherStyleResult>(
  WeatherStyleNotifier.new,
);
