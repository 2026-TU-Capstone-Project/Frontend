import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/fitting/util/weather_util.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/component/feed_detail_sheet.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';

import 'package:capstone_fe/fitting/component/ai_stylist_input.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/chat/view/ai_chat_screen.dart';
import 'package:capstone_fe/follow/component/notification_bell_icon.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// [임시 데이터 모델] - 실제 개발 시 common/const/data.dart 로 분리
// =============================================================================
class SingleFeedModel {
  final String title;
  final String imageUrl;
  final int likeCount;

  SingleFeedModel({
    required this.title,
    required this.imageUrl,
    required this.likeCount,
  });
}

/// 취향 맞춤 추천용 더미 (가로 스크롤)
final List<SingleFeedModel> recommendedDummyFeeds = [
  SingleFeedModel(
    title: '오늘의 추천 룩',
    imageUrl: 'asset/img/App.jpg',
    likeCount: 324,
  ),
  SingleFeedModel(
    title: '미니멀 데일리',
    imageUrl: 'asset/img/App1.jpg',
    likeCount: 512,
  ),
  SingleFeedModel(
    title: '위크엔드 캐주얼',
    imageUrl: 'asset/img/App2.jpg',
    likeCount: 289,
  ),
  SingleFeedModel(
    title: '데이트 코디',
    imageUrl: 'asset/img/App3.jpg',
    likeCount: 891,
  ),
  SingleFeedModel(
    title: '오피스 룩',
    imageUrl: 'asset/img/App4.jpg',
    likeCount: 445,
  ),
  SingleFeedModel(
    title: '트렌디 포인트',
    imageUrl: 'asset/img/App5.jpg',
    likeCount: 678,
  ),
];

/// 전체 진열용 더미 (2열 그리드)
final List<SingleFeedModel> gridDummyFeeds = [
  SingleFeedModel(
    title: '빈티지 무드 데일리룩',
    imageUrl: 'asset/img/App.jpg',
    likeCount: 1829,
  ),
  SingleFeedModel(
    title: '성수동 카페 투어 룩',
    imageUrl: 'asset/img/App1.jpg',
    likeCount: 2341,
  ),
  SingleFeedModel(
    title: '미니멀리즘 코디',
    imageUrl: 'asset/img/App2.jpg',
    likeCount: 542,
  ),
  SingleFeedModel(
    title: '데이트 추천 룩',
    imageUrl: 'asset/img/App3.jpg',
    likeCount: 3100,
  ),
  SingleFeedModel(
    title: '비 오는 날 코디',
    imageUrl: 'asset/img/App4.jpg',
    likeCount: 890,
  ),
  SingleFeedModel(
    title: '캠퍼스 개강 룩',
    imageUrl: 'asset/img/App5.jpg',
    likeCount: 1200,
  ),
  SingleFeedModel(
    title: '강남 데이트 룩',
    imageUrl: 'asset/img/App6.jpg',
    likeCount: 1200,
  ),
  SingleFeedModel(
    title: '도서관 룩',
    imageUrl: 'asset/img/App7.jpg',
    likeCount: 140,
  ),
];

// =============================================================================
// 디자인 시스템 상수 (Apple 스타일 + 글래스모피즘)
// =============================================================================
abstract class DivervaDesign {
  static const double kPadding = 20.0;
  static const double kRadius = 16.0;

  static const Color background = Color(0xFFF5F5F7);
  static const Color backgroundPureWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF6E6E73);
}

// =============================================================================
// 1. 메인 피팅 배너 - 거의 정사각형, 텍스트 하단, 4초 자동 슬라이드, 유도 문구
// =============================================================================
class MainFittingBanner extends StatefulWidget {
  final List<String> backgroundImagePaths;
  final VoidCallback? onBannerTap;

  const MainFittingBanner({
    super.key,
    List<String>? backgroundImagePaths,
    this.onBannerTap,
  }) : backgroundImagePaths =
           backgroundImagePaths ?? const ['asset/img/App.jpg'];

  @override
  State<MainFittingBanner> createState() => _MainFittingBannerState();
}

