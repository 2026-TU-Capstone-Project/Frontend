import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/follow/provider/follow_provider.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPublicProfileScreen extends ConsumerWidget {
  final int userId;

  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(userPublicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.BLACK,
        title: const Text(
          '프로필',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
      ),
      body: asyncProfile.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '프로필을 불러올 수 없어요.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ),
        ),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserPublicProfile profile;

  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = profile.userId;
    if (userId == null) return const SizedBox();

    final displayName = (profile.nickname?.trim().isNotEmpty == true)
        ? profile.nickname!.trim()
        : (profile.username?.trim() ?? '유저');
    final imageUrl = profile.profileImageUrl?.trim();

    // 실시간 팔로우 수치 구독
    final followersAsync = ref.watch(userFollowersProvider(userId));
    final followingsAsync = ref.watch(userFollowingsProvider(userId));
    
    final followerCount = followersAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => profile.followerCount ?? 0,
    );
    final followingCount = followingsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => profile.followingCount ?? 0,
    );

    final feedsAsync = ref.watch(userFeedsProvider(
      (userId: userId, nickname: profile.nickname),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPublicProfileProvider(userId));
        ref.invalidate(userFollowersProvider(userId));
        ref.invalidate(userFollowingsProvider(userId));
        ref.invalidate(feedListProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.INPUT_BG_COLOR,
                          border: Border.all(
                              color: AppColors.BORDER_COLOR, width: 2),
                        ),
                        child: ClipOval(
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: AppColors.MEDIUM_GREY,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: AppColors.MEDIUM_GREY,
                                ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.BLACK,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((profile.username ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@${profile.username!.trim()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.MEDIUM_GREY,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        count: feedsAsync.maybeWhen(
                          data: (list) => '${list.length}',
                          orElse: () => '-',
                        ),
                        label: '게시물',
                      ),
                      _StatItem(count: '$followerCount', label: '팔로워'),
                      _StatItem(count: '$followingCount', label: '팔로잉'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FollowToggleButton(
                    userId: userId,
                    isFollowing: profile.isFollowing ?? false,
                    isRequested: profile.isRequested ?? false,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          feedsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingIndicator(),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    '피드를 불러올 수 없어요.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.MEDIUM_GREY,
                    ),
                  ),
                ),
              ),
            ),
            data: (feeds) => feeds.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          '아직 게시한 피드가 없어요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.MEDIUM_GREY,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = feeds[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FeedDetailScreen(feedId: item.feedId),
                            ),
                          ),
                          child: Image.network(
                            item.styleImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.INPUT_BG_COLOR,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ),
                        );
                      }, childCount: feeds.length),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.BODY_COLOR),
        ),
      ],
    );
  }
}

class _FollowToggleButton extends ConsumerStatefulWidget {
  final int userId;
  final bool isFollowing;
  final bool isRequested;

  const _FollowToggleButton({
    required this.userId,
    required this.isFollowing,
    required this.isRequested,
  });

  @override
  ConsumerState<_FollowToggleButton> createState() =>
      _FollowToggleButtonState();
}

class _FollowToggleButtonState extends ConsumerState<_FollowToggleButton> {
  late bool _isFollowing;
  late bool _isRequested;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _isRequested = widget.isRequested;
  }

  @override
  void didUpdateWidget(covariant _FollowToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing ||
        oldWidget.isRequested != widget.isRequested) {
      setState(() {
        _isFollowing = widget.isFollowing;
        _isRequested = widget.isRequested;
      });
    }
  }

  Future<void> _onPressed() async {
    if (_busy) return;
    setState(() => _busy = true);

    final notifier = ref.read(followActionProvider(widget.userId).notifier);
    try {
      if (_isFollowing || _isRequested) {
        await notifier.unfollow();
        if (!mounted) return;
        setState(() {
          _isFollowing = false;
          _isRequested = false;
        });
      } else {
        await notifier.follow();
        if (!mounted) return;
        setState(() => _isFollowing = true);
      }
      
      // 관련 상태들 즉시 무효화 -> 부모 위젯인 _ProfileBody 가 다시 빌드됨
      ref.invalidate(userPublicProfileProvider(widget.userId));
      ref.invalidate(userFollowersProvider(widget.userId));
      ref.invalidate(myFollowingsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = _isFollowing;
    final requested = _isRequested;

    final label = following
        ? '팔로잉'
        : (requested ? '요청됨' : '팔로우');
    final isOutlined = following || requested;

    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: _busy ? null : _onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.BLACK,
                side: const BorderSide(color: AppColors.BORDER_COLOR),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )
          : ElevatedButton(
              onPressed: _busy ? null : _onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ACCENT_COLOR,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
    );
  }
}
