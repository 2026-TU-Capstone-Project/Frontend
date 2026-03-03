import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 내 피드 목록: GET /api/v1/feeds/me
class MyFeedListScreen extends ConsumerWidget {
  const MyFeedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(myFeedListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 피드',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.BODY_COLOR),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(myFeedListProvider.notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (feeds) {
          if (feeds.isEmpty) {
            return const Center(
              child: Text(
                '작성한 피드가 없어요.',
                style: TextStyle(color: AppColors.MEDIUM_GREY),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myFeedListProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: feeds.length,
              itemBuilder: (context, index) {
                final feed = feeds[index];
                return GestureDetector(
                  onTap: () async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedDetailScreen(
                          feedId: feed.feedId,
                          isMine: true,
                        ),
                      ),
                    );
                    if (deleted == true) {
                      ref.read(myFeedListProvider.notifier).refresh();
                    }
                  },
                  child: _FeedGridItem(feed: feed),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedGridItem extends StatelessWidget {
  final FeedListItem feed;
  const _FeedGridItem({required this.feed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              feed.styleImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.BORDER_COLOR,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          feed.feedTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.BLACK,
          ),
        ),
      ],
    );
  }
}
