import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/provider/follow_provider.dart';
import 'package:capstone_fe/user/view/user_public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(followRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.BLACK,
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
      ),
      body: asyncRequests.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(followRequestsProvider.notifier).refresh(),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(followRequestsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return _RequestRow(request: requests[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestRow extends ConsumerStatefulWidget {
  final FollowRequestResponse request;

  const _RequestRow({required this.request});

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String failMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failMsg: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final displayName = (r.nickname?.trim().isNotEmpty == true)
        ? r.nickname!.trim()
        : (r.username?.trim() ?? '알 수 없음');
    final imageUrl = r.profileImageUrl?.trim();

    return InkWell(
      onTap: r.requesterId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      UserPublicProfileScreen(userId: r.requesterId!),
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
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.BLACK,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '님이 회원님을 팔로우하려고 합니다.'),
                      ],
                    ),
                  ),
                  if ((r.username ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${r.username!.trim()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.MEDIUM_GREY,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ActionButtons(
              busy: _busy,
              onAccept: r.followId == null
                  ? null
                  : () => _run(
                        () => ref
                            .read(followRequestsProvider.notifier)
                            .accept(r.followId!),
                        '수락 실패',
                      ),
              onReject: r.followId == null
                  ? null
                  : () => _run(
                        () => ref
                            .read(followRequestsProvider.notifier)
                            .reject(r.followId!),
                        '거절 실패',
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ActionButtons({
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.PRIMARYCOLOR,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '수락',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.BLACK,
            side: const BorderSide(color: AppColors.BORDER_COLOR),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '거절',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: AppColors.MEDIUM_GREY,
          ),
          const SizedBox(height: 8),
          const Text(
            '받은 알림이 없어요',
            style: TextStyle(fontSize: 14, color: AppColors.MEDIUM_GREY),
          ),
        ],
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
          const Text(
            '불러오기 실패',
            style: TextStyle(
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
