import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:capstone_fe/feed/view/feed_detail_screen.dart';
import 'package:capstone_fe/fitting/component/fitting_profile_edit_sheet.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/component/user_me_edit_sheet.dart';
import 'package:capstone_fe/user/view/login_screen.dart';
import 'package:dio/dio.dart';

/// RootTab 유저 탭: 마이페이지(서버 GET/PATCH /users/me) + 피팅 프로필(로컬)
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserMe? _me;
  FittingProfile? _profile;
  String? _nicknameFromStorage;
  bool _loading = true;
  List<FeedListItem> _myFeeds = [];

  final FeedRepository _feedRepo = FeedRepository(createAuthDio(), baseUrl: baseUrl);

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
    final p = await FittingProfile.load();
    final stored = await const FlutterSecureStorage().read(key: 'NICKNAME');
    List<FeedListItem> myFeeds = [];
    try {
      final feedResp = await _feedRepo.getMyFeeds();
      if (feedResp.success && feedResp.data != null) myFeeds = feedResp.data!;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _me = me;
        _profile = p;
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
      builder: (context) => UserMeEditSheet(
        initial: _me,
        onSaved: _load,
        onLogout: _onLogout,
      ),
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openFittingProfileEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FittingProfileEditSheet(
        initialProfile: _profile,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
      );
    }

    final hasProfile = _profile != null && _profile!.hasAnyData;
    final p = _profile;
    final me = _me;
    // 수정 후 저장된 닉네임(스토리지) 우선, 없으면 서버 값
    final nickname = _nicknameFromStorage?.trim().isNotEmpty == true
        ? _nicknameFromStorage!.trim()
        : me?.nickname?.trim();
    final displayName = (nickname != null && nickname.isNotEmpty) ? nickname : '내 프로필';
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
                    _buildAvatar(me, p),
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
                          const SizedBox(height: 4),
                          Text(
                            hasProfile ? '피팅 프로필이 등록되어 있어요' : '피팅 프로필을 등록해보세요',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.BODY_COLOR,
                            ),
                          ),
                          if (me != null) ...[
                            const SizedBox(height: 4),
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
                            side: const BorderSide(color: AppColors.BORDER_COLOR),
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
                              const SnackBar(content: Text('프로필 공유 기능은 준비 중이에요.')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.BLACK,
                            side: const BorderSide(color: AppColors.BORDER_COLOR),
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

          // 메뉴/카드 영역
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFittingProfileCard(hasProfile, p),
                const SizedBox(height: 12),
                _buildInfoCard(),
              ]),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                              child: Icon(Icons.broken_image_outlined, color: AppColors.MEDIUM_GREY),
                            ),
                          ),
                        );
                      },
                      childCount: _myFeeds.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// 헤더용 아바타: 서버 profileImageUrl 우선, 없으면 로컬 피팅 정면 사진, 없으면 기본 아이콘
  Widget _buildAvatar(UserMe? me, FittingProfile? p) {
    final networkUrl = me?.profileImageUrl?.trim();
    final localPath = p?.frontImagePath;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.INPUT_BG_COLOR,
        border: Border.all(color: AppColors.BORDER_COLOR, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: networkUrl != null && networkUrl.isNotEmpty
            ? Image.network(networkUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatarIcon())
            : localPath != null
                ? _imageFromPath(localPath)
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            size: 14,
            color: color,
          ),
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
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.BODY_COLOR,
          ),
        ),
      ],
    );
  }

  Widget _imageFromPath(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _defaultAvatarIcon();
    }
    return Image.file(file, fit: BoxFit.cover);
  }

  /// 피팅 프로필 카드: 있으면 요약 + 수정, 없으면 등록 유도
  Widget _buildFittingProfileCard(bool hasProfile, FittingProfile? p) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: _openFittingProfileEditSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.BORDER_COLOR),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.PRIMARYCOLOR.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.checkroom_outlined,
                      color: AppColors.PRIMARYCOLOR,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '피팅 프로필',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.BLACK,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.MEDIUM_GREY,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasProfile && p != null) ...[
                _buildProfileSummary(p),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openFittingProfileEditSheet,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.ACCENT_COLOR),
                    label: const Text(
                      '수정',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ACCENT_COLOR,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  '정면 사진과 상의·하의 사이즈를 등록해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.BODY_COLOR,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openFittingProfileEditSheet,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('등록하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.PRIMARYCOLOR,
                      side: const BorderSide(color: AppColors.PRIMARYCOLOR),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 피팅 프로필 한 줄 요약 (상의·하의 사이즈)
  Widget _buildProfileSummary(FittingProfile p) {
    final parts = <String>[];
    if (p.topSize != null && p.topSize!.isNotEmpty) parts.add('상의 ${p.topSize}');
    if (p.bottomSize != null && p.bottomSize!.isNotEmpty) parts.add('하의 ${p.bottomSize}');
    final summary = parts.isEmpty ? '미입력' : parts.join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.INPUT_BG_COLOR,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (p.frontImagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _imageFromPath(p.frontImagePath!),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.BODY_COLOR,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 안내 카드 (선택)
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ACCENT_COLOR.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ACCENT_COLOR.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.ACCENT_COLOR),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '입력하신 정보는 가상 피팅 목적으로만 사용되며 안전하게 보호됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.BODY_COLOR,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
