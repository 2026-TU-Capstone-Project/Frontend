import 'dart:async';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

/// 피팅 진행 중 이미지 위에 겹쳐지는 로딩 효과.
/// - 전체 어두운 오버레이 + 이중 쉬머 띠
/// - 중앙 카드: 단계 텍스트 + 진행률 바
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

  // 진행률 바
  double _progressValue = 0.0;
  Timer? _progressTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // 단계별 상태
  static const List<_LoadingStep> _steps = [
    _LoadingStep(
      duration: Duration(seconds: 4),
      text: '옷을 분석하고 있어요...',
      icon: Icons.search_rounded,
    ),
    _LoadingStep(
      duration: Duration(seconds: 5),
      text: 'AI가 스타일을 매칭하고 있어요...',
      icon: Icons.auto_awesome_rounded,
    ),
    _LoadingStep(
      duration: Duration(seconds: 6),
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

  @override
  void initState() {
    super.initState();

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

    // 진행률 바: 20초 기준, 0.93에서 멈춤
    _stopwatch.start();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      final elapsed = _stopwatch.elapsed.inMilliseconds;
      setState(() => _progressValue = (elapsed / 20000).clamp(0.0, 0.93));
    });

    _scheduleNextStep();
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
        // 어두운 오버레이
        Container(color: AppColors.BLACK.withValues(alpha: 0.30)),

        // 쉬머 띠
        AnimatedBuilder(
          animation: _shimmerDown,
          builder: (_, __) => _ShimmerBar(alignmentY: _shimmerDown.value),
        ),
        AnimatedBuilder(
          animation: _shimmerUp,
          builder: (_, __) => _ShimmerBar(alignmentY: _shimmerUp.value),
        ),

        // 중앙 카드
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: AppColors.BLACK.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.ACCENT_BLUE.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.ACCENT_BLUE.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: Icon(
                      _currentStep.icon,
                      key: ValueKey<int>(_stepIndex),
                      color: AppColors.ACCENT_BLUE,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 단계 텍스트
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _currentStep.text,
                    key: ValueKey<int>(_stepIndex),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 진행률 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.ACCENT_BLUE,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '보통 10~20초 소요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
                AppColors.PRIMARYCOLOR.withValues(alpha: 0.0),
                AppColors.PRIMARYCOLOR.withValues(alpha: 0.35),
                AppColors.ACCENT_COLOR.withValues(alpha: 0.2),
                AppColors.PRIMARYCOLOR.withValues(alpha: 0.35),
                AppColors.PRIMARYCOLOR.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
