import 'dart:io';
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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _topSizeController = TextEditingController();
  final _bottomSizeController = TextEditingController();
  final _shoeSizeController = TextEditingController();

  File? _frontImage;
  File? _sideImage;

  static const List<String> _topSizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static final List<String> _bottomSizeOptions = List.generate(15, (i) => '${26 + i}');
  static final List<String> _shoeSizeOptions = List.generate(17, (i) => '${220 + i * 5}');

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    if (p != null) {
      _heightController.text = p.height ?? '';
      _weightController.text = p.weight ?? '';
      _topSizeController.text = p.topSize ?? '';
      _bottomSizeController.text = p.bottomSize ?? '';
      _shoeSizeController.text = p.shoeSize ?? '';
      if (p.frontImagePath != null) {
        final f = File(p.frontImagePath!);
        if (f.existsSync()) _frontImage = f;
      }
      if (p.sideImagePath != null) {
        final f = File(p.sideImagePath!);
        if (f.existsSync()) _sideImage = f;
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _topSizeController.dispose();
    _bottomSizeController.dispose();
    _shoeSizeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String? savedFrontPath;
    String? savedSidePath;
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
      if (_sideImage != null) {
        final ext = _sideImage!.path.split('.').last;
        final name = 'side_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final dest = File('${profileDir.path}/$name');
        await _sideImage!.copy(dest.path);
        savedSidePath = dest.path;
      } else if (widget.initialProfile?.sideImagePath != null) {
        savedSidePath = widget.initialProfile!.sideImagePath;
      }
      final profile = FittingProfile(
        frontImagePath: savedFrontPath,
        sideImagePath: savedSidePath,
        height: _heightController.text.trim().isEmpty ? null : _heightController.text.trim(),
        weight: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        topSize: _topSizeController.text.trim().isEmpty ? null : _topSizeController.text.trim(),
        bottomSize: _bottomSizeController.text.trim().isEmpty ? null : _bottomSizeController.text.trim(),
        shoeSize: _shoeSizeController.text.trim().isEmpty ? null : _shoeSizeController.text.trim(),
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('사진 촬영하기'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final x = await picker.pickImage(source: source);
    if (x != null && mounted) setState(() => _frontImage = File(x.path));
  }

  Future<void> _pickSideImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null && mounted) setState(() => _sideImage = File(x.path));
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
                  const SizedBox(height: 20),
                  _buildPhotoSection('측면 사진 (선택)', _sideImage, _pickSideImage),
                  const SizedBox(height: 28),
                  const Text(
                    '신체 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.BLACK,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _heightController, label: '키 (cm)', hint: '예: 170', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _weightController, label: '몸무게 (kg)', hint: '예: 65', keyboardType: TextInputType.number),
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
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: '신발 사이즈 (mm)',
                    value: _shoeSizeController.text.isEmpty ? null : _shoeSizeController.text,
                    hint: '선택',
                    items: _shoeSizeOptions,
                    onChanged: (v) {
                      _shoeSizeController.text = v ?? '';
                      setState(() {});
                    },
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
            height: 180,
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

  /// Material 드롭다운: 상의/하의/신발 사이즈 선택
  Widget _buildDropdownField({
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
