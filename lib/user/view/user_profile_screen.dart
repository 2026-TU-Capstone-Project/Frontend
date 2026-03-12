import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/component/user_me_edit_sheet.dart';
import 'package:capstone_fe/user/view/social_login_screen.dart';
import 'package:dio/dio.dart';

/// RootTab 유저 탭: 마이페이지(서버 GET/PATCH /users/me)
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserMe? _me;
  String? _nicknameFromStorage;
  bool _loading = true;
  List<FeedListItem> _myFeeds = [];

  final FeedRepository _feedRepo = FeedRepository(
    createAuthDio(),
    baseUrl: baseUrl,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final authDio = createAuthDio();
    final repo = AuthRepository(Dio(), baseUrl: baseUrl);
    final me = await repo.getMe(authDio);
    final stored = await const FlutterSecureStorage().read(key: 'NICKNAME');
    List<FeedListItem> myFeeds = [];
    try {
      final feedResp = await _feedRepo.getMyFeeds();
      if (feedResp.success && feedResp.data != null) myFeeds = feedResp.data!;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _me = me;
        _nicknameFromStorage = stored;
        _myFeeds = myFeeds;
        _loading = false;
      });
    }
  }

  void _openMeEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          UserMeEditSheet(initial: _me, onSaved: _load, onLogout: _onLogout),
    );
  }

  Future<void> _onLogout() async {
    final storage = const FlutterSecureStorage();
    final refreshToken = await storage.read(key: 'REFRESH_TOKEN');
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final authRepository = AuthRepository(Dio(), baseUrl: baseUrl);
        await authRepository.logout(refreshToken: refreshToken);
      }
    } catch (_) {}
    await storage.deleteAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SocialLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
      );
    }

    final me = _me;
    // 수정 후 저장된 닉네임(스토리지) 우선, 없으면 서버 값
    final nickname = _nicknameFromStorage?.trim().isNotEmpty == true
        ? _nicknameFromStorage!.trim()
        : me?.nickname?.trim();
    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : '내 프로필';
    final gender = me?.gender?.trim();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 프로필 헤더: 서버 프로필 이미지/닉네임, 탭 시 마이페이지 수정 시트
          SliverToBoxAdapter(
            child: InkWell(
              onTap: _openMeEditSheet,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Row(
                  children: [
                    _buildAvatar(me),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.BLACK,
                                ),
                              ),
                              if (gender != null && gender.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _buildGenderBadge(gender),
                              ],
                            ],
                          ),
                          if (me != null) ...[
                            if ((me.email ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                me.email!.trim(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.BODY_COLOR,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if ((me.height ?? 0) > 0 || (me.weight ?? 0) > 0) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if ((me.height ?? 0) > 0)
                                    _buildInfoChip(
                                      '키 ${me.height!.toStringAsFixed(0)}cm',
                                    ),
                                  if ((me.weight ?? 0) > 0)
                                    _buildInfoChip(
                                      '몸무게 ${me.weight!.toStringAsFixed(0)}kg',
                                    ),
                                ],
                              ),
                            ],
                          ],
                          if (me != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '프로필 수정하기',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.ACCENT_COLOR,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 인스타 스타일: 게시물 수 · 프로필 편집/공유
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('${_myFeeds.length}', '게시물'),
                      _buildStatItem('0', '팔로워'),
                      _buildStatItem('0', '팔로잉'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openMeEditSheet,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.BLACK,
                            side: const BorderSide(
                              color: AppColors.BORDER_COLOR,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('프로필 편집'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('프로필 공유 기능은 준비 중이에요.'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.BLACK,
                            side: const BorderSide(
                              color: AppColors.BORDER_COLOR,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('프로필 공유'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _myFeeds.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          '아직 게시한 피드가 없어요.\n피드 탭에서 올려보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.MEDIUM_GREY,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _myFeeds[index];
                      return GestureDetector(
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FeedDetailScreen(
                                feedId: item.feedId,
                                isMine: true,
                              ),
                            ),
                          );
                          if (deleted == true) _load();
                        },
                        child: Image.network(
                          item.styleImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.INPUT_BG_COLOR,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.MEDIUM_GREY,
                            ),
                          ),
                        ),
                      );
                    }, childCount: _myFeeds.length),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// 헤더용 아바타: 서버 profileImageUrl 우선, 없으면 기본 아이콘
  Widget _buildAvatar(UserMe? me) {
    final networkUrl = me?.profileImageUrl?.trim();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.INPUT_BG_COLOR,
        border: Border.all(color: AppColors.BORDER_COLOR, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: networkUrl != null && networkUrl.isNotEmpty
            ? Image.network(
                networkUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatarIcon(),
              )
            : _defaultAvatarIcon(),
      ),
    );
  }

  /// 성별 뱃지: 남성 파란색, 여성 빨간색(핑크)
  Widget _buildGenderBadge(String gender) {
    final isMale = gender.toUpperCase() == 'MALE';
    final color = isMale ? Colors.blue : Colors.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isMale ? Icons.male : Icons.female, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isMale ? '남' : '여',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatarIcon() {
    return Icon(Icons.person_rounded, size: 40, color: AppColors.MEDIUM_GREY);
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.INPUT_BG_COLOR,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.BORDER_COLOR),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.BODY_COLOR,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 인스타 스타일 통계 한 칸 (게시물 / 팔로워 / 팔로잉)
  Widget _buildStatItem(String count, String label) {
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
