import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';

import '../component/fitting_onboarding_sheet.dart';
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
  late ClothesSetRepository _clothesSetRepository;

  String? _resultImageUrl;
  int? _currentTaskId;
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
        if (mounted) _showOnboardingIfNeeded();
      });
    });
  }

  /// 유저에 저장된 피팅 프로필이 없을 때만 온보딩 표시 (저장된 경우 두 번 안 뜸)
  Future<void> _showOnboardingIfNeeded() async {
    final profile = await FittingProfile.load();
    if (!mounted) return;
    if (profile != null && profile.hasAnyData) {
      return;
    }
    _showOnboardingSheet();
  }

  Future<void> _initServices() async {
    final dio = createAuthDio();
    _fittingRepository = FittingRepository(dio, baseUrl: baseUrl);
    _clothesRepository = ClothesRepository(dio, baseUrl: baseUrl);
    _clothesSetRepository = ClothesSetRepository(dio, baseUrl: baseUrl);
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
      // 에러 처리
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
    final isTop = category.contains("TOP") ||
        category.contains("상의") ||
        category.contains("SHIRT") ||
        category.contains("OUTER");

    setState(() {
      if (isTop) {
        _selectedTopUrl = imageUrl;
        _selectedTopFile = null;
      } else {
        _selectedBottomUrl = imageUrl;
        _selectedBottomFile = null;
      }
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cloth_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';
      await Dio().download(imageUrl, tempPath);

      if (!mounted) return;
      setState(() {
        if (isTop)
          _selectedTopFile = File(tempPath);
        else
          _selectedBottomFile = File(tempPath);
      });
    } catch (e) {
      debugPrint("이미지 다운로드 에러: $e");
    }
  }

  Future<void> _startVirtualFitting() async {
    if (_selectedUserImage == null || _selectedTopFile == null) return;

    final stopwatch = Stopwatch()..start();
    setState(() {
      _isFittingNow = true;
      _resultImageUrl = null;
      _currentTaskId = null;
      _latency = null;
    });

    try {
      final reqResp = await _fittingRepository.requestFitting(
        userImage: _selectedUserImage!,
        topImage: _selectedTopFile!,
        bottomImage: _selectedBottomFile,
      );

      if (reqResp.data == null) throw Exception("서버 응답 오류");

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
          if (mounted) setState(() => _currentTaskId = taskId);
          break;
        } else if (statusData.status == 'FAILED') {
          throw Exception('피팅 실패');
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
          _latency =
          "${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s";
        });
      }
    }
  }

  /// 피팅 결과 닫기 — DELETE 호출 후 화면 초기화
  Future<void> _closeFittingResult() async {
    final taskId = _currentTaskId;
    if (taskId == null) return;
    try {
      await _fittingRepository.deleteFittingResult(taskId: taskId);
      if (mounted) {
        setState(() {
          _resultImageUrl = null;
          _currentTaskId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피팅 결과를 닫았습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닫기 실패: $e')),
        );
      }
    }
  }

  /// 피팅 결과 옷장 저장 — PATCH 호출
  Future<void> _saveFittingToWardrobe() async {
    final taskId = _currentTaskId;
    if (taskId == null) return;
    try {
      final resp = await _fittingRepository.saveFittingToWardrobe(taskId: taskId);
      if (mounted) {
        if (resp.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('옷장에 저장되었습니다.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  /// 피팅 결과를 새 코디 폴더에 저장 — POST /clothes-sets/save
  Future<void> _saveToFolder() async {
    final taskId = _currentTaskId;
    if (taskId == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('폴더에 저장'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '폴더 이름 (예: 데이트룩)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final resp = await _clothesSetRepository.saveClothesSet(
        SaveClothesSetRequest(setName: name, fittingTaskId: taskId),
      );
      if (mounted) {
        if (resp.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 폴더에 저장되었습니다.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message)),
          );
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _folderSaveErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('폴더 저장 실패: $msg')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 저장 실패: $e')),
        );
      }
    }
  }

  /// 폴더 저장 API 예외 → 사용자용 메시지 (500은 서버 쪽 점검 필요)
  String _folderSaveErrorMessage(DioException e) {
    final status = e.response?.statusCode;
    if (status == 500) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return '${data['message']} (서버 오류)';
      }
      return '서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
    if (status == 400) return '잘못된 요청이에요.';
    if (status == 401) return '다시 로그인해주세요.';
    if (status != null) return '오류가 발생했어요. (${status})';
    return e.message ?? '네트워크 오류';
  }

  /// 피팅 결과 이미지를 전체 화면으로 표시 (결과 있을 때만 호출)
  void _openResultImageFullScreen() {
    final url = _resultImageUrl;
    if (url == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FullScreenImageView(imageUrl: url),
    );
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
    final bool hasTop = _selectedTopFile != null || _selectedTopUrl != null;
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

    final bool hasResult = _resultImageUrl != null && _currentTaskId != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: hasResult
          ? _ResultActionBar(
              latencyText: _latency != null ? '$_latency 소요' : null,
              onClose: _closeFittingResult,
              onSave: _saveFittingToWardrobe,
              onSaveToFolder: _saveToFolder,
            )
          : _BottomCtaBar(
              isReady: isReady,
              isLoading: _isFittingNow,
              buttonText: buttonText,
              helperText: (!_isFittingNow && !isReady) ? buttonText : null,
              latencyText: _latency != null ? '$_latency 소요' : null,
              onPressed: (_isFittingNow || !isReady) ? null : _startVirtualFitting,
            ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const FittingRoomHeader(),
              const SizedBox(height: 20),

              // ✅ [핵심] 모든 피팅 관련 UI가 이 위젯 하나로 통합됨
              FittingMainStage(
                mainImagePath: _resultImageUrl ??
                    _selectedUserImage?.path ??
                    'asset/img/fitting1.jpg',
                isLoading: _isFittingNow,

                // 피팅 결과일 때 탭 → 크게 보기, 아니면 전신 사진 선택
                onUserImageTap: _resultImageUrl != null
                    ? _openResultImageFullScreen
                    : _pickUserImage,

                // 상의 선택 로직
                topImageFile: _selectedTopFile,
                topImageUrl: _selectedTopUrl,
                onTopTap: () => showAddClothingBottomSheet(
                  context,
                  '상의',
                  onWardrobeTap: () => _openWardrobePicker('TOP'),
                  onImageSelected: (file) {
                    setState(() {
                      _selectedTopFile = file;
                      _selectedTopUrl = null;
                    });
                  },
                ),

                // 하의 선택 로직
                bottomImageFile: _selectedBottomFile,
                bottomImageUrl: _selectedBottomUrl,
                onBottomTap: () => showAddClothingBottomSheet(
                  context,
                  '하의',
                  onWardrobeTap: () => _openWardrobePicker('BOTTOM'),
                  onImageSelected: (file) {
                    setState(() {
                      _selectedBottomFile = file;
                      _selectedBottomUrl = null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "좌측 이미지를 탭하여 전신 사진을 변경하세요",
                  style: TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
              AiStylistInput(controller: _promptController, chips: _quickChips),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

/// 피팅 결과 표시 시 하단 액션: 닫기 / 저장하기 / 폴더에 저장
class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({
    this.latencyText,
    required this.onClose,
    required this.onSave,
    this.onSaveToFolder,
  });

  final String? latencyText;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback? onSaveToFolder;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (latencyText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.SUCCESS_COLOR,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        latencyText!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.SUCCESS_COLOR,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.MEDIUM_GREY,
                        side: const BorderSide(color: AppColors.BORDER_COLOR),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.PRIMARYCOLOR,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('저장하기'),
                    ),
                  ),
                ],
              ),
              if (onSaveToFolder != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: onSaveToFolder,
                    icon: const Icon(Icons.folder_outlined, size: 18),
                    label: const Text('폴더에 저장'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.PRIMARYCOLOR,
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

// 하단 버튼 (이전과 동일하지만 코드는 포함해둠)
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
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (helperText != null || latencyText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        latencyText != null
                            ? Icons.timer_outlined
                            : Icons.info_outline,
                        size: 14,
                        color: latencyText != null
                            ? AppColors.SUCCESS_COLOR
                            : AppColors.MEDIUM_GREY,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        latencyText ?? helperText!,
                        style: TextStyle(
                          fontSize: 13,
                          color: latencyText != null
                              ? AppColors.SUCCESS_COLOR
                              : AppColors.MEDIUM_GREY,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: onPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: (isReady && !isLoading)
                        ? AppColors.PRIMARYCOLOR
                        : AppColors.BORDER_COLOR,
                    boxShadow: (isReady && !isLoading)
                        ? [
                      BoxShadow(
                        color: AppColors.PRIMARYCOLOR.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                        : [],
                  ),
                  child: Center(
                    child: isLoading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white)),
                        SizedBox(width: 12),
                        Text("스타일 분석 중...",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isReady
                                ? Icons.auto_awesome
                                : Icons.checkroom,
                            color: isReady
                                ? Colors.white
                                : AppColors.MEDIUM_GREY),
                        const SizedBox(width: 10),
                        Text(
                          buttonText,
                          style: TextStyle(
                              color: isReady
                                  ? Colors.white
                                  : AppColors.MEDIUM_GREY,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ],
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

/// 피팅 결과 이미지 전체 화면 뷰어 (다이얼로그용)
class _FullScreenImageView extends StatelessWidget {
  const _FullScreenImageView({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}