import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/component/fitting_loading_effect.dart';

class FittingMainStage extends StatefulWidget {
  final String? mainImagePath;
  final bool isLoading;
  final VoidCallback onUserImageTap;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;
  final File? topImageFile;
  final String? topImageUrl;
  final File? bottomImageFile;
  final String? bottomImageUrl;

  const FittingMainStage({
    super.key,
    this.mainImagePath,
    this.isLoading = false,
    required this.onUserImageTap,
    required this.onTopTap,
    required this.onBottomTap,
    this.topImageFile,
    this.topImageUrl,
    this.bottomImageFile,
    this.bottomImageUrl,
  });

  @override
  State<FittingMainStage> createState() => _FittingMainStageState();
}

class _FittingMainStageState extends State<FittingMainStage> {
  @override
  Widget build(BuildContext context) {
    // ✅ 높이를 420으로 줄임 (적절한 크기)
    return SizedBox(
      height: 420,
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
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

                      if (widget.isLoading) const FittingLoadingEffect(),

                      if (widget.mainImagePath == null)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 아이콘 크기 축소 40 -> 32
                              Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.MEDIUM_GREY),
                              SizedBox(height: 8),
                              Text("전신 사진 추가", style: TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 13)),
                            ],
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
                    placeholderIcon: Icons.checkroom_outlined,
                    isActive: widget.topImageFile != null || widget.topImageUrl != null,
                    onTap: widget.onTopTap,
                  ),
                ),
                const SizedBox(height: 14), // 간격 축소
                Expanded(
                  child: _ClothingSlot(
                    label: "하의 (선택)",
                    imageFile: widget.bottomImageFile,
                    imageUrl: widget.bottomImageUrl,
                    placeholderIcon: Icons.accessibility_new_outlined,
                    isActive: widget.bottomImageFile != null || widget.bottomImageUrl != null,
                    onTap: widget.onBottomTap,
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
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    } else if (path.startsWith('/') || path.contains('content://')) {
      return Image.file(File(path), fit: BoxFit.cover);
    } else {
      return Image.asset(path, fit: BoxFit.cover);
    }
  }

}

class _ClothingSlot extends StatelessWidget {
  final String label;
  final File? imageFile;
  final String? imageUrl;
  final IconData placeholderIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _ClothingSlot({
    required this.label,
    this.imageFile,
    this.imageUrl,
    required this.placeholderIcon,
    required this.isActive,
    required this.onTap,
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
            color: isActive ? AppColors.PRIMARYCOLOR : AppColors.BORDER_COLOR,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                    // 아이콘 크기 축소 40 -> 32
                    Icon(placeholderIcon, color: AppColors.BORDER_COLOR, size: 32),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.BLACK.withOpacity(0.7),
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
            ],
          ),
        ),
      ),
    );
  }
}