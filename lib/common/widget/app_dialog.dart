import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

/// 앱 전체 디자인(AppColors, 라운드)에 맞춘 공통 다이얼로그
class AppDialog {
  AppDialog._();

  /// 확인/취소 스타일 (로그아웃, 삭제 확인 등)
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String content,
    String cancelLabel = '취소',
    String confirmLabel = '확인',
    bool confirmIsDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _StyledAlertDialog(
        title: title,
        content: Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.BODY_COLOR,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: confirmIsDestructive ? AppColors.ERROR_COLOR : AppColors.PRIMARYCOLOR,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 텍스트 입력 다이얼로그 (폴더 이름 등)
  static Future<String?> prompt({
    required BuildContext context,
    required String title,
    String hintText = '',
    String initialValue = '',
    String cancelLabel = '취소',
    String confirmLabel = '저장',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => _StyledAlertDialog(
        title: title,
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.MEDIUM_GREY),
            filled: true,
            fillColor: AppColors.INPUT_BG_COLOR,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.BORDER_COLOR),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.BORDER_COLOR),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.PRIMARYCOLOR, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.PRIMARYCOLOR,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _StyledAlertDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.BLACK,
        ),
      ),
      content: content,
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: actions,
    );
  }
}
