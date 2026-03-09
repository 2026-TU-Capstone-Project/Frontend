import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      child: detailAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox(
          height: 200,
          child: Center(child: Text('불러오기 실패')),
        ),
        data: (d) => _SheetBody(d: d),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  final FeedDetailData d;
  const _SheetBody({required this.d});

  @override
  Widget build(BuildContext context) {
    final products = [
      if (d.topImageUrl != null || d.topName != null)
        _ProductChip(imageUrl: d.topImageUrl, name: d.topName ?? '-'),
      if (d.bottomImageUrl != null || d.bottomName != null)
        _ProductChip(imageUrl: d.bottomImageUrl, name: d.bottomName ?? '-'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 핸들바
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
        // 헤더
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
                    const SizedBox(height: 4),
                    Text(
                      d.feedTitle ?? '스타일 피드',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ACCENT_BLUE,
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
                  child: const Icon(Icons.broken_image_outlined, size: 48),
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
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '등록된 착용 제품이 없어요.',
              style: TextStyle(fontSize: 14, color: AppColors.MEDIUM_GREY),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => products[i],
            ),
          ),
      ],
    );
  }
}

class _ProductChip extends StatelessWidget {
  final String? imageUrl;
  final String name;
  const _ProductChip({this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 90,
              height: 90,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.BLACK,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.BORDER_COLOR,
        child: const Icon(Icons.checkroom_rounded,
            size: 32, color: AppColors.MEDIUM_GREY),
      );
}
