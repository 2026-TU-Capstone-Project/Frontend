import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/layout/default_layout.dart';
import 'package:capstone_fe/feed/view/fashion_feed_screen.dart';
import 'package:capstone_fe/fitting/view/fitting_room_screen.dart';
import 'package:capstone_fe/home/view/home_screen.dart';
import 'package:capstone_fe/personal_closet/view/wardrobe_screen.dart';
import 'package:capstone_fe/user/view/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    // 피팅룸 탭으로 전환 시 헤더(키·사이즈) 갱신 → 마이페이지 수정 반영
    if (newIndex == 1) {
      FittingRoomScreen.onFittingTabSelected?.call();
    }
    // 옷장 탭으로 전환 시 닉네임 등 로컬 저장값 갱신
    if (newIndex == 2) {
      WardrobeScreen.onWardrobeTabSelected?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 홈(0)에서만 앱바 표시, 피팅룸/옷장/피드/유저(1~4)에서는 앱바 없음
    final showAppBar = (index == 0);
    return DefaultLayout(
      title: showAppBar ? SvgPicture.asset('asset/img/try-on.svg') : null,
      actions: showAppBar
          ? [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
            ]
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.PRIMARYCOLOR,
        unselectedItemColor: AppColors.MEDIUM_GREY,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          controller.animateTo(index);
        },
        currentIndex: index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: '피팅룸',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.door_sliding_outlined),
            activeIcon: Icon(Icons.door_sliding),
            label: '옷장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: '피드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: '유저',
          ),
        ],
      ),

      child: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        children: [
          HomeScreen(onGoToFittingRoom: () => controller.animateTo(1)),
          FittingRoomScreen(),
          WardrobeScreen(),
          FashionFeedScreen(),
          UserProfileScreen(),
        ],
      ),
    );
  }
}
