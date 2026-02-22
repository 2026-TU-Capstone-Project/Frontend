import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';

/// 가상 피팅 첫 진입 시 온보딩: 1) 원래 환영 화면 → 2) 정면 사진 → 3) 측면 사진 → 4) 신체 정보 (저장 후 유저 탭에서 조회)
class FittingOnboardingSheet extends StatefulWidget {
  final VoidCallback onStart;

  const FittingOnboardingSheet({required this.onStart, super.key});

  @override
  State<FittingOnboardingSheet> createState() => _FittingOnboardingSheetState();
}

class _FittingOnboardingSheetState extends State<FittingOnboardingSheet> {
  static const int _totalSteps = 4;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  bool _isAgreed = false;
  File? _frontImage;
  File? _sideImage;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _topSizeController = TextEditingController();
  final _bottomSizeController = TextEditingController();
  final _shoeSizeController = TextEditingController();

  static const List<String> _topSizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static final List<String> _bottomSizeOptions = List.generate(15, (i) => '${26 + i}');
  static final List<String> _shoeSizeOptions = List.generate(17, (i) => '${220 + i * 5}');

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _topSizeController.dispose();
    _bottomSizeController.dispose();
    _shoeSizeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveAndStart();
    }
  }

  void _skip() {
    widget.onStart();
  }

  Future<void> _saveAndStart() async {
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
      }
      if (_sideImage != null) {
        final ext = _sideImage!.path.split('.').last;
        final name = 'side_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final dest = File('${profileDir.path}/$name');
        await _sideImage!.copy(dest.path);
        savedSidePath = dest.path;
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
      debugPrint('온보딩 프로필 저장 실패: $e');
    }
    if (mounted) widget.onStart();
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
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          if (_currentStep > 0) _buildHeader(topPadding),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildOriginalWelcomeStep(),
                _buildFrontPhotoStep(),
                _buildSidePhotoStep(),
                _buildBodySizeStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    final progress = (_currentStep + 1) / _totalSteps;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 12),
      child: Row(
        children: [
          Text(
            '${_currentStep + 1}/$_totalSteps',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.BORDER_COLOR,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.PRIMARYCOLOR),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _skip,
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.MEDIUM_GREY,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 수정 전 원래 환영 화면: 배경 이미지 + PERFECT FIT + 동의 + 지금 시작하기(다음으로 이동)
  Widget _buildOriginalWelcomeStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'asset/img/fitting1.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.white.withOpacity(0.1),
                          AppColors.white.withOpacity(0.9),
                          AppColors.white,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "PERFECT FIT",
                    style: TextStyle(
                      color: AppColors.PRIMARYCOLOR,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w300,
                        color: AppColors.BLACK,
                        height: 1.2,
                        letterSpacing: -1.0,
                      ),
                      children: [
                        TextSpan(text: '실패 없는 쇼핑,\n'),
                        TextSpan(
                          text: 'AI 가상 피팅',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "사진 한 장으로 내 몸에 딱 맞는 핏을 확인하세요.\n반품 걱정 없는 쇼핑이 시작됩니다.",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.BODY_COLOR,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () => setState(() => _isAgreed = !_isAgreed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.INPUT_BG_COLOR,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAgreed ? AppColors.PRIMARYCOLOR : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAgreed ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _isAgreed ? AppColors.PRIMARYCOLOR : AppColors.MEDIUM_GREY,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "개인정보 수집 및 이용 동의 (필수)",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.BLACK,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isAgreed ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.PRIMARYCOLOR,
                        disabledBackgroundColor: AppColors.INPUT_BG_COLOR,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.MEDIUM_GREY,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "지금 시작하기",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isAgreed ? Colors.white : AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.arrow_forward,
                              color: _isAgreed ? AppColors.PRIMARYCOLOR : AppColors.MEDIUM_GREY,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrontPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전신 사진을 등록해주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '정면 사진만 있어도 괜찮아요! 측면 사진까지 있으면 더 정확해요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.BODY_COLOR,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '1 정면 사진 (필수)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickFrontImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.INPUT_BG_COLOR,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.BORDER_COLOR),
              ),
              child: _frontImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_frontImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.MEDIUM_GREY),
                        const SizedBox(height: 12),
                        Text(
                          '사진 촬영하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.BODY_COLOR,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '정면을 바라보고 전신이 나오게',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 40),
          _buildNextButton('다음'),
        ],
      ),
    );
  }

  Widget _buildSidePhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '측면 사진 (선택)',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '더 정확한 피팅을 원한다면 측면 사진도 등록해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.BODY_COLOR,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '2 측면 사진 (선택)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickSideImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.INPUT_BG_COLOR,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.BORDER_COLOR),
              ),
              child: _sideImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_sideImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.MEDIUM_GREY),
                        const SizedBox(height: 12),
                        Text(
                          '나중에 추가하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.BODY_COLOR,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '더 정확한 피팅을 원한다면',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 40),
          _buildNextButton('다음'),
        ],
      ),
    );
  }

  Widget _buildBodySizeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '신체 사이즈를 알려주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '더 정확한 가상 피팅을 위해 사이즈 정보를 입력해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.BODY_COLOR,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildTextField(
            controller: _heightController,
            label: '키 (cm)',
            hint: '예: 170',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _weightController,
            label: '몸무게 (kg)',
            hint: '예: 65',
            keyboardType: TextInputType.number,
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ACCENT_COLOR.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ACCENT_COLOR.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20, color: AppColors.ACCENT_COLOR),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '입력하신 정보는 안전하게 보호되며, 가상 피팅 목적으로만 사용됩니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.BODY_COLOR,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.PRIMARYCOLOR,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '피팅룸 시작하기',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PRIMARYCOLOR,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
