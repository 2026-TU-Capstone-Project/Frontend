import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone_fe/common/camera/photo_guide_screen.dart';
import 'package:capstone_fe/common/const/colors.dart'; // AppColors 경로 확인

// 호출 함수 (기존 파라미터 유지)
void showAddClothingBottomSheet(
    BuildContext context,
    String type, {
      required VoidCallback onWardrobeTap,
      required Function(File) onImageSelected,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddClothingSheet(
      type: type,
      onWardrobeTap: onWardrobeTap,
      onImageSelected: onImageSelected,
    ),
  );
}

class AddClothingSheet extends StatelessWidget {
  final String type;
  final VoidCallback onWardrobeTap;
  final Function(File) onImageSelected;

  const AddClothingSheet({
    required this.type,
    required this.onWardrobeTap,
    required this.onImageSelected,
    super.key,
  });

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    if (source == ImageSource.camera) {
      File? file;
      if (type == '상의' || type == '하의') {
        final guideType = type == '상의'
            ? PhotoGuideType.topClothing
            : PhotoGuideType.bottomClothing;
        file = await PhotoGuideScreen.open(context, type: guideType);
      } else {
        final picker = ImagePicker();
        final XFile? img = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (img != null) file = File(img.path);
      }
      if (file != null && context.mounted) {
        Navigator.pop(context);
        onImageSelected(file);
      }
      return;
    }

    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && context.mounted) {
        Navigator.pop(context);
        onImageSelected(File(image.path));
      }
    } catch (e) {
      debugPrint("이미지 선택 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 핸들바 (중앙 정렬)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.BORDER_COLOR,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 타이틀 영역
              Text(
                '$type 추가하기',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이미지를 불러올 방법을 선택해주세요.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.BODY_COLOR,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),

              // 옵션 리스트
              _buildMinimalOption(
                context,
                icon: Icons.camera_alt_outlined, // 라인 아이콘 사용
                title: '사진 촬영',
                onTap: () => _pickImage(ImageSource.camera, context),
              ),
              const SizedBox(height: 12),

              _buildMinimalOption(
                context,
                icon: Icons.checkroom_outlined,
                title: '나만의 옷장',
                onTap: () {
                  Navigator.pop(context);
                  onWardrobeTap();
                },
              ),
              const SizedBox(height: 12),

              _buildMinimalOption(
                context,
                icon: Icons.photo_library_outlined,
                title: '갤러리 선택',
                onTap: () => _pickImage(ImageSource.gallery, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 미니멀 스타일 옵션 버튼
  Widget _buildMinimalOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.BORDER_COLOR), // 연한 회색 테두리
            borderRadius: BorderRadius.circular(16),
            color: AppColors.INPUT_BG_COLOR, // 아주 연한 회색 배경
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.PRIMARYCOLOR, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.BLACK,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.MEDIUM_GREY,
              ),
            ],
          ),
        ),
      ),
    );
  }
}