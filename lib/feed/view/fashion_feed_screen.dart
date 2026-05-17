import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/feed/view/feed_write_screen.dart';
import 'package:capstone_fe/user/view/user_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FashionFeedScreen extends ConsumerStatefulWidget {
  const FashionFeedScreen({super.key});

  @override
  ConsumerState<FashionFeedScreen> createState() => _FashionFeedScreenState();
}

class _FashionFeedScreenState extends ConsumerState<FashionFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _fetchMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _fetchMoreThreshold) {
      ref.read(feedListProvider.notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '피드',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.BLACK,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FeedWriteScreen(),
                              ),
                            );
                            ref.read(feedListProvider.notifier).refresh();
                          },
                          tooltip: '피드 작성',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${feedAsync.valueOrNull?.totalElements ?? 0}개의 게시물',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.MEDIUM_GREY,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserSearchScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search,
                                size: 20, color: AppColors.MEDIUM_GREY),
                            SizedBox(width: 8),
                            Text(
                              '닉네임 또는 아이디 검색',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: feedAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.BODY_COLOR),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              ref.read(feedListProvider.notifier).refresh(),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                  data: (state) {
                    final feeds = state.items;
                    if (feeds.isEmpty) {
                      return const Center(
                        child: Text(
                          '아직 피드가 없어요.\n첫 피드를 올려보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.MEDIUM_GREY),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(feedListProvider.notifier).refresh(),
                      child: MasonryGridView.count(
                        controller: _scrollController,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount:
                            feeds.length + (state.isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= feeds.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: LoadingIndicator(size: 28),
                            );
                          }
                          final feed = feeds[index];
                          final aspectRatio = index.isEven ? 0.7 : 0.85;
                          return _FeedTile(
                            feed: feed,
                            aspectRatio: aspectRatio,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FeedDetailScreen(
                                    feedId: feed.feedId,
                                    isMine: false,
                                  ),
                                ),
                              );
                            },
                            onLikeTap: () => ref
                                .read(feedListProvider.notifier)
                                .toggleLike(feed.feedId),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final FeedListResponseDto feed;
  final double aspectRatio;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  const _FeedTile({
    required this.feed,
    this.aspectRatio = 0.7,
    this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final liked = feed.liked ?? false;
    final likeCount = feed.likeCount ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    feed.styleImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.BORDER_COLOR,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x99000000),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Row(
                        children: [
                          Expanded(child: _AuthorBadge(feed: feed)),
                          _LikeButton(
                            liked: liked,
                            count: likeCount,
                            onTap: onLikeTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              feed.feedTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  final FeedListResponseDto feed;
  const _AuthorBadge({required this.feed});

  @override
  Widget build(BuildContext context) {
    final nickname = feed.authorNickname ?? '';
    final profile = feed.authorProfileImageUrl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 22,
            height: 22,
            child: profile != null && profile.isNotEmpty
                ? Image.network(
                    profile,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.BORDER_COLOR,
        child: const Icon(Icons.person, size: 16, color: AppColors.MEDIUM_GREY),
      );
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback? onTap;

  const _LikeButton({
    required this.liked,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x55000000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: liked ? Colors.redAccent : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
