import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:capstone_fe/fitting/clothes/model/weather_recommend_model.dart';
import 'package:capstone_fe/fitting/clothes/provider/recommend_provider.dart';

/// 홈 "날씨" 카드 탭 → 날씨 기반 코디 추천 화면
class WeatherStyleScreen extends ConsumerWidget {
  const WeatherStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(weatherStyleRecommendProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.BLACK),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '날씨 기반 추천',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
        centerTitle: true,
      ),
      body: resultAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
        ),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () =>
              ref.read(weatherStyleRecommendProvider.notifier).refresh(),
        ),
        data: (result) => _SuccessBody(
          result: result,
          onRefresh: () =>
              ref.read(weatherStyleRecommendProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 성공 본문: 날씨 배너 + 추천 그리드
// ─────────────────────────────────────────────

class _SuccessBody extends StatelessWidget {
  final WeatherStyleResult result;
  final Future<void> Function() onRefresh;

  const _SuccessBody({required this.result, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final recs = result.recommendations ?? [];

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.PRIMARYCOLOR,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _WeatherBanner(weatherInfo: result.weatherInfo),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                '오늘의 코디 추천 ${recs.length}개',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                ),
              ),
            ),
          ),
          if (recs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  '추천 코디가 없어요.',
                  style: TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 15),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _OutfitCard(rec: recs[index]),
                  childCount: recs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 날씨 배너: API 날씨 정보가 있으면 사용, 없으면 계절 기반 표시
// ─────────────────────────────────────────────

class _WeatherBanner extends StatelessWidget {
  final WeatherInfo? weatherInfo;

  const _WeatherBanner({this.weatherInfo});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (icon, seasonLabel, gradient, guideText) = _seasonTheme(now.month);

    // API가 날씨 정보를 반환했으면 온도/지역을 함께 표시
    final tempStr = weatherInfo?.temperature != null
        ? '${weatherInfo!.temperature}°C'
        : null;
    final location = weatherInfo?.location;
    final condition = weatherInfo?.condition ?? seasonLabel;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 52, color: Colors.white),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location != null)
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      condition,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    if (tempStr != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          tempStr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  guideText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 달(month)에 따른 계절 테마 반환
  (IconData, String, LinearGradient, String) _seasonTheme(int month) {
    return switch (month) {
      3 || 4 || 5 => (
        Icons.local_florist_rounded,
        '따뜻한 봄이에요',
        const LinearGradient(
          colors: [Color(0xFF5B7FFF), Color(0xFF8B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        '가벼운 레이어드로\n봄 감성을 표현해보세요',
      ),
      6 || 7 || 8 => (
        Icons.wb_sunny_rounded,
        '더운 여름이에요',
        const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        '시원한 소재와 컬러로\n여름을 스타일리시하게',
      ),
      9 || 10 || 11 => (
        Icons.park_rounded,
        '선선한 가을이에요',
        const LinearGradient(
          colors: [Color(0xFFB06A3B), Color(0xFFE8946A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        '어스톤 컬러로\n가을 분위기를 연출해보세요',
      ),
      _ => (
        Icons.ac_unit_rounded,
        '추운 겨울이에요',
        const LinearGradient(
          colors: [Color(0xFF4A6FA5), Color(0xFF8AB4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        '따뜻한 레이어드로\n겨울 코디를 완성해보세요',
      ),
    };
  }
}

// ─────────────────────────────────────────────
// 추천 코디 카드
// ─────────────────────────────────────────────

class _OutfitCard extends StatelessWidget {
  final RecommendationModel rec;

  const _OutfitCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final imageUrl = rec.resultImgUrl;
    final analysis = rec.styleAnalysis;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.INPUT_BG_COLOR,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.BORDER_COLOR),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                analysis?.isNotEmpty == true ? analysis! : '스타일 분석 없음',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.BODY_COLOR,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.INPUT_BG_COLOR,
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            color: AppColors.BORDER_COLOR,
            size: 48,
          ),
        ),
      );
}

// ─────────────────────────────────────────────
// 에러 뷰
// ─────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wb_cloudy_outlined,
              size: 72,
              color: AppColors.BORDER_COLOR,
            ),
            const SizedBox(height: 20),
            const Text(
              '날씨 추천을 불러올 수 없어요',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.MEDIUM_GREY,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.PRIMARYCOLOR,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
