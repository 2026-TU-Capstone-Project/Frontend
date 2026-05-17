import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/clothes_bookmark_provider.dart';
import 'package:capstone_fe/feed/provider/favorite_feed_provider.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/util/clothes_category_util.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import '../theme/fitting_room_theme.dart';

class WardrobePickerSheet extends ConsumerStatefulWidget {
  final List<ClothesModel> clothes;
  final Function(ClothesModel) onClothSelected;
  final String category;

  const WardrobePickerSheet({
    required this.clothes,
    required this.onClothSelected,
    required this.category,
    super.key,
  });

  @override
  ConsumerState<WardrobePickerSheet> createState() =>
      _WardrobePickerSheetState();
}

class _WardrobePickerSheetState extends ConsumerState<WardrobePickerSheet> {
  List<ClothesModel> _filteredClothes = [];
  int _pressedIndex = -1;
  // 'closet' | 'bookmark' | 'favorite_feed' (favorite_feed는 STYLE 모드 전용)
  String _source = 'closet';

  bool get _styleMode => widget.category.toUpperCase() == 'STYLE';

  @override
  void initState() {
    super.initState();
    // STYLE 모드는 즐겨찾기 피드만 노출 (탭 없음)
    if (_styleMode) _source = 'favorite_feed';
    _filterClothes();
  }

  void _filterClothes() {
    _filteredClothes = widget.clothes.where((cloth) {
      final targetCat = widget.category.toUpperCase();
      if (targetCat == 'TOP') return isTopCategory(cloth.category);
      if (targetCat == 'BOTTOM') return isBottomCategory(cloth.category);
      return true;
    }).toList();
  }

  /// 북마크 항목을 _selectCloth가 받는 ClothesModel로 합성.
  /// position을 category로 그대로 넘기면 isTop/Bottom 판별이 그대로 동작.
  ClothesModel _bookmarkToClothes(ClothesBookmarkDto b) => ClothesModel(
        id: b.clothesId,
        category: b.position,
        name: b.name,
        imgUrl: b.imgUrl,
      );

  /// 즐겨찾기 피드 → ClothesModel 합성. styleImageUrl을 imgUrl로 전달해
  /// 호출자(_selectStyleCloth)에서 임시 파일로 다운로드 가능하게 한다.
  ClothesModel _feedToClothes(FeedListResponseDto f) => ClothesModel(
        id: f.feedId,
        category: 'STYLE',
        name: f.feedTitle,
        imgUrl: f.styleImageUrl,
      );

  String _categoryLabel(String? category) {
    if (category == null) return '';
    final upper = category.toUpperCase();
    if (isTopCategory(upper)) return 'TOP';
    if (isBottomCategory(upper)) return 'BOTTOM';
    return upper;
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    switch (widget.category.toUpperCase()) {
      case 'TOP':
        title = "상의 선택하기";
        break;
      case 'BOTTOM':
        title = "하의 선택하기";
        break;
      case 'STYLE':
        title = "스타일 사진 선택하기";
        break;
      default:
        title = "옷장에서 선택하기";
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FittingRoomTheme.kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!_styleMode) _buildSourceTabs(),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_source) {
              'closet' => _buildClosetGrid(),
              'favorite_feed' => _buildFavoriteFeedGrid(),
              _ => _buildBookmarkGrid(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTabs() {
    Widget tab(String value, String label) {
      final selected = _source == value;
      return GestureDetector(
        onTap: () => setState(() {
          _source = value;
          _pressedIndex = -1;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.BLACK : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab('closet', '내 옷장'),
          tab('bookmark', '북마크'),
        ],
      ),
    );
  }

  Widget _buildClosetGrid() {
    if (_filteredClothes.isEmpty) return _buildEmptyState();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredClothes.length,
      itemBuilder: (context, index) =>
          _buildClothCard(_filteredClothes[index], index),
    );
  }

  Widget _buildBookmarkGrid() {
    final asyncList = ref.watch(clothesBookmarkListProvider);
    return asyncList.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.BODY_COLOR),
          ),
        ),
      ),
      data: (list) {
        final target = widget.category.toUpperCase();
        final items =
            list.where((b) => b.position == target).toList(growable: false);
        if (items.isEmpty) return _buildBookmarkEmpty();
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildClothCard(_bookmarkToClothes(items[index]), index),
        );
      },
    );
  }

  Widget _buildFavoriteFeedGrid() {
    final asyncList = ref.watch(favoriteFeedListProvider);
    return asyncList.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.BODY_COLOR),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return _buildFavoriteFeedEmpty();
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final feed = list[index];
            return _FeedTile(
              imageUrl: feed.styleImageUrl,
              onTap: () {
                Navigator.pop(context);
                widget.onClothSelected(_feedToClothes(feed));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteFeedEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.INPUT_BG_COLOR,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "즐겨찾기한 피드가 없어요",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.BODY_COLOR,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "마음에 드는 룩을 즐겨찾기에\n저장해보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.MEDIUM_GREY,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.INPUT_BG_COLOR,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 40,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "북마크한 옷이 없어요",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.BODY_COLOR,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "피드에서 마음에 드는 옷을\n저장해보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.MEDIUM_GREY,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.INPUT_BG_COLOR,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              size: 40,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "등록된 옷이 없어요",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.BODY_COLOR,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "옷장에 옷을 추가하고\n가상 피팅을 시작해 보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.MEDIUM_GREY,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothCard(ClothesModel cloth, int index) {
    final isPressed = _pressedIndex == index;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onClothSelected(cloth);
      },
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = -1),
      onTapCancel: () => setState(() => _pressedIndex = -1),
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.INPUT_BG_COLOR,
                          border: Border.all(
                            color: AppColors.BORDER_COLOR,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          image: cloth.imgUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(cloth.imgUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: cloth.imgUrl == null
                            ? const Icon(Icons.checkroom,
                                color: AppColors.MEDIUM_GREY)
                            : null,
                      ),
                      if (cloth.imgUrl != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cloth.name ?? "-",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _categoryLabel(cloth.category),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTile extends StatefulWidget {
  const _FeedTile({required this.imageUrl, required this.onTap});
  final String imageUrl;
  final VoidCallback onTap;

  @override
  State<_FeedTile> createState() => _FeedTileState();
}

class _FeedTileState extends State<_FeedTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : Container(color: AppColors.INPUT_BG_COLOR),
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.INPUT_BG_COLOR,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.MEDIUM_GREY,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}