class _MainFittingBannerState extends State<MainFittingBanner> {
  late PageController _pageController;
  late int _pageCount;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageCount = widget.backgroundImagePaths.isEmpty
        ? 1
        : widget.backgroundImagePaths.length;
    if (_pageCount > 1) {
      _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_pageController.page?.round() ?? 0) + 1;
        final index = next % _pageCount;
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width - DivervaDesign.kPadding * 2;
    final height = width * 0.9;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DivervaDesign.kPadding,
        vertical: 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                itemBuilder: (context, index) {
                  final path =
                      widget.backgroundImagePaths[index %
                          widget.backgroundImagePaths.length];
                  return Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackColor(),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onBannerTap,
                  child: const SizedBox.expand(),
                ),
              ),
              if (_pageCount > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (i) => AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          final page =
                              _pageController.position.hasContentDimensions
                              ? (_pageController.page ?? 0).round()
                              : 0;
                          final active = (page % _pageCount) == i;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackColor() {
    return Container(color: const Color(0xFFE5E5EA));
  }
}

// =============================================================================
// 오늘은 어떻게 입을까요? — 카드 스택 캐러셀
// =============================================================================
class HowToDressTodaySection extends StatefulWidget {
  final VoidCallback? onWeather;
  final VoidCallback? onPhotoFitting;
  final VoidCallback? onStyleRecommendation;
  final WeatherInfo? weather;

  const HowToDressTodaySection({
    super.key,
    this.onWeather,
    this.onPhotoFitting,
    this.onStyleRecommendation,
    this.weather,
  });

  @override
  State<HowToDressTodaySection> createState() => _HowToDressTodaySectionState();
}

