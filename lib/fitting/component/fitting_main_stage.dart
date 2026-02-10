import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';


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

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _startLoadingEffects();
    }
  }

  @override
  void didUpdateWidget(covariant FittingMainStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startLoadingEffects();
      } else {
        _stopLoadingEffects();
      }
    }
  }

  void _startLoadingEffects() {
    _scanController.repeat(reverse: true);
    _textIndex = 0;
    _loadingText = _loadingMessages[0];


    _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingMessages.length;
          _loadingText = _loadingMessages[_textIndex];
        });
      }
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

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  _buildImage(),

                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, Colors.black38],
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  if (widget.isLoading) _buildScanningEffect(),
                ],
              ),
            ),
          ),
        ),


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


  Widget _buildScanningEffect() {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [

          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                heightFactor: 0.15,
                widthFactor: 1.0,
                alignment: Alignment(0.0, _scanAnimation.value * 2 - 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF7E57C2).withOpacity(0.0),
                        const Color(0xFF7E57C2).withOpacity(0.6),
                        const Color(0xFF7E57C2).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingText,
                    key: ValueKey<String>(_loadingText),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 2))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final path = widget.imagePath;
    if (path == null) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey));
    }


    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    else if (path.startsWith('/') || path.contains('content://')) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    else {
      return Image.asset(
        path,
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
          const Text('이미지 로드 실패', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }


  Widget _buildGlassIconButton(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}