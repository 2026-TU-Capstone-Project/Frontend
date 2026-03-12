import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

/// 피팅룸 상단 헤더. 왼쪽에 [leading](토글 등), 오른쪽에 키·사이즈 스펙
class FittingRoomHeader extends StatelessWidget {
  /// 왼쪽 영역 (토글 등). null이면 비움
  final Widget? leading;
  final String? heightLabel;
  final String? sizeLabel;

  const FittingRoomHeader({
    super.key,
    this.leading,
    this.heightLabel,
    this.sizeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final heightStr = heightLabel?.trim();
    final sizeStr = sizeLabel?.trim();
    final hasHeight = heightStr != null && heightStr.isNotEmpty;
    final hasSize = sizeStr != null && sizeStr.isNotEmpty;
    String specText = '미입력';
    if (hasHeight && hasSize) {
      specText = '${heightStr}cm · $sizeStr size';
    } else if (hasHeight) {
      specText = '${heightStr}cm';
    } else if (hasSize) {
      specText = '$sizeStr size';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) Expanded(child: leading!),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.BORDER_COLOR),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.straighten_rounded,
                size: 16,
                color: AppColors.MEDIUM_GREY,
              ),
              const SizedBox(width: 6),
              Text(
                specText,
                style: const TextStyle(
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