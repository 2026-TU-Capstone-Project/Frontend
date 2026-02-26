import 'dart:async';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';

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
  }) : backgroundImagePaths = backgroundImagePaths ?? const ['asset/img/App.jpg'];

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
      _autoAdvanceTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) {
          if (!mounted) return;
          final next = (_pageController.page?.round() ?? 0) + 1;
          final index = next % _pageCount;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        },
      );
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
    final width = MediaQuery.of(context).size.width -
        DivervaDesign.kPadding * 2;
    final height = width * 0.95;

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
                  final path = widget.backgroundImagePaths[
                      index % widget.backgroundImagePaths.length];
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
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
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
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEW COLLECTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '나의 아바타에\n입혀보는 새로운 계절',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '전신 사진을 등록하고, 입고 싶은 옷을 골라보세요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
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
                          final page = _pageController.position.hasContentDimensions
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
                                  : Colors.white.withOpacity(0.4),
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
                      Colors.black.withOpacity(0.7),
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
      color: DivervaDesign.textSecondary.withOpacity(0.2),
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
                  color: DivervaDesign.textSecondary.withOpacity(0.2),
                  child: const Icon(Icons.checkroom, size: 48),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
  final SingleFeedModel item;
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
              Image.asset(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: DivervaDesign.textSecondary.withOpacity(0.2),
                  child: const Icon(Icons.checkroom, size: 40),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF5F6D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
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
        ),
      ),
    );
  }
}

// =============================================================================
// 메인 홈 화면 (CustomScrollView)
// =============================================================================
class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToFittingRoom;

  const HomeScreen({super.key, this.onGoToFittingRoom});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedFittingData> _savedOutfits = [];
  bool _loadingOutfits = true;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    try {
      final dio = createAuthDio();
      final repo = FittingRepository(dio, baseUrl: baseUrl);
      final resp = await repo.getMyCloset();
      if (!mounted) return;
      setState(() {
        _savedOutfits = resp.data ?? [];
        _loadingOutfits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOutfits = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DivervaDesign.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: MainFittingBanner(
                backgroundImagePaths: const [
                  'asset/img/App.jpg',
                  'asset/img/App1.jpg',
                  'asset/img/App2.jpg',
                ],
                onBannerTap: widget.onGoToFittingRoom,
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: '내 최근 코디')),
            SliverToBoxAdapter(
              child: _loadingOutfits
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SavedOutfitRack(
                      items: _savedOutfits,
                      onItemTap: (_) {},
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: SectionHeader(title: '전체 아이템 진열')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.55,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ProductGridCard(
                    item: gridDummyFeeds[index],
                    onTap: () {},
                  );
                }, childCount: gridDummyFeeds.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
