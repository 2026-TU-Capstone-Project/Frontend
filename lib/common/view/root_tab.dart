import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/layout/default_layout.dart';
import 'package:capstone_fe/feed/view/fashion_feed_screen.dart';
import 'package:capstone_fe/fitting/view/fitting_room_screen.dart';
import 'package:capstone_fe/home/view/home_screen.dart';
import 'package:capstone_fe/personal_closet/view/wardrobe_screen.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/view/user_profile_screen.dart';
import 'package:capstone_fe/user/view/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RootTab extends StatefulWidget {
  const RootTab({super.key});

  @override
  State<RootTab> createState() => _RootTabState();
}

class _RootTabState extends State<RootTab> with SingleTickerProviderStateMixin{
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

  void tabListener(){
    setState(() {
      index = controller.index;
    });
  }

  /// Swagger: POST /api/v1/auth/logout (RefreshTokenRequestDto) 후 로컬 토큰 삭제 → 로그인 화면
  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final storage = const FlutterSecureStorage();
    final refreshToken = await storage.read(key: 'REFRESH_TOKEN');

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final authRepository = AuthRepository(Dio(), baseUrl: baseUrl);
        await authRepository.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // 서버 실패해도 로컬 토큰은 삭제하고 로그인으로 보냄
    } finally {
      await storage.deleteAll();
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      title: SvgPicture.asset('asset/img/try-on.svg'),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_outlined)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.shopping_bag_outlined)),
          IconButton(
            onPressed: _onLogout,
            icon: const Icon(Icons.logout_outlined),
            tooltip: '로그아웃',
          ),
        ],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.PRIMARYCOLOR,
            unselectedItemColor: AppColors.BODY_COLOR,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            onTap: (int index){
            controller.animateTo(index);
            },
            currentIndex: index,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: '홈'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.checkroom_outlined),
                  label: '피팅룸'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.door_sliding_outlined),
                  label: '옷장'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  label: '피드'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  label: '유저'
              ),
            ]
        ),

        child: TabBarView(
          physics: NeverScrollableScrollPhysics(),
            controller: controller,
            children: [
              HomeScreen(),
              FittingRoomScreen(),
              WardrobeScreen(),
              FashionFeedScreen(),
              UserProfileScreen(),
        ]
        )
    );
  }
}
