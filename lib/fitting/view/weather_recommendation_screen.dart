import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  // 로딩 다이얼로그
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LoadingDialog(),
  );

  try {
    // 1. 위치 권한 확인 및 GPS 조회
    final position = await _getPosition(context);
    if (position == null) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    // 2. OpenWeatherMap 날씨 조회
    final weather = await fetchWeather(position.latitude, position.longitude);

    // 3. 백엔드 추천 API 호출
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
    // 위치 조회 실패 시 서울 기본값
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
    return Scaffold(
      backgroundColor: AppColors.INPUT_BG_COLOR,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.BLACK,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '날씨 코디 추천',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _WeatherCard(weather: weather)),
          if (data.recommendations.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RecommendationCard(
                    item: data.recommendations[i],
                    rank: i + 1,
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
// 날씨 정보 카드
// ───────────────────────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  final WeatherInfo weather;

  const _WeatherCard({required this.weather});

  String get _weatherIcon => weatherLabel(weather.conditionCode).emoji;

  String get _tempFeeling {
    final t = weather.temp;
    if (t >= 28) return '🔥 매우 더움';
    if (t >= 23) return '😎 더움';
    if (t >= 18) return '🙂 쾌적';
    if (t >= 12) return '🧥 선선함';
    if (t >= 5) return '🥶 추움';
    return '❄️ 매우 추움';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ACCENT_BLUE, AppColors.ACCENT_PURPLE],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 장식 원
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // 본문
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이모지 + 글로우
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _weatherIcon,
                        style: const TextStyle(fontSize: 38),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                weather.cityName.isNotEmpty
                                    ? weather.cityName
                                    : '현재 위치',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${weather.temp.round()}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            weather.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 하단 구분선
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                // 체감 온도 뱃지
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tempFeeling,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'AI 코디 추천 결과',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 추천 코디 카드
// ───────────────────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  final WeatherRecommendationItem item;
  final int rank;

  const _RecommendationCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          if (item.resultImgUrl != null && item.resultImgUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  item.resultImgUrl!,
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
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.ACCENT_BLUE,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 200,
                color: AppColors.INPUT_BG_COLOR,
                child: const Center(
                  child: Icon(
                    Icons.checkroom_outlined,
                    size: 64,
                    color: AppColors.MEDIUM_GREY,
                  ),
                ),
              ),
            ),

          // 정보 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 순위 + 점수
                Row(
                  children: [
                    _RankBadge(rank: rank),
                    const Spacer(),
                    _ScoreBadge(score: item.score),
                  ],
                ),
                if (item.styleAnalysis != null &&
                    item.styleAnalysis!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.styleAnalysis!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.BODY_COLOR,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ACCENT_BLUE, AppColors.ACCENT_PURPLE],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$rank 추천',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).clamp(0, 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
        const SizedBox(width: 4),
        Text(
          '$pct점',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
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
          Icon(
            Icons.wb_cloudy_outlined,
            size: 64,
            color: AppColors.MEDIUM_GREY,
          ),
          const SizedBox(height: 16),
          const Text(
            '추천할 코디가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.MEDIUM_GREY,
              fontWeight: FontWeight.w500,
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.ACCENT_BLUE,
                ),
              ),
            ),
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
