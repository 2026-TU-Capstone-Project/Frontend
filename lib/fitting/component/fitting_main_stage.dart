import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart'; // 테마 파일 경로는 본인 프로젝트에 맞게 유지

class FittingMainStage extends StatefulWidget {
  final String? imagePath;
  final bool isLoading;

  const FittingMainStage({
    this.imagePath,
    this.isLoading = false,
    super.key,
  });

  @override
  State<FittingMainStage> createState() => _FittingMainStageState();
}

class _FittingMainStageState extends State<FittingMainStage> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // 로딩 멘트를 주기적으로 변경하기 위한 타이머와 변수
  Timer? _textTimer;
  String _loadingText = "체형 분석 중...";
  int _textIndex = 0;

  final List<String> _loadingMessages = [
    "체형 분석 중...",
    "옷의 주름 계산 중...",
    "자연스러운 핏 조정 중...",
    "거의 다 됐어요!",
  ];

  @override
  void initState() {
    super.initState();
    // 1. 스캐닝 애니메이션 컨트롤러 (2초마다 위아래 왕복)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // isLoading 상태에 따라 애니메이션 시작/정지 결정
    if (widget.isLoading) {
      _startLoadingEffects();
    }
  }

  @override
  void didUpdateWidget(covariant FittingMainStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상태가 변할 때 애니메이션 제어
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startLoadingEffects();
      } else {
        _stopLoadingEffects();
      }
    }
  }

  void _startLoadingEffects() {
    _scanController.repeat(reverse: true); // 위아래 왕복
    _textIndex = 0;
    _loadingText = _loadingMessages[0];
    // 1.5초마다 멘트 변경
    _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _textIndex = (_textIndex + 1) % _loadingMessages.length;
        _loadingText = _loadingMessages[_textIndex];
      });
    });
  }

  void _stopLoadingEffects() {
    _scanController.stop();
    _scanController.reset();
    _textTimer?.cancel();
    _textTimer = null;
  }

  @override
  void dispose() {
    _scanController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 메인 컨테이너
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: FittingRoomTheme.kPrimaryColor.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AspectRatio(
              aspectRatio: 3 / 3.8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 기본 이미지
                  _buildImage(),

                  // 2. 그라데이션 오버레이 (하단 그림자)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. [핵심] 로딩 시 스캐닝 효과 오버레이
                  if (widget.isLoading) _buildScanningEffect(),
                ],
              ),
            ),
          ),
        ),

        // 4. 하단 버튼들 (로딩 중엔 숨기거나 비활성화 가능, 여기선 유지)
        if (!widget.isLoading)
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                _buildGlassIconButton(Icons.refresh),
                const SizedBox(width: 12),
                _buildGlassIconButton(Icons.fullscreen),
              ],
            ),
          ),
      ],
    );
  }

  // =========================================
  // ✨ 스캐닝 효과 위젯 (Scanning Effect)
  // =========================================
  Widget _buildScanningEffect() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 3-1. 전체를 살짝 어둡게 (집중 효과)
        Container(color: Colors.black.withOpacity(0.3)),

        // 3-2. 움직이는 스캔 라인 (AnimatedBuilder 사용)
        AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, child) {
            return FractionallySizedBox(
              heightFactor: 0.15, // 스캔 빔의 높이 비율
              widthFactor: 1.0,
              alignment: Alignment(0.0, _scanAnimation.value * 2 - 1), // -1(top) ~ 1(bottom)
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FittingRoomTheme.kPrimaryColor.withOpacity(0.0),
                      FittingRoomTheme.kPrimaryColor.withOpacity(0.5), // 빛나는 부분
                      FittingRoomTheme.kPrimaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // 3-3. 진행 상황 텍스트 (중앙)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 뺑글이도 작게 추가 (보조적인 역할)
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // 바뀌는 텍스트
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingText,
                  key: ValueKey<String>(_loadingText), // Key가 바뀌면 애니메이션 발동
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (widget.imagePath == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, color: Colors.grey),
        ),
      );
    }

    if (widget.imagePath!.startsWith('http')) {
      return Image.network(
        widget.imagePath!,
        fit: BoxFit.cover,
        // 이미지 자체 로딩 시에는 스캐닝 효과가 아니라 기본 인디케이터 사용
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: FittingRoomTheme.kPrimaryColor,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('이미지 로드 실패', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}