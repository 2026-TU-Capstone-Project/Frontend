import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart';

void showAddClothingBottomSheet(BuildContext context, String type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddClothingSheet(type: type),
  );
}

class AddClothingSheet extends StatelessWidget {
  final String type;

  const AddClothingSheet({required this.type, super.key});

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
              _buildOption(context, Icons.camera_alt_rounded, '사진 촬영', '카메라로 직접 찍어서 올리기'),
              _buildOption(context, Icons.checkroom_rounded, '나만의 옷장', '등록해둔 옷 중에서 선택하기'),
              _buildOption(context, Icons.photo_library_rounded, '갤러리 선택', '앨범에서 사진 가져오기', isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, String subtitle, {bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          // TODO: 각 기능 연결
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
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