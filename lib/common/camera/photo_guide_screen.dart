import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone_fe/common/const/colors.dart';

enum PhotoGuideType { topClothing, bottomClothing, fullBody, profile }

/// 카메라 촬영 가이드 화면.
/// 시나리오별 SVG 일러스트와 촬영 팁을 보여준 뒤,
/// "촬영하기" 버튼으로 기본 카메라(ImagePicker)를 실행하고 File?을 반환.
class PhotoGuideScreen extends StatefulWidget {
  final PhotoGuideType type;

  const PhotoGuideScreen({required this.type, super.key});

  static Future<File?> open(BuildContext context, {required PhotoGuideType type}) {
    return Navigator.push<File>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoGuideScreen(type: type),
      ),
    );
  }

  @override
  State<PhotoGuideScreen> createState() => _PhotoGuideScreenState();
}

class _PhotoGuideScreenState extends State<PhotoGuideScreen> {
  bool _isCapturing = false;

  // ── 가이드 컨텐츠 ────────────────────────────────────────────────────────────

  String get _title {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return '상의 촬영 가이드';
      case PhotoGuideType.bottomClothing:
        return '하의 촬영 가이드';
      case PhotoGuideType.fullBody:
        return '전신 사진 촬영 가이드';
      case PhotoGuideType.profile:
        return '프로필 사진 촬영 가이드';
    }
  }

  String get _typeLabel {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return '상의';
      case PhotoGuideType.bottomClothing:
        return '하의';
      case PhotoGuideType.fullBody:
        return '전신';
      case PhotoGuideType.profile:
        return '프로필';
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return Icons.checkroom_outlined;
      case PhotoGuideType.bottomClothing:
        return Icons.straighten_outlined;
      case PhotoGuideType.fullBody:
        return Icons.accessibility_new_outlined;
      case PhotoGuideType.profile:
        return Icons.person_outline_rounded;
    }
  }

  String get _svgAsset {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return 'asset/img/clothes.svg';
      case PhotoGuideType.bottomClothing:
        return 'asset/img/clothes2.svg';
      case PhotoGuideType.fullBody:
      case PhotoGuideType.profile:
        return 'asset/img/human.svg';
    }
  }

  EdgeInsetsGeometry get _svgPadding {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return const EdgeInsets.symmetric(horizontal: 64, vertical: 28);
      case PhotoGuideType.bottomClothing:
        return const EdgeInsets.symmetric(horizontal: 72, vertical: 22);
      case PhotoGuideType.fullBody:
        return const EdgeInsets.symmetric(horizontal: 88, vertical: 16);
      case PhotoGuideType.profile:
        return const EdgeInsets.symmetric(horizontal: 88, vertical: 20);
    }
  }

  List<String> get _tips {
    switch (widget.type) {
      case PhotoGuideType.topClothing:
        return [
          '옷을 평평하게 펴서 촬영하세요',
          '밝은 단색 배경에서 촬영하면 더 정확해요',
          '옷 전체가 프레임 안에 들어오도록 해주세요',
        ];
      case PhotoGuideType.bottomClothing:
        return [
          '옷을 평평하게 펴서 촬영하세요',
          '밝은 단색 배경에서 촬영하면 더 정확해요',
          '옷 전체가 프레임 안에 들어오도록 해주세요',
        ];
      case PhotoGuideType.fullBody:
        return [
          '정면을 바라보고 전신이 나오게 촬영하세요',
          '팔과 다리가 겹치지 않게 자연스럽게 서주세요',
          '머리부터 발끝까지 모두 들어오게 해주세요',
        ];
      case PhotoGuideType.profile:
        return [
          '얼굴이 중앙에 오도록 촬영하세요',
          '어깨까지 나오면 좋아요',
          '밝은 환경에서 촬영하면 더 좋아요',
        ];
    }
  }

  // ── 액션 ─────────────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      debugPrint('촬영 실패: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── 빌드 ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIllustration(),
                    const SizedBox(height: 28),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.BLACK,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '정확한 AI 인식을 위해 아래 방법으로 촬영해 주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.MEDIUM_GREY,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._tips.map(_buildTip),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: _buildCaptureButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.BLACK,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF2FF), Color(0xFFE2ECFF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 배경 도트 그리드
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            // SVG 일러스트
            Positioned.fill(
              child: Padding(
                padding: _svgPadding,
                child: SvgPicture.asset(
                  _svgAsset,
                  colorFilter: ColorFilter.mode(
                    AppColors.ACCENT_BLUE.withValues(alpha: 0.72),
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // 카메라 프레임 코너
            Positioned.fill(
              child: CustomPaint(painter: _CameraFramePainter()),
            ),
            // 타입 배지
            Positioned(
              top: 14,
              left: 14,
              child: _buildTypeBadge(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon, size: 13, color: AppColors.ACCENT_BLUE),
          const SizedBox(width: 5),
          Text(
            _typeLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.PRIMARYCOLOR,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.PRIMARYCOLOR.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: AppColors.PRIMARYCOLOR,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.BODY_COLOR,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _capture,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _isCapturing
              ? AppColors.PRIMARYCOLOR.withValues(alpha: 0.6)
              : AppColors.PRIMARYCOLOR,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: _isCapturing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '촬영하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── 배경 유틸리티 Painters ──────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B7FFF).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.4;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B7FFF).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const margin = 18.0;
    const length = 22.0;

    // 좌상단
    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + length)
        ..lineTo(margin, margin)
        ..lineTo(margin + length, margin),
      paint,
    );
    // 우상단
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - length, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + length),
      paint,
    );
    // 좌하단
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - length)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + length, size.height - margin),
      paint,
    );
    // 우하단
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - length, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
