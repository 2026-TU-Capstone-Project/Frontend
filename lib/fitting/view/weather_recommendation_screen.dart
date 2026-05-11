import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/component/style_analysis_widget.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/model/weather_recommendation_model.dart';
import 'package:capstone_fe/fitting/repository/weather_recommendation_repository.dart';
import 'package:capstone_fe/fitting/util/weather_util.dart';

// ───────────────────────────────────────────────────────────
// 진입점: 위치·날씨 조회 후 결과 화면으로 push
// ───────────────────────────────────────────────────────────
Future<void> navigateToWeatherRecommendation(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LoadingDialog(),
  );

  try {
    final position = await _getPosition(context);
    if (position == null) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    final weather = await fetchWeather(position.latitude, position.longitude);

    final query =
        '현재 ${weather.temp.round()}도 ${weather.description} 날씨에 맞는 코디 추천해줘';
    final repo = WeatherRecommendationRepository(
      createAuthDio(),
      baseUrl: baseUrl,
    );
    final response = await repo.getWeatherRecommendation(
      query: query,
      temp: weather.temp,
    );

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;

    if (response.success && response.data != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WeatherRecommendationScreen(
            weather: weather,
            data: response.data!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : '추천 정보를 불러오지 못했습니다.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날씨 기반 추천을 불러오는 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ───────────────────────────────────────────────────────────
// 위치 권한 + GPS
// ───────────────────────────────────────────────────────────
Future<Position?> _getPosition(BuildContext context) async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('위치 권한 필요'),
          content: const Text(
            '날씨 기반 코디 추천을 위해 위치 접근 권한이 필요합니다.\n설정에서 권한을 허용해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      );
    }
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (_) {
    return Position(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

// ───────────────────────────────────────────────────────────
// 날씨 조건별 그라데이션 색상
// ───────────────────────────────────────────────────────────
List<Color> _weatherGradient(int conditionCode) {
  if (conditionCode >= 200 && conditionCode < 300) {
    // 천둥번개
    return [const Color(0xFF37474F), const Color(0xFF455A64)];
  }
  if (conditionCode >= 300 && conditionCode < 400) {
    // 이슬비
    return [const Color(0xFF546E7A), const Color(0xFF78909C)];
  }
  if (conditionCode >= 500 && conditionCode < 600) {
    // 비
    return [const Color(0xFF3949AB), const Color(0xFF5C6BC0)];
  }
  if (conditionCode >= 600 && conditionCode < 700) {
    // 눈
    return [const Color(0xFF90CAF9), const Color(0xFFBBDEFB)];
  }
  if (conditionCode >= 700 && conditionCode < 800) {
    // 안개/먼지
    return [const Color(0xFF78909C), const Color(0xFFB0BEC5)];
  }
  if (conditionCode == 800) {
    // 맑음
    return [const Color(0xFF42A5F5), const Color(0xFF90CAF9)];
  }
  // 흐림 (801+)
  return [const Color(0xFF5B7FFF), const Color(0xFF8B7BFF)];
}

// ───────────────────────────────────────────────────────────
// 기온 기반 요약 문장
// ───────────────────────────────────────────────────────────
String _summaryForWeather(WeatherInfo w) {
  final t = w.temp;
  if (w.rain > 0) return '비 소식이 있어요, 우산과 방수 아우터를 챙기세요!';
  if (w.snow > 0) return '눈이 내려요, 따뜻하게 레이어드하세요!';
  if (w.windSpeed >= 8) return '바람이 강해요, 바람막이를 추천해요!';
  if (t >= 28) return '무더운 날이에요, 시원한 반팔 차림이 딱이에요!';
  if (t >= 23) return '따뜻한 날씨, 가벼운 옷차림이 좋아요!';
  if (t >= 18) return '쾌적한 날씨예요, 간단한 겉옷 하나면 충분해요!';
  if (t >= 12) return '선선해요, 가벼운 재킷을 걸쳐보세요!';
  if (t >= 5) return '제법 쌀쌀해요, 따뜻한 외투가 필요해요!';
  return '매우 추워요, 두꺼운 코트와 머플러를 챙기세요!';
}

// ───────────────────────────────────────────────────────────
// 시간별 예보 아이콘 (현재 기온 기반 시뮬레이션)
// ───────────────────────────────────────────────────────────
IconData _hourlyWeatherIcon(int conditionCode) {
  if (conditionCode >= 200 && conditionCode < 300) return Icons.flash_on;
  if (conditionCode >= 300 && conditionCode < 600) return Icons.grain;
  if (conditionCode >= 600 && conditionCode < 700) return Icons.ac_unit;
  if (conditionCode >= 700 && conditionCode < 800) return Icons.cloud;
  if (conditionCode == 800) return Icons.wb_sunny_rounded;
  return Icons.cloud;
}

// ───────────────────────────────────────────────────────────
// 결과 화면
// ───────────────────────────────────────────────────────────
class WeatherRecommendationScreen extends StatelessWidget {
  final WeatherInfo weather;
  final WeatherRecommendationData data;

  const WeatherRecommendationScreen({
    super.key,
    required this.weather,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = _weatherGradient(weather.conditionCode);

    return Scaffold(
      backgroundColor: AppColors.INPUT_BG_COLOR,
      body: CustomScrollView(
        slivers: [
          // 동적 날씨 헤더 (AppBar 대체)
          _DynamicWeatherHeader(
            weather: weather,
            gradientColors: gradientColors,
          ),

          // 시간별 예보 스트립
          SliverToBoxAdapter(
            child: _HourlyForecastStrip(weather: weather),
          ),

          // 추천 섹션 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '오늘의 추천 코디',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.BLACK,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${data.recommendations.length}벌',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.MEDIUM_GREY,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 추천 카드 목록
          if (data.recommendations.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _EnhancedRecommendationCard(
                    item: data.recommendations[i],
                    weather: weather,
                  ),
                  childCount: data.recommendations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 1. 동적 날씨 헤더 (SliverAppBar + 그라데이션)
// ───────────────────────────────────────────────────────────
class _DynamicWeatherHeader extends StatelessWidget {
  final WeatherInfo weather;
  final List<Color> gradientColors;

  const _DynamicWeatherHeader({
    required this.weather,
    required this.gradientColors,
  });

  String get _weatherIcon => weatherLabel(weather.conditionCode).emoji;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 장식 원
            Positioned(
              right: -30,
              top: -10,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // 본문
            Padding(
              padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 바: 뒤로가기 + 타이틀
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '날씨 코디 추천',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // 위치 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white70,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              weather.cityName.isNotEmpty
                                  ? weather.cityName
                                  : '현재 위치',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 날씨 아이콘 + 온도
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 이모지 아이콘
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _weatherIcon,
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 온도 + 설명
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temp.round()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  weather.description,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 요약 문장
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _summaryForWeather(weather),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 부가 정보 칩 (풍속, 습도)
                  Row(
                    children: [
                      _WeatherInfoChip(
                        icon: Icons.air_rounded,
                        label: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                      ),
                      const SizedBox(width: 8),
                      _WeatherInfoChip(
                        icon: Icons.water_drop_outlined,
                        label: '${weather.humidity}%',
                      ),
                      if (weather.rain > 0) ...[
                        const SizedBox(width: 8),
                        _WeatherInfoChip(
                          icon: Icons.umbrella_rounded,
                          label: '${weather.rain.toStringAsFixed(1)} mm',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 부가 정보 칩
class _WeatherInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 2. 시간별 예보 스트립
// ───────────────────────────────────────────────────────────
class _HourlyForecastStrip extends StatelessWidget {
  final WeatherInfo weather;

  const _HourlyForecastStrip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rng = Random(weather.temp.round());
    final icon = _hourlyWeatherIcon(weather.conditionCode);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (ctx, i) {
          final hour = (now.hour + i + 1) % 24;
          // 기온을 ±2도 범위로 자연스럽게 변화
          final tempVariation = (rng.nextDouble() * 4 - 2);
          final hourTemp = (weather.temp + tempVariation).round();
          final isNow = i == 0;

          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isNow
                  ? AppColors.ACCENT_BLUE.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: isNow
                  ? Border.all(
                      color: AppColors.ACCENT_BLUE.withValues(alpha: 0.3),
                    )
                  : Border.all(color: AppColors.BORDER_COLOR),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  isNow ? '지금' : '${hour.toString().padLeft(2, '0')}시',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                    color: isNow ? AppColors.ACCENT_BLUE : AppColors.MEDIUM_GREY,
                  ),
                ),
                Icon(
                  icon,
                  size: 22,
                  color: isNow ? AppColors.ACCENT_BLUE : AppColors.BODY_COLOR,
                ),
                Text(
                  '$hourTemp°',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isNow ? AppColors.ACCENT_BLUE : AppColors.BLACK,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 3. 강화된 추천 카드
// ───────────────────────────────────────────────────────────
class _EnhancedRecommendationCard extends StatelessWidget {
  final WeatherRecommendationItem item;
  final WeatherInfo weather;

  const _EnhancedRecommendationCard({
    required this.item,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final matchPct = (item.score * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 + 오버레이 뱃지
          if (item.resultImgUrl != null && item.resultImgUrl!.isNotEmpty)
            _ImageSection(
              imageUrl: item.resultImgUrl!,
              matchPct: matchPct,
            )
          else
            const _PlaceholderImage(),

          // 정보 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 매치 게이지
                _MatchScoreGauge(score: matchPct),

                // 스타일 분석
                if (item.styleAnalysis != null &&
                    item.styleAnalysis!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.BORDER_COLOR),
                  const SizedBox(height: 14),
                  StyleAnalysisView(styleAnalysis: item.styleAnalysis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 이미지 섹션 (뱃지 오버레이 포함)
class _ImageSection extends StatelessWidget {
  final String imageUrl;
  final int matchPct;

  const _ImageSection({
    required this.imageUrl,
    required this.matchPct,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.INPUT_BG_COLOR,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppColors.MEDIUM_GREY,
                  ),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.INPUT_BG_COLOR,
                  child: const LoadingIndicator(size: 80),
                );
              },
            ),
          ),
          // 매치 점수 뱃지 (우상단)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$matchPct점',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 이미지 없을 때 플레이스홀더
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: 200,
        width: double.infinity,
        color: AppColors.INPUT_BG_COLOR,
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: AppColors.MEDIUM_GREY,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 매치 점수 게이지
// ───────────────────────────────────────────────────────────
class _MatchScoreGauge extends StatelessWidget {
  final int score;

  const _MatchScoreGauge({required this.score});

  Color get _gaugeColor {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '날씨 매치도',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.BODY_COLOR,
              ),
            ),
            const Spacer(),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _gaugeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: AppColors.BORDER_COLOR,
            valueColor: AlwaysStoppedAnimation<Color>(_gaugeColor),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────
// 빈 상태
// ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.ACCENT_BLUE.withValues(alpha: 0.15),
                  AppColors.ACCENT_PURPLE.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ACCENT_BLUE.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              size: 44,
              color: AppColors.ACCENT_PURPLE,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '추천할 코디가 없습니다.',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.BLACK,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '옷장에 옷을 먼저 등록해 보세요.',
            style: TextStyle(fontSize: 14, color: AppColors.MEDIUM_GREY),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 로딩 다이얼로그
// ───────────────────────────────────────────────────────────
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(size: 80),
            const SizedBox(height: 20),
            const Text(
              '날씨를 확인하고 있어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI가 오늘 날씨에 맞는 코디를\n추천해드릴게요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.MEDIUM_GREY,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
