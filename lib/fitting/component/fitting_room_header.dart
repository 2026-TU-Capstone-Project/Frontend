import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';

class FittingRoomHeader extends StatefulWidget {
  const FittingRoomHeader({super.key});

  @override
  State<FittingRoomHeader> createState() => _FittingRoomHeaderState();
}

class _FittingRoomHeaderState extends State<FittingRoomHeader> {
  String? _nickname;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final n = await const FlutterSecureStorage().read(key: 'NICKNAME');
    if (mounted) setState(() => _nickname = n);
  }

  @override
  Widget build(BuildContext context) {
    final title = (_nickname != null && _nickname!.isNotEmpty)
        ? '${_nickname!}의 피팅룸'
        : '나의 피팅룸';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VIRTUAL STUDIO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.PRIMARYCOLOR,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.BLACK,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.BORDER_COLOR),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.straighten_rounded,
                size: 16,
                color: AppColors.MEDIUM_GREY,
              ),
              const SizedBox(width: 6),
              const Text(
                '170cm · M size',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.BODY_COLOR,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}