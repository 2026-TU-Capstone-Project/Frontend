import 'package:flutter/material.dart';
import '../component/fitting_onboarding_sheet.dart';
import '../theme/fitting_room_theme.dart';
import '../component/fitting_room_header.dart';
import '../component/fitting_main_stage.dart';
import '../component/ai_stylist_input.dart';
import '../component/wardrobe_section.dart';

class FittingRoomScreen extends StatefulWidget {
  const FittingRoomScreen({super.key});

  @override
  State<FittingRoomScreen> createState() => _FittingRoomScreenState();
}

class _FittingRoomScreenState extends State<FittingRoomScreen> with SingleTickerProviderStateMixin {

  final TextEditingController _promptController = TextEditingController();

  // 애니메이션 컨트롤러
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _quickChips = [
    {'icon': Icons.business, 'label': '오피스룩 추천해줘'},
    {'icon': Icons.flight_takeoff, 'label': '여행 갈 때 뭐 입지?'},
    {'icon': Icons.favorite, 'label': '데이트 룩 추천해줘'},
    {'icon': Icons.coffee, 'label': '편한 캐주얼 룩'},
  ];

  final List<Map<String, dynamic>> _clothingSlots = [
    {'type': '상의', 'icon': Icons.checkroom, 'image': null, 'hint': '블라우스, 셔츠'},
    {'type': '하의', 'icon': Icons.accessibility, 'image': null, 'hint': '슬랙스, 스커트'},
    {'type': '아우터', 'icon': Icons.dry_cleaning, 'image': null, 'hint': '코트, 자켓'},
    {'type': '신발', 'icon': Icons.hiking, 'image': null, 'hint': '구두, 스니커즈'},
    {'type': '가방', 'icon': Icons.shopping_bag, 'image': null, 'hint': '핸드백, 토트백'},
  ];

  @override
  void initState() {
    super.initState();

    // ⚡️ 속도 개선: 1.2초 -> 0.6초 (부드럽지만 빠름)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );

    // ⚡️ 지연 시간 단축: 0.5초 -> 0.1초 (화면 뜨자마자 거의 바로 올라옴)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showOnboardingSheet();
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    // 에러 방지: 컨트롤러가 초기화되었는지 확인 후 해제하면 좋지만,
    // 정상적인 flow라면 initState가 먼저 실행되므로 바로 dispose 해도 됩니다.
    _animationController.dispose();
    super.dispose();
  }

  void _showOnboardingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      transitionAnimationController: _animationController, // 컨트롤러 연결
      builder: (context) {
        return FittingOnboardingSheet(
          onStart: () {
            Navigator.pop(context);
            print("✨ 가상 피팅 시작!");
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FittingRoomTheme.kBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittingRoomHeader(),
              const SizedBox(height: 20),
              const FittingMainStage(imagePath: 'asset/img/fitting1.jpg'),
              const SizedBox(height: 28),
              AiStylistInput(
                controller: _promptController,
                chips: _quickChips,
              ),
              const SizedBox(height: 32),
              WardrobeSection(slots: _clothingSlots),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}