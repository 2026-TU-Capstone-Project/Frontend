import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/provider/follow_provider.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:capstone_fe/user/view/user_public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FollowListType { followers, followings }

class FollowListScreen extends ConsumerStatefulWidget {
  final FollowListType initialType;
  final int? userId;

  const FollowListScreen({
    super.key,
    required this.initialType,
    this.userId,
  });

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
    final myUserId = ref.watch(userMeProvider).valueOrNull?.userId;
    final targetUserId = widget.userId ?? myUserId;
    final isSelf = targetUserId != null && targetUserId == myUserId;

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
      body: targetUserId == null
          ? const _EmptyView(message: '로그인 정보를 불러올 수 없어요.')
          : TabBarView(
              controller: _tabController,
              children: [
                _FollowersTab(userId: targetUserId),
                _FollowingsTab(userId: targetUserId, isSelf: isSelf),
              ],
            ),
    );
  }
}

class _FollowersTab extends ConsumerStatefulWidget {
  final int userId;
  const _FollowersTab({required this.userId});

  @override
  ConsumerState<_FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends ConsumerState<_FollowersTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(followersProvider(widget.userId).notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncFollowers = ref.watch(followersProvider(widget.userId));
    return asyncFollowers.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.read(followersProvider(widget.userId).notifier).refresh(),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const _EmptyView(message: '아직 팔로워가 없어요.');
        }
        final itemCount = state.items.length + (state.isFetchingMore ? 1 : 0);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(followersProvider(widget.userId).notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final user = state.items[index];
              return _UserRow(user: user);
            },
          ),
        );
      },
    );
  }
}

class _FollowingsTab extends ConsumerStatefulWidget {
  final int userId;
  final bool isSelf;
  const _FollowingsTab({required this.userId, required this.isSelf});

  @override
  ConsumerState<_FollowingsTab> createState() => _FollowingsTabState();
}

class _FollowingsTabState extends ConsumerState<_FollowingsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(followingsProvider(widget.userId).notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncFollowings = ref.watch(followingsProvider(widget.userId));
    return asyncFollowings.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.read(followingsProvider(widget.userId).notifier).refresh(),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const _EmptyView(message: '아직 팔로잉한 유저가 없어요.');
        }
        final itemCount = state.items.length + (state.isFetchingMore ? 1 : 0);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(followingsProvider(widget.userId).notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final user = state.items[index];
              return _UserRow(
                user: user,
                trailing: widget.isSelf
                    ? _UnfollowButton(
                        listOwnerId: widget.userId,
                        targetUserId: user.userId,
                      )
                    : null,
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
  final int listOwnerId;
  final int? targetUserId;
  const _UnfollowButton({
    required this.listOwnerId,
    required this.targetUserId,
  });

  @override
  ConsumerState<_UnfollowButton> createState() => _UnfollowButtonState();
}

class _UnfollowButtonState extends ConsumerState<_UnfollowButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    final id = widget.targetUserId;
    if (id == null || _busy) return;

    final confirm = await AppDialog.confirm(
      context: context,
      title: '언팔로우',
      content: '이 유저를 언팔로우하시겠어요?',
      confirmLabel: '언팔로우',
      confirmIsDestructive: true,
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(followingsProvider(widget.listOwnerId).notifier)
          .unfollow(id);
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
