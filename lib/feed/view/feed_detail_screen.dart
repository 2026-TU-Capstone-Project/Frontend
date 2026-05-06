import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 피드 상세: feedDetailProvider로 데이터 구독.
/// isMine은 파라미터 or myFeedListProvider에서 파생 (별도 API 호출 없음).
class FeedDetailScreen extends ConsumerWidget {
  final int feedId;
  final bool isMine;

  const FeedDetailScreen({
    super.key,
    required this.feedId,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(feedDetailProvider(feedId));

    // isMine 판별: 파라미터가 true이거나, 내 피드 목록에 해당 feedId가 있을 때
    final isActuallyMine = isMine ||
        (ref.watch(myFeedListProvider).valueOrNull
                ?.any((f) => f.feedId == feedId) ??
            false);

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
          '피드',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
        actions: isActuallyMine
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _editFeed(context, ref, detailAsync.valueOrNull),
                  tooltip: '수정',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteFeed(context, ref),
                  tooltip: '삭제',
                ),
              ]
            : null,
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
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
                    ref.read(feedDetailProvider(feedId).notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (d) => _DetailBody(d: d, feedId: feedId),
      ),
    );
  }

  Future<void> _deleteFeed(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '피드 삭제',
      content: '이 피드를 삭제할까요?',
      confirmLabel: '삭제',
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final repo = ref.read(feedRepositoryProvider);
      final resp = await repo.delete(feedId);
      if (!context.mounted) return;
      if (resp.success) {
        ref.invalidate(feedListProvider);
        ref.invalidate(myFeedListProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('삭제되었어요.')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _editFeed(
      BuildContext context, WidgetRef ref, FeedDetailResponseDto? detail) async {
    if (detail == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FeedEditScreen(
          feedId: feedId,
          initialTitle: detail.feedTitle ?? '',
          initialContent: detail.feedContent ?? '',
        ),
      ),
    );
    if (result == true) {
      ref.read(feedDetailProvider(feedId).notifier).refresh();
    }
  }
}

// ─────────────────────────────────────────────
// 상세 본문 (순수 UI, StatelessWidget)
// ─────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final FeedDetailResponseDto d;
  final int feedId;
  const _DetailBody({required this.d, required this.feedId});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능이에요.')),
    );
  }

  void _openImageViewer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImageViewer(url: d.styleImageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = d.liked ?? false;
    final likeCount = d.likeCount ?? 0;
    final hasProfileImg = d.authorProfileImageUrl != null &&
        d.authorProfileImageUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openImageViewer(context),
            child: Hero(
              tag: 'feed-image-$feedId',
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showComingSoon(context),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.BORDER_COLOR,
                        backgroundImage: hasProfileImg
                            ? NetworkImage(d.authorProfileImageUrl!)
                            : null,
                        onBackgroundImageError:
                            hasProfileImg ? (_, __) {} : null,
                        child: hasProfileImg
                            ? null
                            : const Icon(Icons.person,
                                color: AppColors.MEDIUM_GREY),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.authorNickname,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.BLACK,
                            ),
                          ),
                          const Text(
                            '온더룩',
                            style: TextStyle(
                                color: AppColors.MEDIUM_GREY, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  d.feedTitle ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.BLACK,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (d.feedContent == null || d.feedContent!.isEmpty)
                      ? '-'
                      : d.feedContent!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.BODY_COLOR,
                  ),
                ),
                const SizedBox(height: 24),
                _LikeButton(
                  liked: liked,
                  count: likeCount,
                  onTap: () => ref
                      .read(feedDetailProvider(feedId).notifier)
                      .toggleLike(),
                ),
                const SizedBox(height: 24),
                const Text(
                  '착용 제품',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.BLACK,
                  ),
                ),
                const SizedBox(height: 12),
                if (d.topImageUrl != null || d.topName != null)
                  _WornProductCard(
                    imageUrl: d.topImageUrl,
                    productName: d.topName ?? '-',
                    onTap: d.topClothesId != null
                        ? () => _showComingSoon(context)
                        : null,
                  ),
                if (d.topImageUrl != null || d.topName != null)
                  const SizedBox(height: 10),
                if (d.bottomImageUrl != null || d.bottomName != null)
                  _WornProductCard(
                    imageUrl: d.bottomImageUrl,
                    productName: d.bottomName ?? '-',
                    onTap: d.bottomClothesId != null
                        ? () => _showComingSoon(context)
                        : null,
                  ),
                if ((d.topImageUrl == null && d.topName == null) &&
                    (d.bottomImageUrl == null && d.bottomName == null))
                  const Text(
                    '등록된 착용 제품이 없어요.',
                    style: TextStyle(
                        color: AppColors.MEDIUM_GREY, fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback onTap;
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: liked
              ? AppColors.ERROR_COLOR.withValues(alpha: 0.10)
              : AppColors.INPUT_BG_COLOR,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                liked ? AppColors.ERROR_COLOR : AppColors.BORDER_COLOR,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppColors.ERROR_COLOR : AppColors.BODY_COLOR,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '좋아요 $count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: liked ? AppColors.ERROR_COLOR : AppColors.BLACK,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  const _FullScreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.MEDIUM_GREY,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 착용 제품 카드
// ─────────────────────────────────────────────

class _WornProductCard extends StatelessWidget {
  final String? imageUrl;
  final String productName;
  final VoidCallback? onTap;

  const _WornProductCard({
    this.imageUrl,
    required this.productName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.BORDER_COLOR),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('상품',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.BLACK)),
                const SizedBox(height: 4),
                Text(productName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.BLACK,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(
            onTap != null
                ? Icons.chevron_right_rounded
                : Icons.bookmark_border_rounded,
            color: AppColors.MEDIUM_GREY,
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _placeholder() => Container(
      color: AppColors.BORDER_COLOR,
      child: const Icon(Icons.checkroom_rounded,
          size: 36, color: AppColors.MEDIUM_GREY));
}

// ─────────────────────────────────────────────
// 피드 수정 화면 (제목·내용 PATCH)
// ─────────────────────────────────────────────

class FeedEditScreen extends ConsumerStatefulWidget {
  final int feedId;
  final String initialTitle;
  final String initialContent;

  const FeedEditScreen({
    super.key,
    required this.feedId,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  ConsumerState<FeedEditScreen> createState() => _FeedEditScreenState();
}

class _FeedEditScreenState extends ConsumerState<FeedEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final resp = await ref.read(feedRepositoryProvider).update(
            widget.feedId,
            UpdateFeedBody(
              feedTitle: title,
              feedContent: _contentController.text.trim(),
            ).toJson(),
          );
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('수정되었어요.')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('피드 수정',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.BLACK)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const LoadingIndicator(size: 20)
                : const Text('저장',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('제목',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.MEDIUM_GREY)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.INPUT_BG_COLOR,
              ),
            ),
            const SizedBox(height: 20),
            const Text('내용',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.MEDIUM_GREY)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.INPUT_BG_COLOR,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
