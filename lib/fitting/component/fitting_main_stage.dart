import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/component/fitting_loading_effect.dart';

class FittingMainStage extends StatefulWidget {
  final String? mainImagePath;
  final bool isLoading;
  final bool isResult;
  final VoidCallback onUserImageTap;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;
  final File? topImageFile;
  final String? topImageUrl;
  final File? bottomImageFile;
  final String? bottomImageUrl;
  final VoidCallback? onUserImageRemove;
  final VoidCallback? onTopRemove;
  final VoidCallback? onBottomRemove;

  const FittingMainStage({
    super.key,
    this.mainImagePath,
    this.isLoading = false,
    this.isResult = false,
    required this.onUserImageTap,
    required this.onTopTap,
    required this.onBottomTap,
    this.topImageFile,
    this.topImageUrl,
    this.bottomImageFile,
    this.bottomImageUrl,
    this.onUserImageRemove,
    this.onTopRemove,
    this.onBottomRemove,
  });

  @override
  State<FittingMainStage> createState() => _FittingMainStageState();
}

class _FittingMainStageState extends State<FittingMainStage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          height: 520,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(widget.mainImagePath),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.transparent),
                ),
                const FittingLoadingEffect(),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isResult) {
      return GestureDetector(
        onTap: widget.onUserImageTap,
        child: Container(
          height: 520,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(widget.mainImagePath),
                // 우상단 "확대" 힌트 아이콘
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 일반 모드: 전신·상의·하의 3개 선택 카드를 크게 표시
    return SizedBox(
      height: 520,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------
          // 1. 좌측: 전신 사진 (피팅룸)
          // -------------------------------------------------------
          Expanded(
            flex: 55, // 비율 조절 (약간 더 넓게)
            child: GestureDetector(
              onTap: widget.onUserImageTap,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.BORDER_COLOR,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(widget.mainImagePath),

                      if (widget.mainImagePath == null)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'asset/img/human.svg',
                                width: 50,
                                height: 50,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.MEDIUM_GREY,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "전신 사진 추가",
                                style: TextStyle(
                                  color: AppColors.MEDIUM_GREY,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (widget.mainImagePath != null &&
                          widget.onUserImageRemove != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _RemoveButton(
                            onTap: widget.onUserImageRemove!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14), // 간격도 살짝 줄임
          // -------------------------------------------------------
          // 2. 우측: 옷 선택 슬롯
          // -------------------------------------------------------
          Expanded(
            flex: 45, // 비율 조절
            child: Column(
              children: [
                Expanded(
                  child: _ClothingSlot(
                    label: "상의 (필수)",
                    imageFile: widget.topImageFile,
                    imageUrl: widget.topImageUrl,
                    placeholderIcon: SvgPicture.asset(
                      'asset/img/clothes.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        AppColors.MEDIUM_GREY,
                        BlendMode.srcIn,
                      ),
                    ),
                    isActive:
                        widget.topImageFile != null ||
                        widget.topImageUrl != null,
                    onTap: widget.onTopTap,
                    onRemove: widget.onTopRemove,
                  ),
                ),
                const SizedBox(height: 14), // 간격 축소
                Expanded(
                  child: _ClothingSlot(
                    label: "하의 (선택)",
                    imageFile: widget.bottomImageFile,
                    imageUrl: widget.bottomImageUrl,
                    placeholderIcon: SvgPicture.asset(
                      'asset/img/clothes2.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        AppColors.MEDIUM_GREY,
                        BlendMode.srcIn,
                      ),
                    ),
                    isActive:
                        widget.bottomImageFile != null ||
                        widget.bottomImageUrl != null,
                    onTap: widget.onBottomTap,
                    onRemove: widget.onBottomRemove,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? path) {
    if (path == null) {
      return Container(color: AppColors.INPUT_BG_COLOR);
    }

    // 1. 서버에서 받아온 결과 이미지 (네트워크 URL)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        // 💡 [추가] 다운로드 중일 때 로딩 스피너 표시
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: LoadingIndicator(),
          );
        },
        // 🚨 [추가] URL이 가짜이거나 깨져있을 때 (에러 발생 시) 엑스박스 표시
        errorBuilder: (context, error, stackTrace) {
          debugPrint('🚨 피팅 결과 이미지 로드 실패: $error');
          debugPrint('🚨 실패한 URL: $path');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: AppColors.MEDIUM_GREY,
                ),
                SizedBox(height: 8),
                Text(
                  "이미지 링크가 끊어졌습니다",
                  style: TextStyle(
                    color: AppColors.MEDIUM_GREY,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    // 2. 핸드폰 갤러리에서 고른 로컬 파일
    else if (path.startsWith('/') || path.contains('content://')) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    // 3. 앱 내장 에셋 이미지
    else {
      return Image.asset(path, fit: BoxFit.cover);
    }
  }
}

class _ClothingSlot extends StatelessWidget {
  final String label;
  final File? imageFile;
  final String? imageUrl;
  final Widget placeholderIcon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ClothingSlot({
    required this.label,
    this.imageFile,
    this.imageUrl,
    required this.placeholderIcon,
    required this.isActive,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16), // 둥글기 살짝 줄임 (컴팩트함)
          border: Border.all(
            color: AppColors.BORDER_COLOR,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageFile != null)
                Image.file(imageFile!, fit: BoxFit.cover)
              else if (imageUrl != null)
                Image.network(imageUrl!, fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    placeholderIcon,
                    const SizedBox(height: 6),
                    Text(
                      "선택하기",
                      style: TextStyle(
                        color: AppColors.MEDIUM_GREY,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              // 라벨
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.BLACK.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (isActive && onRemove != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _RemoveButton(onTap: onRemove!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.BLACK.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
