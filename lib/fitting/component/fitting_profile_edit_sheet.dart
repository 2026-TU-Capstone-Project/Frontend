import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';

/// 피팅 프로필 수정/등록 시트 (유저 탭에서 호출)
/// 초기값이 있으면 수정, 없으면 신규 등록
class FittingProfileEditSheet extends StatefulWidget {
  final FittingProfile? initialProfile;
  final VoidCallback? onSaved;

  const FittingProfileEditSheet({
    this.initialProfile,
    this.onSaved,
    super.key,
  });

  @override
  State<FittingProfileEditSheet> createState() => _FittingProfileEditSheetState();
}

class _FittingProfileEditSheetState extends State<FittingProfileEditSheet> {
  final _topSizeController = TextEditingController();
  final _bottomSizeController = TextEditingController();

  File? _frontImage;

  static const List<String> _topSizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static final List<String> _bottomSizeOptions = List.generate(15, (i) => '${26 + i}');

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    if (p != null) {
      _topSizeController.text = p.topSize ?? '';
      _bottomSizeController.text = p.bottomSize ?? '';
      if (p.frontImagePath != null) {
        final f = File(p.frontImagePath!);
        if (f.existsSync()) _frontImage = f;
      }
    }
  }

  @override
  void dispose() {
    _topSizeController.dispose();
    _bottomSizeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String? savedFrontPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${dir.path}/fitting_profile');
      if (!await profileDir.exists()) await profileDir.create(recursive: true);
      if (_frontImage != null) {
        final ext = _frontImage!.path.split('.').last;
        final name = 'front_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final dest = File('${profileDir.path}/$name');
        await _frontImage!.copy(dest.path);
        savedFrontPath = dest.path;
      } else if (widget.initialProfile?.frontImagePath != null) {
        savedFrontPath = widget.initialProfile!.frontImagePath;
      }
      final profile = FittingProfile(
        frontImagePath: savedFrontPath,
        topSize: _topSizeController.text.trim().isEmpty ? null : _topSizeController.text.trim(),
        bottomSize: _bottomSizeController.text.trim().isEmpty ? null : _bottomSizeController.text.trim(),
      );
      await FittingProfile.save(profile);
    } catch (e) {
      debugPrint('피팅 프로필 저장 실패: $e');
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved?.call();
    }
  }

  Future<void> _pickFrontImage() async {
    final picker = ImagePicker();
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
    final x = await picker.pickImage(source: source);
    if (x != null && mounted) setState(() => _frontImage = File(x.path));
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소', style: TextStyle(color: AppColors.MEDIUM_GREY, fontWeight: FontWeight.w600)),
                ),
                const Text(
                  '피팅 프로필',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.BLACK,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('저장', style: TextStyle(color: AppColors.PRIMARYCOLOR, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection('정면 사진', _frontImage, _pickFrontImage),
                  const SizedBox(height: 28),
                  const Text(
                    '사이즈',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.BLACK,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: '상의 사이즈',
                          value: _topSizeController.text.isEmpty ? null : _topSizeController.text,
                          hint: '선택',
                          items: _topSizeOptions,
                          onChanged: (v) {
                            _topSizeController.text = v ?? '';
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField(
                          label: '하의 사이즈',
                          value: _bottomSizeController.text.isEmpty ? null : _bottomSizeController.text,
                          hint: '선택',
                          items: _bottomSizeOptions,
                          onChanged: (v) {
                            _bottomSizeController.text = v ?? '';
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.MEDIUM_GREY,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.INPUT_BG_COLOR,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.BORDER_COLOR),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : _buildEmptyPhoto(),
                  )
                : _buildEmptyPhoto(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhoto() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.MEDIUM_GREY),
        const SizedBox(height: 8),
        Text(
          '사진 추가',
          style: TextStyle(fontSize: 14, color: AppColors.MEDIUM_GREY),
        ),
      ],
    );
  }

  /// iOS: Cupertino 피커. Android: Material 드롭다운
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    if (Platform.isIOS) {
      return _buildCupertinoSizeField(
        label: label,
        value: value,
        hint: hint,
        items: items,
        onSelected: onChanged,
      );
    }
    return _buildMaterialDropdownField(
      label: label,
      value: value,
      hint: hint,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCupertinoSizeField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onSelected,
  }) {
    final display = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.BLACK,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCupertinoSizePicker(
            context: context,
            title: label,
            options: items,
            initialValue: display,
            onSelected: (v) {
              onSelected(v);
              setState(() {});
            },
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.INPUT_BG_COLOR,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.BORDER_COLOR),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  display ?? hint,
                  style: TextStyle(
                    fontSize: 16,
                    color: display != null ? AppColors.BLACK : AppColors.MEDIUM_GREY,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.MEDIUM_GREY, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoSizePicker({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? initialValue,
    required ValueChanged<String?> onSelected,
  }) {
    int index = initialValue != null && options.contains(initialValue)
        ? options.indexOf(initialValue)
        : 0;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () {
                      onSelected(options[index]);
                      Navigator.pop(ctx);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(initialItem: index.clamp(0, options.length - 1)),
                onSelectedItemChanged: (i) => index = i,
                children: options.map((e) => Center(child: Text(e))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Material 드롭다운: Android용
  Widget _buildMaterialDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.BLACK,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value != null && items.contains(value) ? value : null,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 16),
          ),
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
