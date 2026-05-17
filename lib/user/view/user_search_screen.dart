import 'dart:async';

import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:capstone_fe/user/view/user_public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.BLACK,
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, size: 20, color: AppColors.MEDIUM_GREY),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  cursorColor: AppColors.BLACK,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.BLACK,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '닉네임 또는 아이디 검색',
                    hintStyle: TextStyle(
                      color: AppColors.MEDIUM_GREY,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.cancel, size: 18, color: AppColors.MEDIUM_GREY),
                  onPressed: _clear,
                  splashRadius: 18,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return const Center(
        child: Text(
          '닉네임 또는 아이디를 입력해 보세요.',
          style: TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 14),
        ),
      );
    }

    final asyncResults = ref.watch(userSearchProvider(_query));
    return asyncResults.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '검색에 실패했어요.\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 14),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              '검색 결과가 없어요.',
              style: TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 14),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.BORDER_COLOR,
            indent: 72,
          ),
          itemBuilder: (context, index) => _UserTile(item: items[index]),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSearchItem item;
  const _UserTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final profile = item.profileImageUrl;
    final nickname = item.nickname ?? '';
    final username = item.username ?? '';

    return InkWell(
      onTap: () {
        final id = item.userId;
        if (id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserPublicProfileScreen(userId: id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.BORDER_COLOR,
              backgroundImage: (profile != null && profile.isNotEmpty)
                  ? NetworkImage(profile)
                  : null,
              child: (profile == null || profile.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.MEDIUM_GREY)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.BLACK,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.MEDIUM_GREY,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
