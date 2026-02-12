import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FittingMainStage extends StatefulWidget {
  final String? imagePath;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const FittingMainStage({
    this.imagePath,
    this.isLoading = false,
    this.onRefresh,
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

  void _openFullScreenImage() {
    if (widget.imagePath == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => EnhancedFullScreenImageViewer(imagePath: widget.imagePath!),
      ),
    );
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

                  Hero(
                    tag: widget.imagePath ?? 'fitting_image',
                    child: Material(
                      color: Colors.transparent,
                      child: _buildImage(widget.imagePath),
                    ),
                  ),

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
                _buildGlassIconButton(
                  Icons.refresh,
                  onTap: widget.onRefresh,
                ),
                const SizedBox(width: 12),
                _buildGlassIconButton(
                  Icons.fullscreen,
                  onTap: _openFullScreenImage,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String? path, {BoxFit fit = BoxFit.cover}) {
    if (path == null) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey));
    }

    Widget imageWidget;
    if (path.startsWith('http')) {
      imageWidget = Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(color: Colors.grey[300]));
        },
      );
    } else if (path.startsWith('/') || path.contains('content://')) {
      imageWidget = Image.file(
        File(path),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
    return imageWidget;
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

  Widget _buildGlassIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
      ),
    );
  }
}

class EnhancedFullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const EnhancedFullScreenImageViewer({required this.imagePath, super.key});

  @override
  State<EnhancedFullScreenImageViewer> createState() => _EnhancedFullScreenImageViewerState();
}

class _EnhancedFullScreenImageViewerState extends State<EnhancedFullScreenImageViewer> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          Dismissible(
            key: const Key('fullscreen_image_dismiss'),
            direction: DismissDirection.vertical,
            onDismissed: (_) => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,

                child: Hero(
                  tag: widget.imagePath,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildImage(widget.imagePath),
                  ),
                ),
              ),
            ),
          ),


          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCloseButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildImage(String path) {

    const fit = BoxFit.contain;

    if (path.startsWith('http')) {
      return Image.network(path, fit: fit);
    } else if (path.startsWith('/') || path.contains('content://')) {
      return Image.file(File(path), fit: fit);
    } else {
      return Image.asset(path, fit: fit);
    }
  }
}