class _HowToDressTodaySectionState extends State<HowToDressTodaySection>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragOffset = 0;
  late AnimationController _animCtrl;

  static const int _totalCards = 2;
  static const double _cardH = 400.0; // 카드 높이 (크게)
  static const double _backScale = 0.93; // 뒤 카드 크기 비율
  static const double _cardWRatio = 0.75; // 카드 너비 = 화면의 75%
  static const double _hPad = 20.0; // 왼쪽 패딩
  static const double _rightPeekMargin = 8.0; // 뒤 카드 오른쪽 끝 여백
  static const double _swipeThreshold = 70.0;
  static const double _velThreshold = 380.0;

  bool get _hasNext => _currentIndex < _totalCards - 1;
  bool get _hasPrev => _currentIndex > 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _weatherSubtitle() {
    final w = widget.weather;
    if (w == null) return '오늘 날씨에 맞는 코디를 확인하세요';
    final label = weatherLabel(w.conditionCode);
    final city = w.cityName.isNotEmpty ? w.cityName : '현재 위치';
    return '$city · ${w.temp.round()}° · ${label.description}';
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_animCtrl.isAnimating) return;
    setState(() {
      var delta = d.delta.dx;
      // 경계에서 저항감 (0.18 배)
      if (!_hasNext && _dragOffset + delta < 0) delta *= 0.18;
      if (!_hasPrev && _dragOffset + delta > 0) delta *= 0.18;
      _dragOffset += delta;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_animCtrl.isAnimating) return;
    final vel = d.primaryVelocity ?? 0;
    final sw = MediaQuery.of(context).size.width;

    if ((_dragOffset < -_swipeThreshold || vel < -_velThreshold) && _hasNext) {
      // 다음 카드가 정확히 0 위치에 착지하도록 -sw 로 이동
      _animate(
        to: -sw,
        curve: Curves.easeOutCubic,
        onDone: () {
          setState(() {
            _currentIndex++;
            _dragOffset = 0;
          });
        },
      );
    } else if ((_dragOffset > _swipeThreshold || vel > _velThreshold) &&
        _hasPrev) {
      // 이전 카드가 정확히 0 위치에 착지하도록 +sw 로 이동
      _animate(
        to: sw,
        curve: Curves.easeOutCubic,
        onDone: () {
          setState(() {
            _currentIndex--;
            _dragOffset = 0;
          });
        },
      );
    } else {
      _animate(to: 0, curve: Curves.easeOutCubic);
    }
  }

  void _animate({
    required double to,
    required Curve curve,
    VoidCallback? onDone,
  }) {
    final start = _dragOffset;
    _animCtrl.reset();
    final anim = Tween<double>(
      begin: start,
      end: to,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: curve));

    void listener() {
      if (mounted) setState(() => _dragOffset = anim.value);
    }

    anim.addListener(listener);
    _animCtrl.forward().then((_) {
      anim.removeListener(listener);
      onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final cardW = sw * _cardWRatio; // 카드 너비 (화면의 82%)
    // 0→1: 왼쪽 스와이프 진행도
    final prog = (_dragOffset / -sw).clamp(0.0, 1.0);
    final prevProg = (_dragOffset / sw).clamp(0.0, 1.0);

    // 뒤 카드 at-rest translateX:
    // 뒤 카드 오른쪽 끝이 (sw - _rightPeekMargin) 에 위치하도록 계산
    // center_at_rest = (sw - _rightPeekMargin) - cardW*_backScale/2
    // default_center = _hPad + cardW/2
    // backDx = center_at_rest - default_center
    final backDx =
        (sw - _rightPeekMargin) - cardW * _backScale / 2 - (_hPad + cardW / 2);

    final cards = [
      _StackCardData(
        imageAsset: 'asset/img/App3.jpg',
        title: '다이버바가 추천하는\n현재 날씨 룩',
        subtitle: _weatherSubtitle(),
        btnText: '날씨 코디 보기',
        onTap: widget.onWeather,
        gradientColors: const [Color(0xFF1A3A5C), Color(0xFF2D7DD2)],
        fallbackIcon: Icons.wb_sunny_outlined,
      ),
      _StackCardData(
        imageAsset: 'asset/img/App6.jpg',
        title: 'AI가 추천하는\n상황별 코디',
        subtitle: '내가 가진 옷으로 만드는 맞춤 코디',
        btnText: 'AI 코디 받기',
        onTap: widget.onStyleRecommendation,
        gradientColors: const [Color(0xFF1A1A2E), Color(0xFF6B5CE7)],
        fallbackIcon: Icons.auto_awesome_outlined,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _cardH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── 이전 카드: 오른쪽 스와이프 시에만 렌더링
                if (_hasPrev && _dragOffset > 0)
                  Positioned(
                    left: _hPad,
                    top: 0,
                    width: cardW,
                    height: _cardH,
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset(_dragOffset - sw, 0),
                        child: _buildCard(cards[_currentIndex - 1]),
                      ),
                    ),
                  ),
                // ── 다음 카드: 오른쪽 peek → 현재 카드와 함께 슬라이드 인
                if (_hasNext)
                  Positioned(
                    left: _hPad,
                    top: 0,
                    width: cardW,
                    height: _cardH,
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset(backDx * (1 - prog), 0),
                        child: Transform.scale(
                          scale: _backScale + (1 - _backScale) * prog,
                          alignment: Alignment.center,
                          child: _buildCard(cards[_currentIndex + 1]),
                        ),
                      ),
                    ),
                  ),
                // ── 현재 카드: 드래그
                Positioned(
                  left: _hPad,
                  top: 0,
                  width: cardW,
                  height: _cardH,
                  child: Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Opacity(
                      opacity: (1.0 - prog * 0.25 - prevProg * 0.25).clamp(
                        0.0,
                        1.0,
                      ),
                      child: GestureDetector(
                        onTap: _dragOffset.abs() < 6
                            ? cards[_currentIndex].onTap
                            : null,
                        child: _buildCard(cards[_currentIndex]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Dot indicator ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (i) {
            final active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active
                    ? AppColors.PRIMARYCOLOR
                    : AppColors.PRIMARYCOLOR.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCard(_StackCardData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          Image.asset(
            data.imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradientColors,
                ),
              ),
              child: Center(
                child: Icon(
                  data.fallbackIcon,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          // 아래에서 조명 쏘는 효과
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 1.4),
                radius: 1.2,
                colors: [
                  Color(0x55FFFFFF),
                  Color(0x22FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // 텍스트 (하단 좌측) — 불투명 배경으로 가독성 향상
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF9E9E9E).withValues(alpha: 0.45),
                    const Color(0xFF808080).withValues(alpha: 0.65),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 명확한 우측 화살표 CTA 버튼
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.btnText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
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

class _StackCardData {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String btnText;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final IconData fallbackIcon;

  const _StackCardData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.btnText,
    this.onTap,
    required this.gradientColors,
    required this.fallbackIcon,
  });
}

// =============================================================================
// 2. 내 최근 코디 - 저장한 코디 가로 스크롤 (옷장 API 동일)
// =============================================================================
class SavedOutfitCard extends StatelessWidget {
  final SavedFittingData item;
  final VoidCallback? onTap;

  const SavedOutfitCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.resultImgUrl;
    final title = item.setName?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              if (title.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: DivervaDesign.textSecondary.withValues(alpha: 0.2),
      child: const Icon(Icons.checkroom, size: 48),
    );
  }
}

class SavedOutfitRack extends StatelessWidget {
  final List<SavedFittingData> items;
  final ValueChanged<SavedFittingData>? onItemTap;

  const SavedOutfitRack({super.key, required this.items, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DivervaDesign.kPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SavedOutfitCard(
            item: item,
            onTap: onItemTap != null ? () => onItemTap!(item) : null,
          );
        },
      ),
    );
  }
}

// =============================================================================
// 내 최근 코디 — 빈 상태 배너
// =============================================================================
class _EmptyOutfitBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyOutfitBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DivervaDesign.kPadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2FF),
          borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
          border: Border.all(color: const Color(0xFFDDD5FF), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                size: 28,
                color: AppColors.ACCENT_PURPLE,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '아직 저장된 코디가 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '가상 피팅으로 나만의 코디를 만들어보세요',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6E6E73),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B85F5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '피팅 시작하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 섹션 헤더 + 추천 카드 (전체 진열 등에서 재사용)
// =============================================================================
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DivervaDesign.kPadding,
        8,
        DivervaDesign.kPadding,
        12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DivervaDesign.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class RecommendedItemCard extends StatelessWidget {
  final SingleFeedModel item;
  final VoidCallback? onTap;

  const RecommendedItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: DivervaDesign.textSecondary.withValues(alpha: 0.2),
                  child: const Icon(Icons.checkroom, size: 48),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecommendedRack extends StatelessWidget {
  final List<SingleFeedModel> items;
  final ValueChanged<SingleFeedModel>? onItemTap;

  const RecommendedRack({super.key, required this.items, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DivervaDesign.kPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return RecommendedItemCard(
            item: item,
            onTap: onItemTap != null ? () => onItemTap!(item) : null,
          );
        },
      ),
    );
  }
}

// =============================================================================
// 3. 2열 그리드 카드
// =============================================================================
class ProductGridCard extends StatelessWidget {
  final FeedListResponseDto item;
  final VoidCallback? onTap;

  const ProductGridCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(DivervaDesign.kRadius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.styleImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: DivervaDesign.textSecondary.withValues(alpha: 0.2),
                  child: const Icon(Icons.checkroom, size: 40),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.likeCount ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 메인 홈 화면 (CustomScrollView)
// =============================================================================
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onGoToFittingRoom;
  final VoidCallback? onGoToStyleRecommendation;
  final VoidCallback? onWeather;

  const HomeScreen({
    super.key,
    this.onGoToFittingRoom,
    this.onGoToStyleRecommendation,
    this.onWeather,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<SavedFittingData> _savedOutfits = [];
  bool _loadingOutfits = true;
  WeatherInfo? _weather;
  String? _nickname;
  List<ClothesModel> _serverClothes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
    _loadWeather();
    _loadNickname();
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    try {
      final dio = createAuthDio();
      final repo = ClothesRepository(dio, baseUrl: baseUrl);
      final resp = await repo.getClothesList();
      if (resp.success && mounted) {
        setState(() => _serverClothes = resp.data ?? []);
      }
    } catch (e) {
      debugPrint('⚠️ HomeScreen _loadWardrobe 에러: $e');
    }
  }

  Future<void> _loadNickname() async {
    try {
      final stored = await const FlutterSecureStorage().read(key: 'NICKNAME');
      if (stored != null && stored.trim().isNotEmpty) {
        if (mounted) setState(() => _nickname = stored.trim());
        return;
      }
      final authDio = createAuthDio();
      final me = await AuthRepository(Dio(), baseUrl: baseUrl).getMe(authDio);
      final name = me?.nickname?.trim();
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _nickname = name);
      }
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    final weather = await fetchWeatherFromCurrentPosition();
    if (!mounted || weather == null) return;
    setState(() => _weather = weather);
  }

  Future<void> _loadSavedOutfits() async {
    try {
      final dio = createAuthDio();
      final repo = FittingRepository(dio, baseUrl: baseUrl);
      final resp = await repo.getMyCloset();
      if (!mounted) return;
      setState(() {
        _savedOutfits = (resp.data ?? []).reversed.toList();
        _loadingOutfits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOutfits = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [NotificationBellIcon()],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: AiStylistInput(nickname: _nickname),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _WardrobeAiSection(clothes: _serverClothes),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: '오늘의 PICK')),
            SliverToBoxAdapter(
              child: HowToDressTodaySection(
                onWeather: widget.onWeather,
                onPhotoFitting: widget.onGoToFittingRoom,
                onStyleRecommendation: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  );
                },
                weather: _weather,
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: '내 최근 코디')),
            SliverToBoxAdapter(
              child: _loadingOutfits
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _savedOutfits.isEmpty
                  ? _EmptyOutfitBanner(onTap: widget.onGoToFittingRoom)
                  : SavedOutfitRack(items: _savedOutfits, onItemTap: (_) {}),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: SectionHeader(title: '인기 스타일')),
            switch (ref.watch(feedListProvider)) {
              AsyncData(:final value) => () {
                final sortedItems = [...value.items]..sort(
                  (a, b) => (b.likeCount ?? 0).compareTo(a.likeCount ?? 0),
                );
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.55,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductGridCard(
                        item: sortedItems[index],
                        onTap: () => showFeedDetailSheet(
                          context,
                          sortedItems[index].feedId,
                        ),
                      ),
                      childCount: sortedItems.length,
                    ),
                  ),
                );
              }(),
              AsyncError() => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: Text('피드를 불러올 수 없습니다.')),
                ),
              ),
              _ => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _WardrobeAiSection extends StatelessWidget {
  final List<ClothesModel> clothes;

  const _WardrobeAiSection({required this.clothes});

  String _buildQuery(ClothesModel item) {
    final name = item.name?.trim() ?? '';
    final cat = item.category?.trim() ?? '';
    if (name.isNotEmpty) return '내 옷 "$name" 어울리는 코디 추천해줘';
    if (cat.isNotEmpty) return '내 $cat 어울리는 코디 추천해줘';
    return '내 옷 어울리는 코디 추천해줘';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '내 옷장',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.BLACK,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${clothes.length}개',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
            const Spacer(),
            const Text(
              '탭하면 AI가 코디 추천해드려요',
              style: TextStyle(fontSize: 12, color: AppColors.MEDIUM_GREY),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (clothes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.checkroom_outlined,
                  size: 32,
                  color: AppColors.MEDIUM_GREY,
                ),
                SizedBox(height: 8),
                Text(
                  '옷을 추가하고 AI 추천을 받아보세요',
                  style: TextStyle(fontSize: 13, color: AppColors.MEDIUM_GREY),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: clothes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = clothes[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, animation, __) =>
                          AiChatScreen(initialMessage: _buildQuery(item)),
                      transitionDuration: const Duration(milliseconds: 350),
                      transitionsBuilder: (_, animation, __, child) {
                        final slide =
                            Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                    ),
                  ),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.imgUrl != null && item.imgUrl!.isNotEmpty)
                          Image.network(
                            item.imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        else
                          _placeholder(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFEEEEEE),
    child: const Icon(
      Icons.checkroom_outlined,
      size: 32,
      color: AppColors.MEDIUM_GREY,
    ),
  );
}
