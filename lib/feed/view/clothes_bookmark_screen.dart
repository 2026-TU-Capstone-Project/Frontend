import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/clothes_bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kBg = Color(0xFFF5F5F7);

class ClothesBookmarkScreen extends ConsumerStatefulWidget {
  const ClothesBookmarkScreen({super.key});

  @override
  ConsumerState<ClothesBookmarkScreen> createState() =>
      _ClothesBookmarkScreenState();
}

class _ClothesBookmarkScreenState
    extends ConsumerState<ClothesBookmarkScreen> {
  // null = 전체, 'TOP' | 'BOTTOM'
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(clothesBookmarkListProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '북마크',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.PRIMARYCOLOR,
              onRefresh: () =>
                  ref.read(clothesBookmarkListProvider.notifier).refresh(),
              child: asyncList.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: AppColors.BODY_COLOR),
                      ),
                    ),
                  ],
                ),
                data: (list) {
                  final items = _filter == null
                      ? list
                      : list.where((b) => b.position == _filter).toList();
                  if (items.isEmpty) return _buildEmpty();
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _BookmarkCard(
                      item: items[i],
                      onRemove: () => _remove(items[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(ClothesBookmarkDto item) async {
    final ok = await ref
        .read(clothesBookmarkListProvider.notifier)
        .toggleBookmark(item.feedId, item.position);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 해제에 실패했어요.')),
      );
    }
  }

  Widget _buildFilterChips() {
    final chips = [
      ('전체', null),
      ('상의', 'TOP'),
      ('하의', 'BOTTOM'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, value) = chips[i];
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.BLACK : Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: selected ? 0.0 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.BLACK,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  size: 36,
                  color: AppColors.MEDIUM_GREY,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '아직 북마크한 옷이 없어요',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '피드에서 마음에 드는 옷을 저장해보세요',
                style: TextStyle(fontSize: 13, color: AppColors.MEDIUM_GREY),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final ClothesBookmarkDto item;
  final VoidCallback onRemove;

  const _BookmarkCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final hasImg = item.imgUrl != null && item.imgUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImg
                ? Image.network(
                    item.imgUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.position == 'TOP' ? '상의' : '하의',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark_rounded),
                color: Colors.white,
                tooltip: '북마크 해제',
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Text(
                  item.name ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Icon(
          Icons.checkroom_outlined,
          color: Color(0xFFCCCCCC),
          size: 40,
        ),
      );
}
