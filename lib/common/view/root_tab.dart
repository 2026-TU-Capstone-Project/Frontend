import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/layout/default_layout.dart';
import 'package:capstone_fe/feed/view/fashion_feed_screen.dart';
import 'package:capstone_fe/fitting/view/fitting_room_screen.dart';
import 'package:capstone_fe/fitting/view/weather_recommendation_screen.dart';
import 'package:capstone_fe/home/view/home_screen.dart';
import 'package:capstone_fe/personal_closet/view/wardrobe_screen.dart';
import 'package:capstone_fe/user/view/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  }

  @override
  void dispose() {
    controller.removeListener(tabListener);
    super.dispose();
  }

  void tabListener() {
    final newIndex = controller.index;
    setState(() => index = newIndex);
    if (newIndex == 2) {
      FittingRoomScreen.onFittingTabSelected?.call();
    }
    if (newIndex == 1) {
      WardrobeScreen.onWardrobeTabSelected?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 홈(0)에서만 앱바 표시, 피팅룸/옷장/피드/유저(1~4)에서는 앱바 없음
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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
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
          HomeScreen(
            onGoToFittingRoom: () => controller.animateTo(2),
            onGoToStyleRecommendation: () => controller.animateTo(2),
            onWeather: () => navigateToWeatherRecommendation(context),
          ),
          WardrobeScreen(),
          FittingRoomScreen(),
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

  const _CustomBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

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
              _buildTab(1, Icons.door_sliding_outlined, Icons.door_sliding, '옷장'),
              _buildTab(2, Icons.checkroom_outlined, Icons.checkroom, '피팅룸'),
              _buildTab(3, Icons.grid_view_outlined, Icons.grid_view, '피드'),
              _buildTab(4, Icons.person_outline_rounded, Icons.person_rounded, 'MY'),
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
                color: selected ? AppColors.PRIMARYCOLOR : AppColors.MEDIUM_GREY,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected ? AppColors.PRIMARYCOLOR : AppColors.MEDIUM_GREY,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
