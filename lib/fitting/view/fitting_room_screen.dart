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
// 👇 [필수] 모델 파일이 있어야 taskId, status 등을 인식합니다.
import 'package:capstone_fe/fitting/model/fitting_model.dart';

import '../component/fitting_onboarding_sheet.dart';
import '../theme/fitting_room_theme.dart';
import '../component/fitting_room_header.dart';
import '../component/fitting_main_stage.dart';
import '../component/ai_stylist_input.dart';

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

    // 👇 [디버깅] 서버 에러 확인을 위해 로그 활성화
    dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true
    ));

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
      debugPrint(e.toString());
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
    final isTop = category.contains("TOP") || category.contains("상의") || category.contains("SHIRT");

    setState(() {
      if (isTop) _selectedTopUrl = imageUrl;
      else _selectedBottomUrl = imageUrl;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cloth_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, tempPath);

      if (!mounted) return; // ✅ 앱이 꺼졌으면 중단

      setState(() {
        if (isTop) _selectedTopFile = File(tempPath);
        else _selectedBottomFile = File(tempPath);
      });
    } catch (e) {
      debugPrint("이미지 다운로드 에러: $e");
    }
  }

  Future<void> _startVirtualFitting() async {
    // 상의 필수 체크
    if (_selectedUserImage == null || _selectedTopFile == null) return;

    final stopwatch = Stopwatch()..start();
    setState(() {
      _isFittingNow = true;
      _resultImageUrl = null;
      _latency = null;
    });

    try {
      // 1. 요청 (POST)
      final reqResp = await _fittingRepository.requestFitting(
        userImage: _selectedUserImage!,
        topImage: _selectedTopFile!,
        bottomImage: _selectedBottomFile,
      );

      // ✅ [Null Check] 응답 데이터 확인
      if (reqResp.data == null) {
        throw Exception("서버 응답(data)이 비어있습니다.");
      }

      // ✅ [경로 수정] ApiResponse -> Data -> taskId (중복 껍데기 제거됨)
      final taskId = reqResp.data!.taskId;
      String? finalUrl;

      // 2. 폴링 (GET Status)
      while (true) {
        if (!mounted) break; // ✅ 화면 나갔으면 루프 종료

        await Future.delayed(const Duration(seconds: 2));
        final statusResp = await _fittingRepository.checkStatus(taskId: taskId);

        // ✅ [Null Check]
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
          SnackBar(content: Text('오류 발생: $e')),
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

  @override
  Widget build(BuildContext context) {
    final bool hasUser = _selectedUserImage != null;
    final bool hasTop = _selectedTopFile != null;
    final bool isReady = hasUser && hasTop;

    String? helperText;
    if (!_isFittingNow && !isReady) {
      if (!hasUser && !hasTop) helperText = "전신 사진과 상의를 선택해 주세요";
      else if (!hasUser) helperText = "전신 사진을 먼저 선택해 주세요";
      else if (!hasTop) helperText = "입어볼 상의를 선택해 주세요 (필수)";
    }

    return Scaffold(
      backgroundColor: FittingRoomTheme.kBackgroundColor,

      // ✅ 하단 고정 CTA 바
      bottomNavigationBar: _BottomCtaBar(
        isReady: isReady,
        isLoading: _isFittingNow,
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
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickUserImage,
                child: FittingMainStage(
                  imagePath: _resultImageUrl ??
                      _selectedUserImage?.path ??
                      'asset/img/fitting1.jpg',
                  isLoading: _isFittingNow,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "이미지를 탭하여 전신 사진을 변경하세요",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),
              AiStylistInput(controller: _promptController, chips: _quickChips),
              const SizedBox(height: 32),

              const Text("내 옷장", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildWardrobeList(),

              const SizedBox(height: 120), // 하단 공간 확보
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeList() {
    return SizedBox(
      height: 110,
      child: _serverClothes.isEmpty
          ? Center(child: Text("옷장이 비어있습니다.", style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _serverClothes.length,
        itemBuilder: (context, index) {
          final cloth = _serverClothes[index];
          final isSelected = (cloth.imgUrl == _selectedTopUrl) || (cloth.imgUrl == _selectedBottomUrl);
          return _buildClothItem(cloth, isSelected);
        },
      ),
    );
  }

  Widget _buildClothItem(ClothesModel cloth, bool isSelected) {
    return GestureDetector(
      onTap: () => cloth.imgUrl != null ? _selectCloth(cloth) : null,
      child: Stack(
        children: [
          Container(
            width: 75,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? PRIMARYCOLOR : Colors.grey.shade300,
                width: isSelected ? 3.0 : 1.0,
              ),
              image: cloth.imgUrl != null
                  ? DecorationImage(image: NetworkImage(cloth.imgUrl!), fit: BoxFit.cover)
                  : null,
            ),
          ),
          if (isSelected)
            Positioned(
              top: 4, right: 16,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: PRIMARYCOLOR, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// ✅ 하단 CTA 바 (디자인 유지)
class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.isReady,
    required this.isLoading,
    required this.onPressed,
    this.helperText,
    this.latencyText,
  });

  final bool isReady;
  final bool isLoading;
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
                    gradient: (isReady && !isLoading)
                        ? const LinearGradient(
                      colors: [PRIMARYCOLOR, Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade300],
                    ),
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
                        : _ButtonContent(isReady: isReady),
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
  const _ButtonContent({required this.isReady});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isReady ? Icons.auto_awesome : Icons.checkroom, color: isReady ? Colors.white : Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          isReady ? "스타일 완성하기" : "상의를 선택하세요",
          style: TextStyle(color: isReady ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}