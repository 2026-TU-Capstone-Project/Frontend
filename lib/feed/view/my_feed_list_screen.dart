import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:flutter/material.dart';

/// 내 피드 목록: GET /api/v1/feeds/me, 탭 시 상세(수정/삭제 가능)
class MyFeedListScreen extends StatefulWidget {
  const MyFeedListScreen({super.key});

  @override
  State<MyFeedListScreen> createState() => _MyFeedListScreenState();
}

class _MyFeedListScreenState extends State<MyFeedListScreen> {
  final FeedRepository _repo =
      FeedRepository(createAuthDio(), baseUrl: baseUrl);

  List<FeedListItem> _feeds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _repo.getMyFeeds();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        onPressed: _load,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _feeds.isEmpty
                  ? const Center(
                      child: Text(
                        '작성한 피드가 없어요.',
                        style: TextStyle(color: AppColors.MEDIUM_GREY),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _feeds.length,
                        itemBuilder: (context, index) {
                          final feed = _feeds[index];
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
                              if (deleted == true) _load();
                            },
                            child: Column(
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
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
