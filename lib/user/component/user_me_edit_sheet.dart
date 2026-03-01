import 'dart:io';

import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 마이페이지 수정 시트 (PATCH /api/v1/users/me)
/// 닉네임, 키, 몸무게, 프로필 이미지. 보낸 필드만 서버에 반영. 로그아웃 버튼 포함.
class UserMeEditSheet extends StatefulWidget {
  final UserMe? initial;
  final VoidCallback? onSaved;
  final VoidCallback? onLogout;

  const UserMeEditSheet({this.initial, this.onSaved, this.onLogout, super.key});

  @override
  State<UserMeEditSheet> createState() => _UserMeEditSheetState();
}

/// 키 목록: 100.0 ~ 250.0 cm, 0.1 단위
List<double> get _heightOptions => List.generate(1501, (i) => 100.0 + i * 0.1);

/// 몸무게 목록: 30.0 ~ 200.0 kg, 0.1 단위
List<double> get _weightOptions => List.generate(1701, (i) => 30.0 + i * 0.1);

class _UserMeEditSheetState extends State<UserMeEditSheet> {
  final _nicknameController = TextEditingController();

  double? _height;
  double? _weight;

  /// MALE | FEMALE (API 명세)
  String? _gender;

  File? _pickedImage;
  bool _saving = false;

  static const double _defaultHeight = 160.0;
  static const double _defaultWeight = 60.0;

