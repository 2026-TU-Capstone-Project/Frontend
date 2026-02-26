import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/feed/view/feed_write_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 피드 탭 메인: 전체 피드 목록 + 내 피드/글쓰기 진입
class FashionFeedScreen extends StatefulWidget {
  const FashionFeedScreen({super.key});

  @override
  State<FashionFeedScreen> createState() => _FashionFeedScreenState();
}

class _FashionFeedScreenState extends State<FashionFeedScreen> {
  final FeedRepository _feedRepository =
      FeedRepository(createAuthDio(), baseUrl: baseUrl);

  List<FeedListItem> _feeds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _feedRepository.getFeeds();
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        setState(() {
          _feeds = resp.data!;
          _loading = false;
        });
      } else {
        setState(() {
          _error = resp.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            _loadFeeds();
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
                      '${_feeds.length}개의 게시물',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.MEDIUM_GREY,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.BODY_COLOR),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadFeeds,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (_feeds.isEmpty) {
      return const Center(
        child: Text(
          '아직 피드가 없어요.\n첫 피드를 올려보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.MEDIUM_GREY),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _feeds.length,
        itemBuilder: (context, index) {
          final feed = _feeds[index];
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
          );
        },
      ),
    );
  }
}

/// 목록용 타일 (스타일 이미지 + 제목)
class _FeedTile extends StatelessWidget {
  final FeedListItem feed;
  final double aspectRatio;
  final VoidCallback? onTap;

  const _FeedTile({
    required this.feed,
    this.aspectRatio = 0.7,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.network(
                feed.styleImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.BORDER_COLOR,
                  child: const Icon(Icons.broken_image_outlined),
                ),
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
