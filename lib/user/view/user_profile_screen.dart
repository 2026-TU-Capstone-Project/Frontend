import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/component/fitting_profile_edit_sheet.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';

/// RootTab 유저 탭: 다른 앱의 마이페이지처럼 헤더 + 카드형 메뉴, 피팅 프로필 수정 가능
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  FittingProfile? _profile;
  String? _nickname;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await FittingProfile.load();
    final n = await const FlutterSecureStorage().read(key: 'NICKNAME');
    if (mounted) {
      setState(() {
        _profile = p;
        _nickname = n;
        _loading = false;
      });
    }
  }

  void _openEditSheet() {
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

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 프로필 헤더 (다른 앱 유저 탭 스타일)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                children: [
                  _buildAvatar(p),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_nickname != null && _nickname!.isNotEmpty)
                              ? '$_nickname 프로필'
                              : '내 프로필',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.BLACK,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasProfile ? '피팅 프로필이 등록되어 있어요' : '피팅 프로필을 등록해보세요',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.BODY_COLOR,
                          ),
                        ),
                      ],
                    ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// 헤더용 아바타: 프로필에 정면 사진이 있으면 썸네일, 없으면 기본 아이콘
  Widget _buildAvatar(FittingProfile? p) {
    String? path = p?.frontImagePath;
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
        child: path != null
            ? _imageFromPath(path)
            : Icon(
                Icons.person_rounded,
                size: 40,
                color: AppColors.MEDIUM_GREY,
              ),
      ),
    );
  }

  Widget _imageFromPath(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Icon(Icons.person_rounded, size: 40, color: AppColors.MEDIUM_GREY);
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
        onTap: _openEditSheet,
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
                    onPressed: _openEditSheet,
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
                  '가상 피팅을 위해 전신 사진과 신체 정보를 등록해주세요.',
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
                    onPressed: _openEditSheet,
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

  /// 신체 정보 한 줄 요약 (키 · 상의 · 신발 등)
  Widget _buildProfileSummary(FittingProfile p) {
    final parts = <String>[];
    if (p.height != null && p.height!.isNotEmpty) parts.add('키 ${p.height}cm');
    if (p.weight != null && p.weight!.isNotEmpty) parts.add('${p.weight}kg');
    if (p.topSize != null && p.topSize!.isNotEmpty) parts.add('상의 ${p.topSize}');
    if (p.bottomSize != null && p.bottomSize!.isNotEmpty) parts.add('하의 ${p.bottomSize}');
    if (p.shoeSize != null && p.shoeSize!.isNotEmpty) parts.add('신발 ${p.shoeSize}mm');
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
