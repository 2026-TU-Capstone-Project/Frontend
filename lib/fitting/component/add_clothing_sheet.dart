import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ✅ image_picker import
import '../theme/fitting_room_theme.dart';

// 👇 [수정] onImageSelected 콜백 추가 (선택된 파일 반환용)
void showAddClothingBottomSheet(
    BuildContext context,
    String type, {
      required VoidCallback onWardrobeTap,
      required Function(File) onImageSelected, // ✅ 추가됨
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddClothingSheet(
      type: type,
      onWardrobeTap: onWardrobeTap,
      onImageSelected: onImageSelected, // ✅ 전달
    ),
  );
}

class AddClothingSheet extends StatelessWidget {
  final String type;
  final VoidCallback onWardrobeTap;
  final Function(File) onImageSelected; // ✅ 콜백 저장

  const AddClothingSheet({
    required this.type,
    required this.onWardrobeTap,
    required this.onImageSelected,
    super.key,
  });

  // 👇 [New] 이미지 선택 로직 (카메라/갤러리 공통)
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // 용량 최적화
      );

      if (image != null) {
        if (context.mounted) {
          Navigator.pop(context); // 바텀 시트 닫기
          onImageSelected(File(image.path)); // ✅ 파일 전달
        }
      }
    } catch (e) {
      debugPrint("이미지 선택 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$type 추가하기',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FittingRoomTheme.kTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '어떤 방법으로 옷을 가져올까요?',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),

              // 📸 카메라 촬영 연결
              _buildOption(
                context,
                Icons.camera_alt_rounded,
                '사진 촬영',
                '카메라로 직접 찍어서 올리기',
                onTap: () => _pickImage(context, ImageSource.camera), // ✅ 연결
              ),

              // 🧥 나만의 옷장 (기존 유지)
              _buildOption(
                context,
                Icons.checkroom_rounded,
                '나만의 옷장',
                '등록해둔 옷 중에서 선택하기',
                onTap: () {
                  Navigator.pop(context);
                  onWardrobeTap();
                },
              ),

              // 🖼️ 갤러리 선택 연결
              _buildOption(
                context,
                Icons.photo_library_rounded,
                '갤러리 선택',
                '앨범에서 사진 가져오기',
                isLast: true,
                onTap: () => _pickImage(context, ImageSource.gallery), // ✅ 연결
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle, {
        bool isLast = false,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FittingRoomTheme.kSecondarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: FittingRoomTheme.kPrimaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FittingRoomTheme.kTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}