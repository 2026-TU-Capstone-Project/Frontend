import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

/// 피팅 진행 중 이미지 위에 겹쳐지는 로딩 효과.
/// - 이중 쉬머 띠가 위·아래로 교차 이동
/// - 단계별 상태 텍스트가 시간에 따라 자동 전환 (AnimatedSwitcher)
/// - 하단에 LinearProgressIndicator + 예상 소요 시간 안내
class FittingLoadingEffect extends StatefulWidget {
  const FittingLoadingEffect({super.key});

  @override
  State<FittingLoadingEffect> createState() => _FittingLoadingEffectState();
}

class _FittingLoadingEffectState extends State<FittingLoadingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerDown;
  late Animation<double> _shimmerUp;

  // 단계별 상태 텍스트
  static const List<_LoadingStep> _steps = [
    _LoadingStep(
      duration: Duration(seconds: 3),
      text: '옷을 분석하고 있어요...',
      icon: Icons.search_rounded,
    ),
    _LoadingStep(
      duration: Duration(seconds: 5),
      text: 'AI가 스타일을 매칭하고 있어요...',
      icon: Icons.auto_awesome_rounded,
    ),
    _LoadingStep(
      duration: Duration(seconds: 7),
      text: '거의 완성됐어요! 조금만 기다려주세요...',
      icon: Icons.palette_rounded,
    ),
  ];
  static const _LoadingStep _lastStep = _LoadingStep(
    duration: Duration(days: 1),
    text: '조금 더 걸리고 있어요... 잠시만요',
    icon: Icons.hourglass_top_rounded,
  );

  int _stepIndex = 0;
  Timer? _stepTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // 진행률 애니메이션 (indeterminate → determinate)
  double _progressValue = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // 쉬머 애니메이션
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shimmerDown = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerUp = Tween<double>(begin: 1.15, end: -0.15).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();

    // 단계 진행
    _stopwatch.start();
    _scheduleNextStep();

    // 진행률 바: 20초 기준으로 서서히 올라가되, 0.93에서 멈춤 (완료 전까지)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      final elapsed = _stopwatch.elapsed.inMilliseconds;
      final target = (elapsed / 20000).clamp(0.0, 0.93);
      setState(() => _progressValue = target);
    });
  }

  void _scheduleNextStep() {
    if (_stepIndex >= _steps.length) return;
    _stepTimer = Timer(_steps[_stepIndex].duration, () {
      if (!mounted) return;
      setState(() => _stepIndex++);
      _scheduleNextStep();
    });
  }

  _LoadingStep get _currentStep =>
      _stepIndex < _steps.length ? _steps[_stepIndex] : _lastStep;

  @override
  void dispose() {
    _shimmerController.dispose();
    _stepTimer?.cancel();
    _progressTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 어두운 반투명 오버레이
        Container(color: AppColors.BLACK.withOpacity(0.30)),

        // 위→아래 쉬머 띠
        AnimatedBuilder(
          animation: _shimmerDown,
          builder: (context, _) => _ShimmerBar(alignmentY: _shimmerDown.value),
        ),
        // 아래→위 쉬머 띠
        AnimatedBuilder(
          animation: _shimmerUp,
          builder: (context, _) => _ShimmerBar(alignmentY: _shimmerUp.value),
        ),

        // 중앙 상태 카드
        Center(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.BLACK.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.ACCENT_BLUE.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘 + 텍스트 (AnimatedSwitcher로 fade 전환)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Column(
                        key: ValueKey<int>(_stepIndex),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 아이콘
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.ACCENT_BLUE.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentStep.icon,
                              color: AppColors.ACCENT_BLUE,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 상태 텍스트
                          Text(
                            _currentStep.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 진행률 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.ACCENT_BLUE,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 예상 소요 시간 안내
                    Text(
                      '보통 10~20초 소요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
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

/// 단계 정보 데이터 클래스
class _LoadingStep {
  final Duration duration;
  final String text;
  final IconData icon;

  const _LoadingStep({
    required this.duration,
    required this.text,
    required this.icon,
  });
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
