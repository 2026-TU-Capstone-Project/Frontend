import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/camera/photo_guide_screen.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';

/// 최초 로그인 유저 온보딩: 1) 환영 → 2) 전신 사진 → 3) 신체 정보(키·몸무게·성별)
/// 전신 사진을 서버 프로필 이미지 + 로컬 가상 피팅 frontImage로 동시 저장
class FittingOnboardingSheet extends ConsumerStatefulWidget {
  final VoidCallback onStart;

  const FittingOnboardingSheet({required this.onStart, super.key});

  @override
  ConsumerState<FittingOnboardingSheet> createState() =>
      _FittingOnboardingSheetState();
}

class _FittingOnboardingSheetState
    extends ConsumerState<FittingOnboardingSheet> {
  static const int _totalSteps = 3;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  bool _isAgreed = false;
  File? _frontImage;
  bool _isSubmitting = false;

  // 신체 정보
  double _height = 165;
  double _weight = 60;
  String _gender = 'MALE'; // 'MALE' | 'FEMALE'

  static final List<double> _heightOptions =
      List.generate(81, (i) => (140 + i).toDouble()); // 140~220 cm
  static final List<double> _weightOptions =
      List.generate(121, (i) => (30 + i).toDouble()); // 30~150 kg

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _skip() async {
    try {
      await FittingProfile.save(FittingProfile(onboardingCompleted: true));
    } catch (e) {
      debugPrint('온보딩 건너뛰기 저장 실패: $e');
    }
    if (mounted) widget.onStart();
  }

  /// A. 서버에 프로필 전송 (키·몸무게·성별·사진)
  /// B. 사진을 로컬에 복사 후 FittingProfile 저장
  Future<void> _saveAndStart() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    String? savedFrontPath;
    try {
      // A. 서버 전송
      final repo = ref.read(authRepositoryProvider);
      final authDio = ref.read(authDioProvider);
      await repo.submitOnboardingProfile(
        authDio,
        height: _height,
        weight: _weight,
        gender: _gender,
        profileImage: _frontImage,
      );

      // B. 로컬 저장
      if (_frontImage != null) {
        final dir = await getApplicationDocumentsDirectory();
        final profileDir = Directory('${dir.path}/fitting_profile');
        if (!await profileDir.exists()) {
          await profileDir.create(recursive: true);
        }
        final ext = _frontImage!.path.split('.').last;
        final name = 'front_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final dest = File('${profileDir.path}/$name');
        await _frontImage!.copy(dest.path);
        savedFrontPath = dest.path;
      }

      await FittingProfile.save(
        FittingProfile(
          frontImagePath: savedFrontPath,
          onboardingCompleted: true,
        ),
      );
    } catch (e) {
      debugPrint('온보딩 프로필 저장 실패: $e');
      // 서버 실패해도 로컬 온보딩 완료 처리
      try {
        await FittingProfile.save(
          FittingProfile(
            frontImagePath: savedFrontPath,
            onboardingCompleted: true,
          ),
        );
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (mounted) widget.onStart();
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
    if (source == ImageSource.camera) {
      final file =
          await PhotoGuideScreen.open(context, type: PhotoGuideType.fullBody);
      if (file != null && mounted) setState(() => _frontImage = file);
    } else {
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x != null && mounted) setState(() => _frontImage = File(x.path));
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
                color: AppColors.ACCENT_COLOR.withValues(alpha: 0.12),
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
                _buildWelcomeStep(),
                _buildFrontPhotoStep(),
                _buildBodyInfoStep(),
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
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.PRIMARYCOLOR,
                ),
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

  // ─── Step 1: 환영 ───────────────────────────────────────────────────────────

  Widget _buildWelcomeStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('asset/img/fitting1.jpg', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.white.withValues(alpha: 0.1),
                          AppColors.white.withValues(alpha: 0.9),
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
                          color: _isAgreed
                              ? AppColors.PRIMARYCOLOR
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAgreed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _isAgreed
                                ? AppColors.PRIMARYCOLOR
                                : AppColors.MEDIUM_GREY,
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
                                color: _isAgreed
                                    ? Colors.white
                                    : AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.arrow_forward,
                              color: _isAgreed
                                  ? AppColors.PRIMARYCOLOR
                                  : AppColors.MEDIUM_GREY,
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

  // ─── Step 2: 전신 사진 ─────────────────────────────────────────────────────

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
            '전신이 나오는 정면 사진을 등록해주세요.\n프로필 사진과 가상 피팅에 함께 사용됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.BODY_COLOR,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '정면 전신 사진 (선택)',
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
              height: 360,
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
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: AppColors.MEDIUM_GREY,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '사진 촬영 또는 선택',
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
            '정면을 바라보고 전신이 나오게 찍어주세요',
            style: TextStyle(fontSize: 12, color: AppColors.MEDIUM_GREY),
          ),
          const SizedBox(height: 40),
          _buildNextButton('다음'),
        ],
      ),
    );
  }

  // ─── Step 3: 신체 정보 (키·몸무게·성별) ────────────────────────────────────

  Widget _buildBodyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '신체 정보를 입력해주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '정확한 가상 피팅을 위해 신체 정보를 알려주세요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.BODY_COLOR,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // 성별 토글
          const Text(
            '성별',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.BLACK,
            ),
          ),
          const SizedBox(height: 8),
          _buildGenderToggle(),
          const SizedBox(height: 20),

          // 키 & 몸무게
          Row(
            children: [
              Expanded(
                child: _buildNumericPickerField(
                  label: '키',
                  value: _height,
                  options: _heightOptions,
                  unit: 'cm',
                  onChanged: (v) => setState(() => _height = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumericPickerField(
                  label: '몸무게',
                  value: _weight,
                  options: _weightOptions,
                  unit: 'kg',
                  onChanged: (v) => setState(() => _weight = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ACCENT_COLOR.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.ACCENT_COLOR.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20, color: AppColors.ACCENT_COLOR),
                const SizedBox(width: 12),
                const Expanded(
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
              onPressed: _isSubmitting ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.PRIMARYCOLOR,
                disabledBackgroundColor: AppColors.INPUT_BG_COLOR,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.MEDIUM_GREY,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const LoadingIndicator(size: 24)
                  : const Text(
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

  /// 성별 토글 (MALE / FEMALE)
  Widget _buildGenderToggle() {
    return Row(
      children: [
        Expanded(child: _genderOption(label: '남성', value: 'MALE')),
        const SizedBox(width: 12),
        Expanded(child: _genderOption(label: '여성', value: 'FEMALE')),
      ],
    );
  }

  Widget _genderOption({required String label, required String value}) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.PRIMARYCOLOR : AppColors.INPUT_BG_COLOR,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.PRIMARYCOLOR : AppColors.BORDER_COLOR,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.MEDIUM_GREY,
            ),
          ),
        ),
      ),
    );
  }

  /// iOS → CupertinoPicker 모달, Android → DropdownButtonFormField
  Widget _buildNumericPickerField({
    required String label,
    required double value,
    required List<double> options,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    if (Platform.isIOS) {
      return _buildCupertinoNumericField(
        label: label,
        value: value,
        options: options,
        unit: unit,
        onSelected: onChanged,
      );
    }
    return _buildMaterialNumericDropdown(
      label: label,
      value: value,
      options: options,
      unit: unit,
      onChanged: onChanged,
    );
  }

  Widget _buildCupertinoNumericField({
    required String label,
    required double value,
    required List<double> options,
    required String unit,
    required ValueChanged<double> onSelected,
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
        GestureDetector(
          onTap: () => _showCupertinoNumericPicker(
            title: label,
            options: options,
            initialValue: value,
            unit: unit,
            onSelected: onSelected,
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
                  '${value.toStringAsFixed(0)} $unit',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.BLACK,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.MEDIUM_GREY,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoNumericPicker({
    required String title,
    required List<double> options,
    required double initialValue,
    required String unit,
    required ValueChanged<double> onSelected,
  }) {
    int index = options.indexOf(initialValue).clamp(0, options.length - 1);
    if (index < 0) index = 0;

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
                      setState(() {});
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
                scrollController: FixedExtentScrollController(
                  initialItem: index.clamp(0, options.length - 1),
                ),
                onSelectedItemChanged: (i) => index = i,
                children: options
                    .map((e) => Center(
                          child: Text('${e.toStringAsFixed(0)} $unit'),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialNumericDropdown({
    required String label,
    required double value,
    required List<double> options,
    required String unit,
    required ValueChanged<double> onChanged,
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
        DropdownButtonFormField<double>(
          initialValue: options.contains(value) ? value : options.first,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: options
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text('${e.toStringAsFixed(0)} $unit'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
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
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
