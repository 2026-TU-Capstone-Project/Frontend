import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import '../component/fitting_onboarding_sheet.dart';
import '../theme/fitting_room_theme.dart';
import '../component/fitting_room_header.dart';
import '../component/fitting_main_stage.dart';
import '../component/ai_stylist_input.dart';
import '../component/add_clothing_sheet.dart';
import '../component/wardrobe_picker_sheet.dart';

class FittingRoomScreen extends StatefulWidget {
  const FittingRoomScreen({super.key});

  @override
  State<FittingRoomScreen> createState() => _FittingRoomScreenState();
}

class _FittingRoomScreenState extends State<FittingRoomScreen>
    with SingleTickerProviderStateMixin {
  late FittingRepository _fittingRepository;
  late ClothesRepository _clothesRepository;

  String? _resultImageUrl;
  bool _isFittingNow = false;
  String? _latency;

  File? _selectedUserImage;
  File? _selectedTopFile;
  File? _selectedBottomFile;

  String? _selectedTopUrl;
  String? _selectedBottomUrl;

  final TextEditingController _promptController = TextEditingController();
  late AnimationController _animationController;

  List<ClothesModel> _serverClothes = [];

  final List<Map<String, dynamic>> _quickChips = [
    {'icon': Icons.business, 'label': '오피스룩 추천해줘'},
    {'icon': Icons.flight_takeoff, 'label': '여행 갈 때 뭐 입지?'},
    {'icon': Icons.favorite, 'label': '데이트 룩 추천해줘'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _initServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showOnboardingSheet();
      });
    });
  }

  Future<void> _initServices() async {
    final dio = Dio();
    // 👇 LogInterceptor 제거됨 (깔끔!)

    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    if (accessToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }

    _fittingRepository = FittingRepository(dio, baseUrl: 'http://$ip');
    _clothesRepository = ClothesRepository(dio, baseUrl: 'http://$ip');

    await _loadWardrobe();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showOnboardingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      transitionAnimationController: _animationController,
      builder: (context) =>
          FittingOnboardingSheet(onStart: () => Navigator.pop(context)),
    );
  }

  Future<void> _loadWardrobe() async {
    try {
      final resp = await _clothesRepository.getClothesList();
      if (resp.success && mounted) {
        setState(() => _serverClothes = resp.data ?? []);
      }
    } catch (e) {
      // 에러 처리는 필요하다면 남겨두거나, 조용히 넘어가도록 수정
    }
  }

  Future<void> _pickUserImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _selectedUserImage = File(image.path));
    }
  }

  Future<void> _selectCloth(ClothesModel cloth) async {
    if (cloth.imgUrl == null) return;

    final imageUrl = cloth.imgUrl!;
    final category = cloth.category?.toUpperCase() ?? "";
    final isTop = category.contains("TOP") || category.contains("상의") || category.contains("SHIRT") || category.contains("OUTER");

    setState(() {
      if (isTop) _selectedTopUrl = imageUrl;
      else _selectedBottomUrl = imageUrl;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cloth_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, tempPath);

      if (!mounted) return;

      setState(() {
        if (isTop) _selectedTopFile = File(tempPath);
        else _selectedBottomFile = File(tempPath);
      });
    } catch (e) {
      // 이미지 다운로드 실패 시 처리 (조용히 넘김)
    }
  }

  Future<void> _startVirtualFitting() async {
    if (_selectedUserImage == null || _selectedTopFile == null) return;

    final stopwatch = Stopwatch()..start();
    setState(() {
      _isFittingNow = true;
      _resultImageUrl = null;
      _latency = null;
    });

    try {
      final reqResp = await _fittingRepository.requestFitting(
        userImage: _selectedUserImage!,
        topImage: _selectedTopFile!,
        bottomImage: _selectedBottomFile,
      );

      if (reqResp.data == null) {
        throw Exception("서버 응답(data)이 비어있습니다.");
      }

      final taskId = reqResp.data!.taskId;
      String? finalUrl;

      while (true) {
        if (!mounted) break;

        await Future.delayed(const Duration(seconds: 2));
        final statusResp = await _fittingRepository.checkStatus(taskId: taskId);

        if (statusResp.data == null) continue;

        final statusData = statusResp.data!;

        if (statusData.status == 'COMPLETED') {
          finalUrl = statusData.resultImgUrl;
          break;
        } else if (statusData.status == 'FAILED') {
          throw Exception('서버 작업 실패 (FAILED)');
        }
      }

      if (finalUrl != null && mounted) {
        setState(() => _resultImageUrl = finalUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피팅 작업 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isFittingNow = false;
          _latency = "${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s";
        });
      }
    }
  }

  void _openWardrobePicker(String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WardrobePickerSheet(
        clothes: _serverClothes,
        onClothSelected: _selectCloth,
        category: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUser = _selectedUserImage != null;
    final bool hasTop = _selectedTopFile != null;
    final bool isReady = hasUser && hasTop;

    String buttonText;
    if (_isFittingNow) {
      buttonText = "스타일 분석 중...";
    } else if (isReady) {
      buttonText = "가상 피팅 시작하기";
    } else if (!hasUser) {
      buttonText = "전신 사진을 선택하세요";
    } else {
      buttonText = "상의를 선택하세요";
    }

    String? helperText;
    if (!_isFittingNow && !isReady) {
      helperText = buttonText;
    }

    return Scaffold(
      backgroundColor: FittingRoomTheme.kBackgroundColor,

      bottomNavigationBar: _BottomCtaBar(
        isReady: isReady,
        isLoading: _isFittingNow,
        buttonText: buttonText,
        helperText: helperText,
        latencyText: _latency != null ? "$_latency 소요" : null,
        onPressed: (_isFittingNow || !isReady) ? null : _startVirtualFitting,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const FittingRoomHeader(),
              const SizedBox(height: 20),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1️⃣ 좌측: 전신 사진 (5/8)
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        onTap: _pickUserImage,
                        child: FittingMainStage(
                          imagePath: _resultImageUrl ??
                              _selectedUserImage?.path ??
                              'asset/img/fitting1.jpg',
                          isLoading: _isFittingNow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 2️⃣ 우측: 상의/하의 슬롯 (3/8)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // 상의 슬롯
                          Expanded(
                            child: _ClothingSlot(
                              label: "상의 (필수)",
                              imageUrl: _selectedTopUrl,
                              placeholderIcon: Icons.checkroom,
                              isActive: _selectedTopUrl != null,
                              onTap: () => showAddClothingBottomSheet(
                                context,
                                '상의',
                                onWardrobeTap: () => _openWardrobePicker('TOP'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 하의 슬롯
                          Expanded(
                            child: _ClothingSlot(
                              label: "하의 (선택)",
                              imageUrl: _selectedBottomUrl,
                              placeholderIcon: Icons.trolley,
                              isActive: _selectedBottomUrl != null,
                              onTap: () => showAddClothingBottomSheet(
                                context,
                                '하의',
                                onWardrobeTap: () => _openWardrobePicker('BOTTOM'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "좌측 이미지를 탭하여 전신 사진을 변경하세요",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              AiStylistInput(controller: _promptController, chips: _quickChips),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClothingSlot extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData placeholderIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _ClothingSlot({
    required this.label,
    this.imageUrl,
    required this.placeholderIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? PRIMARYCOLOR : Colors.grey.shade200,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error_outline, color: Colors.grey),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(placeholderIcon, color: Colors.grey.shade300, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "선택",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.isReady,
    required this.isLoading,
    required this.buttonText,
    required this.onPressed,
    this.helperText,
    this.latencyText,
  });

  final bool isReady;
  final bool isLoading;
  final String buttonText;
  final VoidCallback? onPressed;
  final String? helperText;
  final String? latencyText;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (helperText != null || latencyText != null) _buildInfoRow(),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: onPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: (isReady && !isLoading)
                        ? PRIMARYCOLOR
                        : Colors.grey.shade300,
                    boxShadow: (isReady && !isLoading)
                        ? [
                      BoxShadow(
                        color: PRIMARYCOLOR.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                        : [],
                  ),
                  child: Center(
                    child: isLoading
                        ? const _LoadingIndicator()
                        : _ButtonContent(isReady: isReady, text: buttonText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    final isTimer = latencyText != null;
    return Row(
      children: [
        Icon(
          isTimer ? Icons.timer_outlined : Icons.info_outline,
          size: 14,
          color: isTimer ? Colors.green : Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          latencyText ?? helperText!,
          style: TextStyle(
            fontSize: 12,
            color: isTimer ? Colors.green : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
        SizedBox(width: 12),
        Text("스타일 분석 중...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final bool isReady;
  final String text;

  const _ButtonContent({required this.isReady, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isReady ? Icons.auto_awesome : Icons.checkroom, color: isReady ? Colors.white : Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: isReady ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}