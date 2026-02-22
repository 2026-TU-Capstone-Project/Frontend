import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

/// 피팅 진행 중 이미지 위에 겹쳐지는 로딩 효과.
/// - 이중 쉬머 띠가 위·아래로 교차 이동
/// - 중앙에 "스타일 분석 중..." 텍스트 + 인디케이터
class FittingLoadingEffect extends StatefulWidget {
  const FittingLoadingEffect({super.key});

  @override
  State<FittingLoadingEffect> createState() => _FittingLoadingEffectState();
}

class _FittingLoadingEffectState extends State<FittingLoadingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerDown;
  late Animation<double> _shimmerUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shimmerDown = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shimmerUp = Tween<double>(begin: 1.15, end: -0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 어두운 반투명 오버레이 (이미지 위에)
        Container(
          color: AppColors.BLACK.withOpacity(0.25),
        ),
        // 위→아래 쉬머 띠
        AnimatedBuilder(
          animation: _shimmerDown,
          builder: (context, _) => _ShimmerBar(alignmentY: _shimmerDown.value),
        ),
        // 아래→위 쉬머 띠 (역방향)
        AnimatedBuilder(
          animation: _shimmerUp,
          builder: (context, _) => _ShimmerBar(alignmentY: _shimmerUp.value),
        ),
        // 중앙 라벨 + 인디케이터
        Center(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.BLACK.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.PRIMARYCOLOR.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                        backgroundColor: AppColors.BLACK,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '스타일 분석 중...',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 단일 쉬머 띠 (세로 그라데이션, 위치만 animation 값으로 제어)
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.alignmentY});

  final double alignmentY;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(0.0, alignmentY),
      child: FractionallySizedBox(
        heightFactor: 0.18,
        widthFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.PRIMARYCOLOR.withOpacity(0.0),
                AppColors.PRIMARYCOLOR.withOpacity(0.35),
                AppColors.ACCENT_COLOR.withOpacity(0.2),
                AppColors.PRIMARYCOLOR.withOpacity(0.35),
                AppColors.PRIMARYCOLOR.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
