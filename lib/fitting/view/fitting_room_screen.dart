import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/model/fitting_profile.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import '../component/fitting_onboarding_sheet.dart';
import '../component/fitting_room_header.dart';
import '../component/fitting_main_stage.dart';
import '../component/ai_stylist_input.dart';
import '../component/add_clothing_sheet.dart';
import '../component/wardrobe_picker_sheet.dart';

/// 피팅 진행 상태를 화면(탭) 전환과 무관하게 유지. 탭을 떠났다 와도 로딩/결과가 유지됨.
class _FittingProgressHolder extends ChangeNotifier {
  bool isFittingNow = false;
  String? resultImageUrl;
  int? currentTaskId;
  String? latency;

  void setRunning() {
    isFittingNow = true;
    resultImageUrl = null;
    currentTaskId = null;
    latency = null;
    notifyListeners();
  }

  void setResult({
    required int taskId,
    required String url,
    String? latencySec,
  }) {
    isFittingNow = false;
    currentTaskId = taskId;
    resultImageUrl = url;
    latency = latencySec;
    notifyListeners();
  }

  void setStopped({String? latencySec}) {
    isFittingNow = false;
    latency = latencySec;
    notifyListeners();
  }

  void clearResult() {
    resultImageUrl = null;
    currentTaskId = null;
    notifyListeners();
  }
}

class FittingRoomScreen extends StatefulWidget {
  const FittingRoomScreen({super.key});

  /// 피팅룸 탭 선택 시 RootTab에서 호출. 마이페이지 수정 반영용
  static void Function()? onFittingTabSelected;

  /// 홈에서 "추천" 또는 검색바 탭 시 true로 설정 → 탭 전환 후 AI 스타일리스트 세그먼트로 전환
  static bool requestOpenAiStylist = false;

  /// 탭 전환 시에도 피팅 진행/결과 상태 유지용 (화면 바깥 보관)
  static final _FittingProgressHolder _fittingProgress =
      _FittingProgressHolder();

  @override
  State<FittingRoomScreen> createState() => _FittingRoomScreenState();
}