  @override
  void initState() {
    super.initState();
    final u = widget.initial;
    if (u != null) {
      _nicknameController.text = u.nickname ?? '';
      _height = u.height ?? _defaultHeight;
      _weight = u.weight ?? _defaultWeight;
      final g = u.gender?.toUpperCase();
      _gender = (g == 'MALE' || g == 'FEMALE') ? g : null;
    } else {
      _height = _defaultHeight;
      _weight = _defaultWeight;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _showHeightPicker() {
    final options = _heightOptions;
    final initialIndex = _height != null
        ? ((_height! - 100) / 0.1).round().clamp(0, options.length - 1)
        : 0;
    int selectedIndex = initialIndex;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: AppColors.ACCENT_COLOR,
          scaffoldBackgroundColor: AppColors.white,
        ),
        child: Container(
          height: 280,
          color: AppColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: AppColors.MEDIUM_GREY,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _height = options[selectedIndex]);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: AppColors.ACCENT_COLOR,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: options
                      .map(
                        (v) => Center(
                          child: Text(
                            '${v.toStringAsFixed(1)} cm',
                            style: const TextStyle(
                              color: AppColors.BLACK,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightPicker() {
    final options = _weightOptions;
    final initialIndex = _weight != null
        ? ((_weight! - 30) / 0.1).round().clamp(0, options.length - 1)
        : 0;
    int selectedIndex = initialIndex;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: AppColors.ACCENT_COLOR,
          scaffoldBackgroundColor: AppColors.white,
        ),
        child: Container(
          height: 280,
          color: AppColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: AppColors.MEDIUM_GREY,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _weight = options[selectedIndex]);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: AppColors.ACCENT_COLOR,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: options
                      .map(
                        (v) => Center(
                          child: Text(
                            '${v.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: AppColors.BLACK,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.BORDER_COLOR,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '사진 선택',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                ),
              ),
              const SizedBox(height: 16),
              _photoSourceTile(
                context: ctx,
                icon: Icons.camera_alt_outlined,
                label: '사진 촬영하기',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.BORDER_COLOR),
              ),
              _photoSourceTile(
                context: ctx,
                icon: Icons.photo_library_outlined,
                label: '갤러리에서 선택',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source);
    if (x != null && mounted) {
      setState(() => _pickedImage = File(x.path));
    }
  }

  Widget _photoSourceTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.ACCENT_COLOR.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: AppColors.ACCENT_COLOR),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final authDio = createAuthDio();
      final repo = AuthRepository(Dio(), baseUrl: baseUrl);

      String? nickname;
      if (_nicknameController.text.trim().isNotEmpty) {
        nickname = _nicknameController.text.trim();
      }

      final height = _height;
      final weight = _weight;
      final gender = _gender;

      final updated = await repo.patchMe(
        authDio,
        nickname: nickname,
        height: height,
        weight: weight,
        gender: gender,
        profileImage: _pickedImage,
      );

      if (!mounted) return;
      // 이번에 수정한 닉네임 우선 저장 (서버 응답이 예전 값일 수 있음)
      final newNickname = (nickname != null && nickname.isNotEmpty)
          ? nickname
          : updated?.nickname?.trim();
      if (newNickname != null && newNickname.isNotEmpty) {
        await const FlutterSecureStorage().write(
          key: 'NICKNAME',
          value: newNickname,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onLogoutTap() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '로그아웃',
      content: '로그아웃 하시겠습니까?',
      confirmLabel: '로그아웃',
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.initial;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.BORDER_COLOR,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '마이페이지 수정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.BLACK,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 프로필 이미지
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.INPUT_BG_COLOR,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (u?.profileImageUrl != null &&
                                  u!.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(u.profileImageUrl!)
                            : null,
                        child:
                            _pickedImage == null &&
                                (u?.profileImageUrl == null ||
                                    u!.profileImageUrl!.isEmpty)
                            ? Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: AppColors.MEDIUM_GREY,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _pickImage,
                      child: const Text(
                        '사진 변경',
                        style: TextStyle(color: AppColors.ACCENT_COLOR),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.INPUT_BG_COLOR,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPickerRow(
                    label: '키 (cm)',
                    value:
                        '${_height?.toStringAsFixed(1) ?? _defaultHeight.toStringAsFixed(1)} cm',
                    onTap: _showHeightPicker,
                  ),
                  const SizedBox(height: 12),
                  _buildPickerRow(
                    label: '몸무게 (kg)',
                    value:
                        '${_weight?.toStringAsFixed(1) ?? _defaultWeight.toStringAsFixed(1)} kg',
                    onTap: _showWeightPicker,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '성별',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.MEDIUM_GREY,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: Text(
                          '남성',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gender == 'MALE'
                                ? AppColors.PRIMARYCOLOR
                                : AppColors.BODY_COLOR,
                          ),
                        ),
                        selected: _gender == 'MALE',
                        onSelected: (v) =>
                            setState(() => _gender = v ? 'MALE' : null),
                        selectedColor: AppColors.ACCENT_COLOR.withOpacity(0.3),
                        backgroundColor: AppColors.INPUT_BG_COLOR,
                        side: BorderSide(
                          color: _gender == 'MALE'
                              ? AppColors.ACCENT_COLOR
                              : AppColors.BORDER_COLOR,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          '여성',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gender == 'FEMALE'
                                ? AppColors.PRIMARYCOLOR
                                : AppColors.BODY_COLOR,
                          ),
                        ),
                        selected: _gender == 'FEMALE',
                        onSelected: (v) =>
                            setState(() => _gender = v ? 'FEMALE' : null),
                        selectedColor: AppColors.ACCENT_COLOR.withOpacity(0.3),
                        backgroundColor: AppColors.INPUT_BG_COLOR,
                        side: BorderSide(
                          color: _gender == 'FEMALE'
                              ? AppColors.ACCENT_COLOR
                              : AppColors.BORDER_COLOR,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.PRIMARYCOLOR,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('저장'),
                    ),
                  ),
                  if (widget.onLogout != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _onLogoutTap,
                        icon: const Icon(Icons.logout_outlined, size: 18),
                        label: const Text('로그아웃'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.MEDIUM_GREY,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.INPUT_BG_COLOR,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.BORDER_COLOR),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.MEDIUM_GREY,
            ),
          ],
        ),
      ),
    );
  }
}
