import 'dart:io';

import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/layout/default_layout.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/view/fashion_feed_screen.dart';
import 'package:capstone_fe/follow/component/notification_bell_icon.dart';
import 'package:capstone_fe/fitting/component/fitting_onboarding_sheet.dart';
import 'package:capstone_fe/fitting/view/fitting_room_screen.dart';
import 'package:capstone_fe/fitting/view/weather_recommendation_screen.dart';
import 'package:capstone_fe/home/view/home_screen.dart';
import 'package:capstone_fe/personal_closet/view/wardrobe_screen.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/user_profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class RootTab extends StatefulWidget {
  const RootTab({super.key});

  @override
  State<RootTab> createState() => _RootTabState();
}

class _RootTabState extends State<RootTab> with SingleTickerProviderStateMixin {
  late TabController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 5, vsync: this);
    controller.addListener(tabListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    // 페이지 전환 애니메이션 완료 대기
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      final repo = AuthRepository(Dio(), baseUrl: baseUrl);
      final me = await repo.getMe(createAuthDio());
      if (!mounted) return;

      final hasServerProfile =
          me != null &&
          (me.height != null && me.height! > 0) &&
          (me.weight != null && me.weight! > 0);

      // 분기 1: 서버에 신체 정보 없음 → 최초 유저, 온보딩 팝업
      if (!hasServerProfile) {
        _showOnboardingSheet();
        return;
      }

      // 분기 2: 서버 값은 있지만 로컬 FittingProfile 없음 → 새 기기 자동 복원
      final localProfile = await FittingProfile.load();
      if (localProfile != null) return;

      String? savedFrontPath;
      final imageUrl = me.profileImageUrl?.trim();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await Dio().get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.data != null) {
            final dir = await getApplicationDocumentsDirectory();
            final profileDir = Directory('${dir.path}/fitting_profile');
            if (!await profileDir.exists()) {
              await profileDir.create(recursive: true);
            }
            final file = File('${profileDir.path}/front_restored.jpg');
            await file.writeAsBytes(response.data!);
            savedFrontPath = file.path;
          }
        } catch (e) {
          debugPrint('프로필 이미지 다운로드 실패: $e');
        }
      }

      await FittingProfile.save(
        FittingProfile(
          frontImagePath: savedFrontPath,
          onboardingCompleted: true,
        ),
      );
    } catch (_) {
      // 네트워크 오류 등 서버 조회 실패 시 스킵
    }
  }

  void _showOnboardingSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FittingOnboardingSheet(
        onStart: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  void dispose() {
    controller.removeListener(tabListener);
    super.dispose();
  }

  void tabListener() {
    final newIndex = controller.index;
    setState(() => index = newIndex);
    if (newIndex == 0) {
      FittingRoomScreen.onFittingTabSelected?.call();
    }
    if (newIndex == 1) {
      WardrobeScreen.onWardrobeTabSelected?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = (index == 0);
    return DefaultLayout(
      backgroundColor: const Color(0xFFF5F5F7),
      appBarBackgroundColor: const Color(0xFFF5F5F7),
      title: showAppBar
          ? Text(
              '다이버바',
              style: GoogleFonts.blackHanSans(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            )
          : null,
      actions: showAppBar
          ? [
              const NotificationBellIcon(),
            ]
          : null,
      bottomNavigationBar: _CustomBottomBar(
        currentIndex: index,
        onTap: (i) => controller.animateTo(i),
      ),

      child: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: [
          FittingRoomScreen(),
          WardrobeScreen(),
          HomeScreen(
            onGoToFittingRoom: () => controller.animateTo(0),
            onGoToStyleRecommendation: () => controller.animateTo(0),
            onWeather: () => navigateToWeatherRecommendation(context),
          ),
          FashionFeedScreen(),
          UserProfileScreen(),
        ],
      ),
    );
  }
}

class _CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(0, Icons.home_outlined, Icons.home, '홈'),
              _buildTab(
                1,
                Icons.door_sliding_outlined,
                Icons.door_sliding,
                '옷장',
              ),
              _buildTab(2, Icons.checkroom_outlined, Icons.checkroom, 'AI추천'),
              _buildTab(3, Icons.grid_view_outlined, Icons.grid_view, '피드'),
              _buildTab(
                4,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'MY',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int i, IconData icon, IconData activeIcon, String label) {
    final selected = currentIndex == i;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 26,
                color: selected
                    ? AppColors.PRIMARYCOLOR
                    : AppColors.MEDIUM_GREY,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.PRIMARYCOLOR
                      : AppColors.MEDIUM_GREY,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