class _FittingRoomScreenState extends State<FittingRoomScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => FittingRoomScreen._fittingProgress.isFittingNow;

  late FittingRepository _fittingRepository;
  late ClothesRepository _clothesRepository;
  late ClothesSetRepository _clothesSetRepository;

  /// 화면 표시용은 holder에서 읽음. (탭 전환 후 복귀 시에도 동기화)
  _FittingProgressHolder get _progress => FittingRoomScreen._fittingProgress;

  File? _selectedUserImage;
  File? _selectedTopFile;
  File? _selectedBottomFile;

  String? _selectedTopUrl;
  String? _selectedBottomUrl;

  final TextEditingController _promptController = TextEditingController();
  late AnimationController _animationController;

  List<ClothesModel> _serverClothes = [];

  /// 헤더용: 서버 마이페이지 + 로컬 피팅 프로필 (피팅 탭 선택 시 갱신)
  UserMe? _userMeForHeader;
  FittingProfile? _fittingProfileForHeader;

  final List<Map<String, dynamic>> _quickChips = [
    {'icon': Icons.business, 'label': '오피스룩 추천해줘'},
    {'icon': Icons.flight_takeoff, 'label': '여행 갈 때 뭐 입지?'},
    {'icon': Icons.favorite, 'label': '데이트 룩 추천해줘'},
  ];

  /// 상단 토글: true = 피팅룸, false = AI 스타일리스트
  bool _isFittingRoomTab = true;

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onFittingProgressChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _initServices();
    FittingRoomScreen.onFittingTabSelected = _loadHeaderUserInfo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _showOnboardingIfNeeded();
          _loadHeaderUserInfo();
        }
      });
    });
  }

  void _onFittingProgressChanged() {
    if (mounted) setState(() {});
  }

  /// 서버 GET /users/me + 로컬 FittingProfile + 스토리지 닉네임 → 헤더 반영
  Future<void> _loadHeaderUserInfo() async {
    try {
      final authDio = createAuthDio();
      final authRepo = AuthRepository(Dio(), baseUrl: baseUrl);
      final me = await authRepo.getMe(authDio);
      final profile = await FittingProfile.load();
      if (mounted) {
        final openAiStylist = FittingRoomScreen.requestOpenAiStylist;
        if (openAiStylist) FittingRoomScreen.requestOpenAiStylist = false;
        setState(() {
          _userMeForHeader = me;
          _fittingProfileForHeader = profile;
          if (openAiStylist) _isFittingRoomTab = false;
        });
      }
    } catch (_) {}
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
    _progress.removeListener(_onFittingProgressChanged);
    FittingRoomScreen.onFittingTabSelected = null;
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

  /// 전신 사진 선택: 하단 시트 → 사진 촬영 / 갤러리 / 내 피팅 프로필 불러오기
  Future<void> _pickUserImage() async {
    final result = await showModalBottomSheet<String>(
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
                '전신 사진 선택',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.BLACK,
                ),
              ),
              const SizedBox(height: 16),
              _userImageSourceTile(
                context: ctx,
                icon: Icons.camera_alt_outlined,
                label: '사진 촬영하기',
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.BORDER_COLOR),
              ),
              _userImageSourceTile(
                context: ctx,
                icon: Icons.photo_library_outlined,
                label: '갤러리에서 선택',
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.BORDER_COLOR),
              ),
              _userImageSourceTile(
                context: ctx,
                icon: Icons.person_outline_rounded,
                label: '내 피팅 프로필 불러오기',
                onTap: () => Navigator.pop(ctx, 'profile'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result == 'profile') {
      final profile = await FittingProfile.load();
      final path = profile?.frontImagePath;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync() && mounted) {
          setState(() => _selectedUserImage = file);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('피팅 프로필의 전신 사진을 불러왔어요.')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '저장된 전신 사진 파일을 찾을 수 없어요. 유저 탭에서 피팅 프로필을 다시 등록해주세요.',
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장된 피팅 프로필이 없어요. 유저 탭에서 정면 사진을 등록해주세요.'),
          ),
        );
      }
      return;
    }

    final source = result == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null && mounted) {
      setState(() => _selectedUserImage = File(image.path));
    }
  }

  Widget _userImageSourceTile({
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

  Future<void> _selectCloth(ClothesModel cloth) async {
    if (cloth.imgUrl == null) return;

    final imageUrl = cloth.imgUrl!;
    final category = cloth.category?.toUpperCase() ?? "";
    final isTop =
        category.contains("TOP") ||
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
        if (isTop) {
          _selectedTopFile = File(tempPath);
        } else {
          _selectedBottomFile = File(tempPath);
        }
      });
    } catch (e) {
      debugPrint("이미지 다운로드 에러: $e");
    }
  }

  /// AI 스타일리스트 추천 코디를 피팅룸에 적용 (상의/하의 ID → 옷 조회 후 다운로드해 선택)
  Future<void> _applyRecommendationOutfit(int? topId, int? bottomId) async {
    if (topId == null && bottomId == null) return;
    try {
      ClothesModel? topCloth;
      ClothesModel? bottomCloth;
      if (topId != null) {
        final resp = await _clothesRepository.getClothDetail(id: topId);
        if (resp.success && resp.data != null) {
          topCloth = resp.data;
        }
      }
      if (bottomId != null) {
        final resp = await _clothesRepository.getClothDetail(id: bottomId);
        if (resp.success && resp.data != null) {
          bottomCloth = resp.data;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final dio = Dio();

      if (topCloth?.imgUrl != null && topCloth!.imgUrl!.trim().isNotEmpty) {
        final path =
            '${tempDir.path}/rec_top_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await dio.download(topCloth.imgUrl!, path);
        if (!mounted) return;
        setState(() {
          _selectedTopUrl = topCloth!.imgUrl;
          _selectedTopFile = File(path);
        });
      }
      if (bottomCloth?.imgUrl != null &&
          bottomCloth!.imgUrl!.trim().isNotEmpty) {
        final path =
            '${tempDir.path}/rec_bottom_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await dio.download(bottomCloth.imgUrl!, path);
        if (!mounted) return;
        setState(() {
          _selectedBottomUrl = bottomCloth!.imgUrl;
          _selectedBottomFile = File(path);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이 코디가 선택되었어요. 전신 사진을 고른 뒤 "가상 피팅 시작하기"를 눌러주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("추천 코디 적용 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('코디를 불러오는 데 실패했어요. 옷장에 해당 옷이 있는지 확인해주세요.'),
          ),
        );
      }
    }
  }

  Future<void> _startVirtualFitting() async {
    if (_selectedUserImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전신 사진을 선택해주세요.')));
      return;
    }

    // (이미지 다운로드 및 예외 처리 로직은 기존과 동일)
    if (_selectedTopFile == null && _selectedTopUrl != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/top_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(_selectedTopUrl!, path);
        if (mounted) setState(() => _selectedTopFile = File(path));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상의 이미지를 불러오는 데 실패했어요. 다시 선택해주세요.')),
          );
        }
        return;
      }
    }
    if (_selectedBottomFile == null && _selectedBottomUrl != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/bottom_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(_selectedBottomUrl!, path);
        if (mounted) setState(() => _selectedBottomFile = File(path));
      } catch (_) {}
    }
    if (_selectedTopFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상의를 선택해주세요.')));
      return;
    }

    final stopwatch = Stopwatch()..start();
    _progress.setRunning();

    int? taskIdForPolling;
    try {
      // 1. 서버에 가상 피팅 작업을 지시하고 Task ID를 받아옵니다.
      final reqResp = await _fittingRepository.requestFitting(
        userImage: _selectedUserImage!,
        topImage: _selectedTopFile!,
        bottomImage: _selectedBottomFile,
      );

      if (reqResp.data == null) throw Exception("서버 응답 오류 (Task ID 없음)");
      final taskId = reqResp.data!.taskId;
      taskIdForPolling = taskId;

      debugPrint(" [SSE 연결 시도] Task ID: $taskId");

      // 2. SSE 통신을 위한 Completer 생성 (스트림이 끝날 때까지 여기서 함수 진행을 멈추고 기다리게 만듦)
      final completer = Completer<String?>();

      // 3. 인증 토큰이 포함된 Dio 객체를 생성하여 스트림(Stream) 방식으로 GET 요청을 엽니다.
      final dio = createAuthDio(); // (인터셉터가 포함된 공통 Dio 사용)
      final response = await dio.get<ResponseBody>(
        '$baseUrl/api/v1/virtual-fitting/$taskId/stream',
        options: Options(
          headers: {
            'Accept': 'text/event-stream',
          }, // 나는 SSE 스트림을 받을 준비가 되었다고 서버에 알림
          responseType:
              ResponseType.stream, // 한 번에 받지 않고 조각(Chunk) 단위로 계속 받겠다고 선언
          receiveTimeout: const Duration(
            minutes: 2,
          ), // 2분 동안 서버에서 아무 말도 없으면 연결 끊기
        ),
      );

      // 4. 파이프(Stream)로 들어오는 바이트 데이터를 우리가 읽을 수 있는 글자(String)로 변환하며 대기합니다.
      final streamSubscription = response.data!.stream
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
            (String line) {
              // 서버에서 데이터 조각이 날아올 때마다 이 부분이 실행됩니다.
              if (line.trim().isEmpty) return; // 빈 줄은 무시

              debugPrint(" [SSE 수신] $line");

              // SSE 표준 규격은 실제 데이터 앞에 "data:" 를 붙여서 보냅니다.
              if (line.startsWith('data:')) {
                final dataStr = line.substring(5).trim();
                if (dataStr.isEmpty) return;

                try {
                  // 백엔드가 넘겨준 JSON 스트링을 Map으로 파싱합니다.
                  final jsonData = jsonDecode(dataStr) as Map<String, dynamic>;
                  // 서버가 { "data": { "status": ... } } 형식으로 감싸서 보낼 수도 있고
                  // { "status": ... } 형식으로 직접 보낼 수도 있으므로 양쪽 지원
                  final payload = (jsonData['data'] is Map<String, dynamic>)
                      ? jsonData['data'] as Map<String, dynamic>
                      : jsonData;
                  final status = payload['status']?.toString().toUpperCase();

                  if (status == 'COMPLETED') {
                    final resultUrl = payload['resultImgUrl']?.toString();
                    if (resultUrl != null && resultUrl.isNotEmpty) {
                      if (!completer.isCompleted) {
                        completer.complete(resultUrl);
                      }
                    } else {
                      // URL이 없으면 폴링 폴백이 트리거되도록 동일한 패턴의 메시지 사용
                      if (!completer.isCompleted) {
                        completer.completeError(
                          Exception('결과를 받기 전에 서버 연결이 종료되었습니다. (URL 없음)'),
                        );
                      }
                    }
                  } else if (status == 'FAILED') {
                    if (!completer.isCompleted) {
                      completer.completeError(
                        Exception('백엔드 피팅 처리 실패 (FAILED)'),
                      );
                    }
                  }
                  // WAITING 이나 PROCESSING 이면 아무것도 안 하고 다음 조각이 올 때까지 계속 기다립니다.
                } catch (parseError) {
                  debugPrint("⚠ [SSE 파싱 에러] 무시하고 계속 대기: $parseError");
                }
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.completeError(Exception('스트림 연결 오류: $error'));
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.completeError(Exception('결과를 받기 전에 서버 연결이 종료되었습니다.'));
              }
            },
          );

      // 5. Completer가 complete 될 때까지(즉, COMPLETED나 FAILED가 떨어질 때까지) 여기서 멈춰서 기다립니다.
      final finalUrl = await completer.future;

      // 6. 결과가 무사히 도착하면 파이프를 안전하게 닫고 화면을 업데이트합니다.
      await streamSubscription.cancel();

      stopwatch.stop();
      final latencySec =
          "${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s";
      if (finalUrl != null) {
        _progress.setResult(
          taskId: taskId,
          url: finalUrl,
          latencySec: latencySec,
        );
        debugPrint(" [SSE 완료] 화면 업데이트: $finalUrl");
      } else {
        _progress.setStopped(latencySec: latencySec);
      }
    } catch (e) {
      stopwatch.stop();
      final isConnectionClosed =
          e.toString().contains('서버 연결이 종료') ||
          e.toString().contains('결과를 받기 전에') ||
          e.toString().contains('스트림 연결 오류') ||
          e.toString().contains('Connection closed');

      if (isConnectionClosed) {
        // SSE가 끊겼을 때 상태 API로 폴링해서 결과 복구 시도
        final taskId = taskIdForPolling;
        if (taskId != null) {
          try {
            final polledUrl = await _pollFittingResult(taskId);
            final latencySec =
                "${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s";
            if (polledUrl != null && polledUrl.isNotEmpty) {
              _progress.setResult(
                taskId: taskId,
                url: polledUrl,
                latencySec: latencySec,
              );
              debugPrint(" [폴링 복구] 결과 수신: $polledUrl");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('연결이 끊어졌지만 결과를 불러왔어요.')),
                );
              }
              return;
            }
          } catch (_) {
            debugPrint(" [폴링 복구 실패]");
          }
        }
      }

      _progress.setStopped(
        latencySec:
            "${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s",
      );
      if (mounted) {
        debugPrint(" [피팅 에러 발생] $e");
        final msg = e.toString().contains('피팅 실패')
            ? '피팅에 실패했어요. 전신 사진과 옷 사진이 선명한지 확인한 뒤 다시 시도해주세요.'
            : '오류 발생: ${e.toString().replaceAll('Exception: ', '')}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  /// SSE 연결이 끊겼을 때 상태 API를 주기적으로 호출해 결과 URL 복구 (최대 약 1분)
  Future<String?> _pollFittingResult(int taskId) async {
    const maxAttempts = 30;
    const interval = Duration(seconds: 2);

    for (var i = 0; i < maxAttempts; i++) {
      if (i > 0) await Future<void>.delayed(interval);
      if (!mounted) return null;
      try {
        final resp = await _fittingRepository.checkStatus(taskId: taskId);
        final data = resp.data;
        if (data == null) continue;
        final status = data.status.toUpperCase();
        if (status == 'COMPLETED') {
          final url = data.resultImgUrl?.trim();
          if (url != null && url.isNotEmpty) return url;
        }
        if (status == 'FAILED') {
          throw Exception('백엔드 피팅 처리 실패 (FAILED)');
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('FAILED')) rethrow;
        debugPrint("⏳ [폴링 ${i + 1}/$maxAttempts] 대기 중...");
      }
    }
    throw Exception('시간이 지나도 결과를 받지 못했어요.');
  }

  /// 피팅 결과 닫기 — DELETE 호출 후 화면 초기화
  Future<void> _closeFittingResult() async {
    final taskId = _progress.currentTaskId;
    if (taskId == null) return;
    try {
      await _fittingRepository.deleteFittingResult(taskId: taskId);
      _progress.clearResult();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('피팅 결과를 닫았습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('닫기 실패: $e')));
      }
    }
  }

  /// 피팅 결과 옷장 저장 — PATCH 호출
  Future<void> _saveFittingToWardrobe() async {
    final taskId = _progress.currentTaskId;
    if (taskId == null) return;
    try {
      final resp = await _fittingRepository.saveFittingToWardrobe(
        taskId: taskId,
      );
      if (mounted) {
        if (resp.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('옷장에 저장되었습니다.')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(resp.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  /// 피팅 결과를 새 코디 폴더에 저장 — POST /clothes-sets/save
  Future<void> _saveToFolder() async {
    final taskId = _progress.currentTaskId;
    if (taskId == null) return;
    final name = await AppDialog.prompt(
      context: context,
      title: '폴더에 저장',
      hintText: '폴더 이름 (예: 데이트룩)',
      confirmLabel: '저장',
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final resp = await _clothesSetRepository.saveClothesSet(
        SaveClothesSetRequest(setName: name, fittingTaskId: taskId),
      );
      if (mounted) {
        if (resp.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('새 폴더에 저장되었습니다.')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(resp.message)));
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _folderSaveErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('폴더 저장 실패: $msg')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('폴더 저장 실패: $e')));
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
    if (status != null) return '오류가 발생했어요. ($status)';
    return e.message ?? '네트워크 오류';
  }

  /// 피팅 결과 이미지를 전체 화면으로 표시 (결과 있을 때만 호출)
  void _openResultImageFullScreen() {
    final url = _progress.resultImageUrl;
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
    super.build(context); // AutomaticKeepAliveClientMixin
    final bool hasUser = _selectedUserImage != null;
    final bool hasTop = _selectedTopFile != null || _selectedTopUrl != null;
    final bool isReady = hasUser && hasTop;

    String buttonText;
    if (_progress.isFittingNow) {
      buttonText = "스타일 분석 중...";
    } else if (isReady) {
      buttonText = "가상 피팅 시작하기";
    } else if (!hasUser) {
      buttonText = "전신 사진을 선택하세요";
    } else {
      buttonText = "상의를 선택하세요";
    }

    final bool hasResult =
        _progress.resultImageUrl != null && _progress.currentTaskId != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: hasResult
          ? _ResultActionBar(
              latencyText: _progress.latency != null
                  ? '${_progress.latency} 소요'
                  : null,
              onClose: _closeFittingResult,
              onSave: _saveFittingToWardrobe,
              onSaveToFolder: _saveToFolder,
            )
          : _isFittingRoomTab
          ? _BottomCtaBar(
              isReady: isReady,
              isLoading: _progress.isFittingNow,
              buttonText: buttonText,
              helperText: (!_progress.isFittingNow && !isReady)
                  ? buttonText
                  : null,
              latencyText: _progress.latency != null
                  ? '${_progress.latency} 소요'
                  : null,
              onPressed: (_progress.isFittingNow || !isReady)
                  ? null
                  : _startVirtualFitting,
            )
          : null,
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                FittingRoomHeader(
                  leading: _FittingRoomSegmentedControl(
                    selectedIndex: _isFittingRoomTab ? 0 : 1,
                    onChanged: (index) {
                      setState(() => _isFittingRoomTab = (index == 0));
                    },
                  ),
                  heightLabel: _userMeForHeader?.height != null
                      ? _userMeForHeader!.height!.toStringAsFixed(0)
                      : null,
                  sizeLabel: _fittingProfileForHeader?.topSize,
                ),
                const SizedBox(height: 20),

                // 피팅룸 탭: 전신+상하의 선택 / AI 탭: 스타일리스트 입력만
                if (_isFittingRoomTab) ...[
                  FittingMainStage(
                    mainImagePath:
                        _progress.resultImageUrl ??
                        _selectedUserImage?.path ??
                        'asset/img/fitting1.jpg',
                    isLoading: _progress.isFittingNow,

                    // 피팅 결과일 때 탭 → 크게 보기, 아니면 전신 사진 선택
                    onUserImageTap: _progress.resultImageUrl != null
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
                      style: TextStyle(
                        color: AppColors.MEDIUM_GREY,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ] else ...[
                  AiStylistInput(
                    controller: _promptController,
                    chips: _quickChips,
                    onTryOnOutfit: _applyRecommendationOutfit,
                  ),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 세그먼트: 피팅룸 | AI 스타일리스트 (토글 스타일, 중앙 정렬)
class _FittingRoomSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FittingRoomSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.INPUT_BG_COLOR,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.BORDER_COLOR),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: '피팅룸',
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _Segment(
              label: 'AI 스타일리스트',
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _selectedBg = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.MEDIUM_GREY,
            ),
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
                            ),
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
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "스타일 분석 중...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isReady ? Icons.auto_awesome : Icons.checkroom,
                                color: isReady
                                    ? Colors.white
                                    : AppColors.MEDIUM_GREY,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                buttonText,
                                style: TextStyle(
                                  color: isReady
                                      ? Colors.white
                                      : AppColors.MEDIUM_GREY,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
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
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
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
              style: IconButton.styleFrom(backgroundColor: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }
}
