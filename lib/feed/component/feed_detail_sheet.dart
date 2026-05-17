import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/component/worn_product_card.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/clothes_bookmark_provider.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 인기 스타일 카드 탭 시 띄우는 바텀 시트.
/// feedDetailProvider로 착용 제품 정보까지 표시.
void showFeedDetailSheet(BuildContext context, int feedId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FeedDetailSheet(feedId: feedId),
  );
}

class FeedDetailSheet extends ConsumerWidget {
  final int feedId;
  const FeedDetailSheet({super.key, required this.feedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(feedDetailProvider(feedId));

    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 300,
            child: LoadingIndicator(size: 80),
          ),
          error: (_, __) => const SizedBox(
            height: 200,
            child: Center(child: Text('불러오기 실패')),
          ),
          data: (d) => _SheetBody(d: d, feedId: feedId),
        ),
      ),
    );
  }
}

class _SheetBody extends ConsumerWidget {
  final FeedDetailResponseDto d;
  final int feedId;
  const _SheetBody({required this.d, required this.feedId});

  Future<void> _handleBookmarkTap(
    BuildContext context,
    WidgetRef ref,
    String position,
  ) async {
    final ok = await ref
        .read(clothesBookmarkListProvider.notifier)
        .toggleBookmark(feedId, position);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 처리에 실패했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMe = ref.watch(userMeProvider).valueOrNull;
    final isMine = userMe?.userId == d.authorId;
    final bookmarks =
        ref.watch(clothesBookmarkListProvider).valueOrNull ??
            const <ClothesBookmarkDto>[];
    bool isBookmarked(String position) =>
        bookmarks.any((b) => b.feedId == feedId && b.position == position);

    final cards = <Widget>[
      if (d.topImageUrl != null || d.topName != null)
        WornProductCard(
          label: '상의',
          imageUrl: d.topImageUrl,
          productName: d.topName ?? '-',
          isBookmarked: isBookmarked('TOP'),
          onBookmarkTap:
              isMine ? null : () => _handleBookmarkTap(context, ref, 'TOP'),
        ),
      if (d.bottomImageUrl != null || d.bottomName != null)
        WornProductCard(
          label: '하의',
          imageUrl: d.bottomImageUrl,
          productName: d.bottomName ?? '-',
          isBookmarked: isBookmarked('BOTTOM'),
          onBookmarkTap:
              isMine ? null : () => _handleBookmarkTap(context, ref, 'BOTTOM'),
        ),
    ];

    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 핸들바 (스크롤과 무관하게 상단 고정)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // 헤더 (고정)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '착용 아이템을 확인해 보세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.BLACK,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
                color: AppColors.MEDIUM_GREY,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 본문 (스크롤)
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 스타일 이미지
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.network(
                        d.styleImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.BORDER_COLOR,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 착용 제품 섹션
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '착용 제품',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.BLACK,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '등록된 착용 제품이 없어요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.MEDIUM_GREY,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          cards[i],
                          if (i != cards.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
