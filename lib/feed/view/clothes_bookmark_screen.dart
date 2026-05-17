import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/clothes_bookmark_provider.dart';
import 'package:capstone_fe/feed/provider/favorite_feed_provider.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/fitting/clothes/component/clothes_detail_bottom_sheet.dart';
import 'package:capstone_fe/fitting/clothes/provider/clothes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kBg = Color(0xFFF5F5F7);

class ClothesBookmarkScreen extends StatelessWidget {
  const ClothesBookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            labelColor: AppColors.BLACK,
            unselectedLabelColor: AppColors.MEDIUM_GREY,
            indicatorColor: AppColors.BLACK,
            indicatorWeight: 2,
            labelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: '옷'),
              Tab(text: '피드'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ClothesTab(),
            _FeedTab(),
          ],
        ),
      ),
    );
  }
}

class _ClothesTab extends ConsumerStatefulWidget {
  const _ClothesTab();

  @override
  ConsumerState<_ClothesTab> createState() => _ClothesTabState();
}

class _ClothesTabState extends ConsumerState<_ClothesTab> {
  // null = 전체, 'TOP' | 'BOTTOM'
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(clothesBookmarkListProvider);

    return Column(
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
                if (items.isEmpty) {
                  return _EmptyView(
                    icon: Icons.bookmark_border_rounded,
                    title: '아직 북마크한 옷이 없어요',
                    subtitle: '피드에서 마음에 드는 옷을 저장해보세요',
                  );
                }
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
                    onTap: () => _openDetail(items[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(ClothesBookmarkDto item) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => const PopScope(
        canPop: false,
        child: LoadingIndicator(),
      ),
    );
    try {
      final resp = await ref
          .read(clothesRepositoryProvider)
          .getClothDetail(id: item.clothesId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (resp.success && resp.data != null) {
        await ClothesDetailBottomSheet.show(context, cloth: resp.data!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상세 정보를 불러오지 못했어요: $e')),
      );
    }
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
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(favoriteFeedListProvider);

    return RefreshIndicator(
      color: AppColors.PRIMARYCOLOR,
      onRefresh: () =>
          ref.read(favoriteFeedListProvider.notifier).refresh(),
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
          if (list.isEmpty) {
            return const _EmptyView(
              icon: Icons.favorite_border_rounded,
              title: '아직 즐겨찾기한 피드가 없어요',
              subtitle: '피드 상세에서 마음에 드는 피드를 저장해보세요',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              return _FeedCard(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FeedDetailScreen(feedId: item.feedId),
                  ),
                ),
                onRemove: () async {
                  final ok = await ref
                      .read(favoriteFeedListProvider.notifier)
                      .toggleFavorite(item.feedId);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('즐겨찾기 해제에 실패했어요.')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final ClothesBookmarkDto item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = item.imgUrl != null && item.imgUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

class _FeedCard extends StatelessWidget {
  final FeedListResponseDto item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FeedCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = item.styleImageUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      item.styleImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.favorite_rounded),
                  color: Colors.white,
                  tooltip: '즐겨찾기 해제',
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
                    item.feedTitle,
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
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFFCCCCCC),
          size: 40,
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Icon(
                  icon,
                  size: 36,
                  color: AppColors.MEDIUM_GREY,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.MEDIUM_GREY,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
