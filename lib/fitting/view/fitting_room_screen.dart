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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showOnboardingSheet();
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();


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
      transitionAnimationController: _animationController,
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