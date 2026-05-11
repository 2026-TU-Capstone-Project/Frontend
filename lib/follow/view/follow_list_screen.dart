import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/provider/follow_provider.dart';
import 'package:capstone_fe/user/view/user_public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FollowListType { followers, followings }

class FollowListScreen extends ConsumerStatefulWidget {
  final FollowListType initialType;

  const FollowListScreen({super.key, required this.initialType});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == FollowListType.followers ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.BLACK,
        title: const Text(
          '팔로우',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.BLACK,
          unselectedLabelColor: AppColors.MEDIUM_GREY,
          indicatorColor: AppColors.BLACK,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: '팔로워'),
            Tab(text: '팔로잉'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FollowersTab(),
          _FollowingsTab(),
        ],
      ),
    );
  }
}

class _FollowersTab extends ConsumerWidget {
  const _FollowersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFollowers = ref.watch(myFollowersProvider);
    return asyncFollowers.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(myFollowersProvider.notifier).refresh(),
      ),
      data: (followers) {
        if (followers.isEmpty) {
          return const _EmptyView(message: '아직 팔로워가 없어요.');
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myFollowersProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: followers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final user = followers[index];
              return _UserRow(user: user);
            },
          ),
        );
      },
    );
  }
}

class _FollowingsTab extends ConsumerWidget {
  const _FollowingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFollowings = ref.watch(myFollowingsProvider);
    return asyncFollowings.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(myFollowingsProvider.notifier).refresh(),
      ),
      data: (followings) {
        if (followings.isEmpty) {
          return const _EmptyView(message: '아직 팔로잉한 유저가 없어요.');
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myFollowingsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: followings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final user = followings[index];
              return _UserRow(
                user: user,
                trailing: _UnfollowButton(targetUserId: user.userId),
              );
            },
          ),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  final FollowResponse user;
  final Widget? trailing;

  const _UserRow({required this.user, this.trailing});

  @override
  Widget build(BuildContext context) {
    final displayName = (user.nickname?.trim().isNotEmpty == true)
        ? user.nickname!.trim()
        : (user.username?.trim() ?? '알 수 없음');
    final imageUrl = user.profileImageUrl?.trim();

    return InkWell(
      onTap: user.userId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      UserPublicProfileScreen(userId: user.userId!),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _Avatar(imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.BLACK,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((user.username ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username!.trim()}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.MEDIUM_GREY,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.INPUT_BG_COLOR,
        border: Border.all(color: AppColors.BORDER_COLOR),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: AppColors.MEDIUM_GREY,
                ),
              )
            : const Icon(Icons.person_rounded, color: AppColors.MEDIUM_GREY),
      ),
    );
  }
}

class _UnfollowButton extends ConsumerStatefulWidget {
  final int? targetUserId;
  const _UnfollowButton({required this.targetUserId});

  @override
  ConsumerState<_UnfollowButton> createState() => _UnfollowButtonState();
}

class _UnfollowButtonState extends ConsumerState<_UnfollowButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    final id = widget.targetUserId;
    if (id == null || _busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('언팔로우'),
        content: const Text('이 유저를 언팔로우하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '언팔로우',
              style: TextStyle(color: AppColors.ERROR_COLOR),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(myFollowingsProvider.notifier).unfollow(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('언팔로우 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy ? null : _onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.BLACK,
        side: const BorderSide(color: AppColors.BORDER_COLOR),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(0, 32),
      ),
      child: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              '팔로잉',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.MEDIUM_GREY,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '불러오기 실패',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
