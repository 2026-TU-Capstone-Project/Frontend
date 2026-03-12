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

  static const double _centerButtonSize = 56.0;

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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTab(0, Icons.home_outlined, Icons.home, '홈'),
                  _buildTab(
                    1,
                    Icons.door_sliding_outlined,
                    Icons.door_sliding,
                    '옷장',
                  ),
                  const SizedBox(width: _centerButtonSize + 8),
                  _buildTab(3, Icons.grid_view_outlined, Icons.grid_view, '피드'),
                  _buildTab(
                    4,
                    Icons.person_outline_rounded,
                    Icons.person_rounded,
                    'MY',
                  ),
                ],
              ),
              Positioned(
                top: -12,
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _centerButtonSize,
                        height: _centerButtonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.ACCENT_BLUE,
                              AppColors.ACCENT_PURPLE,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ACCENT_BLUE.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          currentIndex == 2
                              ? Icons.checkroom
                              : Icons.checkroom_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '피팅룸',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: currentIndex == 2
                              ? AppColors.ACCENT_BLUE
                              : AppColors.MEDIUM_GREY,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
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
