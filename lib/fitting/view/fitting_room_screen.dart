import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/fitting/provider/fitting_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/home/view/home_screen.dart'
    show SectionHeader, SavedOutfitRack;
import '../component/fitting_main_stage.dart';
import '../component/add_clothing_sheet.dart';
import '../component/wardrobe_picker_sheet.dart';
import '../component/fit_type_selector_sheet.dart';
import '../model/fit_type.dart';
import '../util/clothes_category_util.dart';

/// 피팅 입력 모드: 아이템 조합 (상의/하의 선택) vs 스타일 사진 (참조 룩 사진)
enum _FittingMode { itemCombination, stylePhoto }

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
    latency = null;
    notifyListeners();
  }
}

class FittingRoomScreen extends ConsumerStatefulWidget {
  const FittingRoomScreen({super.key});

  /// 피팅룸 탭 선택 시 RootTab에서 호출. 마이페이지 수정 반영용
  static void Function()? onFittingTabSelected;

  /// 홈에서 "추천" 또는 검색바 탭 시 true로 설정 → 탭 전환 후 AI 스타일리스트 세그먼트로 전환
  static bool requestOpenAiStylist = false;

  /// 탭 전환 시에도 피팅 진행/결과 상태 유지용 (화면 바깥 보관)
  static final _FittingProgressHolder _fittingProgress =
      _FittingProgressHolder();

  @override
  ConsumerState<FittingRoomScreen> createState() => _FittingRoomScreenState();
}

class _FittingRoomScreenState extends ConsumerState<FittingRoomScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => FittingRoomScreen._fittingProgress.isFittingNow;

  late FittingRepository _fittingRepository;
  late ClothesRepository _clothesRepository;
  late ClothesSetRepository _clothesSetRepository;

  /// 화면 표시용은 holder에서 읽음. (탭 전환 후 복귀 시에도 동기화)
  _FittingProgressHolder get _progress => FittingRoomScreen._fittingProgress;

  _FittingMode _mode = _FittingMode.itemCombination;

  File? _selectedUserImage;
  File? _selectedTopFile;
  File? _selectedBottomFile;
  File? _selectedStyleImage;

  String? _selectedTopUrl;
  String? _selectedBottomUrl;

  int? _selectedTopClothesId;
  int? _selectedBottomClothesId;

  FitType _selectedTopFit = FitType.regular;
  FitType _selectedBottomFit = FitType.regular;

  List<ClothesModel> _serverClothes = [];

  List<SavedFittingData> _savedOutfits = [];
  bool _loadingOutfits = true;

  /// 헤더용: 서버 마이페이지 + 로컬 피팅 프로필 (피팅 탭 선택 시 갱신)

  /// 상단 토글: true = 피팅룸, false = AI 스타일리스트

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onFittingProgressChanged);
    _initServices();
    _loadSavedOutfits();
    FittingRoomScreen.onFittingTabSelected = () {
      _loadHeaderUserInfo();
      _loadWardrobe();
      _loadSavedOutfits();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHeaderUserInfo();
    });
  }

  Future<void> _loadSavedOutfits() async {
    try {
      final dio = createAuthDio();
      final repo = FittingRepository(dio, baseUrl: baseUrl);
      final resp = await repo.getMyCloset();
      if (!mounted) return;
      setState(() {
        _savedOutfits = (resp.data ?? []).reversed.toList();
        _loadingOutfits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOutfits = false);
    }
  }

  void _onFittingProgressChanged() {
    if (mounted) setState(() {});
  }

  /// 서버 GET /users/me + 로컬 FittingProfile + 스토리지 닉네임 → 헤더 반영
  Future<void> _loadHeaderUserInfo() async {
    try {
      final authDio = createAuthDio();
      final authRepo = AuthRepository(Dio(), baseUrl: baseUrl);
      await authRepo.getMe(authDio);
      if (mounted) {
        if (FittingRoomScreen.requestOpenAiStylist) {
          FittingRoomScreen.requestOpenAiStylist = false;
        }
      }
    } catch (_) {}
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
    super.dispose();
  }

  Future<void> _loadWardrobe() async {
    try {
      final resp = await _clothesRepository.getClothesList();
      if (resp.success && mounted) {
        setState(() => _serverClothes = resp.data ?? []);
      }
    } catch (e) {
      debugPrint("⚠️ 피팅룸 _loadWardrobe 에러: $e");
    }
  }

  /// 전신 사진 선택: 통합 AddClothingSheet → 촬영 / 갤러리 / 내 피팅프로필 불러오기
  Future<void> _pickUserImage() async {
    showAddClothingBottomSheet(
      context,
      '전신',
      onWardrobeTap: () {},
      onImageSelected: (file) {
        if (mounted) setState(() => _selectedUserImage = file);
      },
      onProfileTap: () async {
        try {
          final authDio = createAuthDio();
          final authRepo = AuthRepository(Dio(), baseUrl: baseUrl);
          final userInfo = await authRepo.getMe(authDio);
          final profileImageUrl = userInfo?.profileImageUrl?.trim();

          if (profileImageUrl == null || profileImageUrl.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('등록된 프로필 사진이 없어요. 유저 탭에서 사진을 먼저 등록해주세요.'),
                ),
              );
            }
            return;
          }

          final tempDir = await getTemporaryDirectory();
          final tempPath =
              '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await Dio().download(profileImageUrl, tempPath);

          if (mounted) {
            setState(() => _selectedUserImage = File(tempPath));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('피팅 프로필의 전신 사진을 불러왔어요.')),
            );
          }
        } catch (e) {
          debugPrint("⚠️ 서버 프로필 이미지 다운로드 실패: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('네트워크 오류로 사진을 불러오지 못했어요. 잠시 후 다시 시도해주세요.'),
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _selectCloth(ClothesModel cloth) async {
    if (cloth.imgUrl == null) return;

    final imageUrl = cloth.imgUrl!;
    final isTop = isTopCategory(cloth.category);

    // Step 1: Ask fit type FIRST — do NOT update state yet.
    final fit = await FitTypeSelectorSheet.show(
      context,
      title: isTop ? '상의 핏 선택' : '하의 핏 선택',
      isTop: isTop,
    );
    // Step 2: If user cancelled, discard the selection entirely.
    if (fit == null || !mounted) return;

    // Step 3: Fit type confirmed — now update state atomically.
    setState(() {
      if (isTop) {
        _selectedTopUrl = imageUrl;
        _selectedTopFile = null;
        _selectedTopClothesId = cloth.id;
        _selectedTopFit = fit;
      } else {
        _selectedBottomUrl = imageUrl;
        _selectedBottomFile = null;
        _selectedBottomClothesId = cloth.id;
        _selectedBottomFit = fit;
      }
    });

    // Download the image file in the background for later multipart upload.
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

  /// Show fit type selector and return the chosen value.
  /// Returns null if the user cancelled.
  Future<FitType?> _promptFitTypeFor({required bool isTop}) async {
    final fit = await FitTypeSelectorSheet.show(
      context,
      title: isTop ? '상의 핏 선택' : '하의 핏 선택',
      isTop: isTop,
    );
    return fit;
  }

  Future<void> _pickStyleImage() async {
    showAddClothingBottomSheet(
      context,
      '스타일',
      onWardrobeTap: _openStyleWardrobePicker,
      onImageSelected: (file) {
        if (mounted) setState(() => _selectedStyleImage = file);
      },
    );
  }

  /// 스타일 모드 전용 옷장 피커 — 카테고리 'STYLE'을 넘겨 전체 옷장/북마크 노출
  void _openStyleWardrobePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WardrobePickerSheet(
        clothes: _serverClothes,
        onClothSelected: _selectStyleCloth,
        category: 'STYLE',
      ),
    );
  }

  Future<void> _selectStyleCloth(ClothesModel cloth) async {
    if (cloth.imgUrl == null) return;
    final imageUrl = cloth.imgUrl!;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/style_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(imageUrl, tempPath);
      if (!mounted) return;
      setState(() => _selectedStyleImage = File(tempPath));
    } catch (e) {
      debugPrint("스타일 이미지 다운로드 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스타일 이미지를 불러오지 못했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  void _switchMode(_FittingMode mode) {
    if (_mode == mode || _progress.isFittingNow) return;
    setState(() => _mode = mode);
  }

  /// CTA: 아이템별로 미리 선택된 핏감을 사용해 바로 피팅 시작
  Future<void> _onCtaPressed() async {
    await _startVirtualFitting();
  }

  Future<void> _startVirtualFitting() async {
    if (_selectedUserImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전신 사진을 선택해주세요.')));
      return;
    }

    if (_mode == _FittingMode.stylePhoto) {
      if (_selectedStyleImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('입혀볼 스타일 사진을 선택해주세요.')),
        );
        return;
      }
    } else {
      // 아이템 모드: 옷장에서 고른 URL은 임시 파일로 다운로드 후 multipart에 실음
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
    }

    final stopwatch = Stopwatch()..start();
    _progress.setRunning();

    int? taskIdForPolling;
    try {
      // 모드별 API 분기 — 응답 타입/Task ID 흐름 동일 → 이후 SSE/폴링 그대로 재사용
      final ApiResponse<FittingRequestData> reqResp;
      if (_mode == _FittingMode.stylePhoto) {
        reqResp = await _fittingRepository.requestStyleFitting(
          userImage: _selectedUserImage!,
          styleImage: _selectedStyleImage!,
        );
      } else {
        reqResp = await _fittingRepository.requestFitting(
          topFitType: _selectedTopFit.apiValue,
          bottomFitType:
              _selectedBottomFile != null ? _selectedBottomFit.apiValue : null,
          userImage: _selectedUserImage!,
          topImage: _selectedTopFile!,
          bottomImage: _selectedBottomFile,
        );
      }

      if (reqResp.data == null) throw Exception("서버 응답 오류 (Task ID 없음)");
      final taskId = reqResp.data!.taskId;
      taskIdForPolling = taskId;

      debugPrint(" [SSE 연결 시도] Task ID: $taskId");

      // 2. SSE 통신을 위한 Completer 생성
      final completer = Completer<String?>();

      // 3. authDio로 SSE 연결 → 401 시 인터셉터가 토큰 자동 갱신 후 재시도.
      final authDio = ref.read(authDioProvider);
      final cancelToken = CancelToken();
      final response = await authDio.get<ResponseBody>(
        '/api/v1/virtual-fitting/$taskId/stream',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            HttpHeaders.acceptHeader: 'text/event-stream',
            'cache-control': 'no-cache',
          },
        ),
      );
      debugPrint(" [SSE] 응답 상태: ${response.statusCode}");

      final byteStream = response.data?.stream;
      if (byteStream == null) {
        throw Exception('SSE 연결 실패 (빈 응답 스트림)');
      }

      // 4. 버퍼 기반 SSE 이벤트 파싱 (\n\n 구분)
      final buffer = StringBuffer();

      final streamSubscription = byteStream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            (String text) {
              if (completer.isCompleted) return;
              debugPrint(" [SSE 수신] ${text.replaceAll('\n', '↵')}");
              buffer.write(text);

              // SSE 이벤트는 빈 줄(\n\n)로 구분
              while (buffer.toString().contains('\n\n')) {
                final full = buffer.toString();
                final splitIdx = full.indexOf('\n\n');
                final eventBlock = full.substring(0, splitIdx);
                buffer.clear();
                buffer.write(full.substring(splitIdx + 2));

                // 이벤트 블록에서 data: 라인 추출
                String? rawData;
                for (final line in eventBlock.split('\n')) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('data:')) {
                    rawData = trimmed.substring(5).trim();
                  }
                }
                if (rawData == null || rawData.isEmpty) continue;

                try {
                  final jsonData = jsonDecode(rawData) as Map<String, dynamic>;
                  final payload = (jsonData['data'] is Map<String, dynamic>)
                      ? jsonData['data'] as Map<String, dynamic>
                      : jsonData;
                  final status = payload['status']?.toString().toUpperCase();

                  if (status == 'COMPLETED') {
                    final resultUrl = payload['resultImgUrl']?.toString();
                    if (resultUrl != null && resultUrl.isNotEmpty) {
                      if (!completer.isCompleted) completer.complete(resultUrl);
                    } else {
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
                } catch (parseError) {
                  debugPrint("⚠ [SSE 파싱 에러] 무시하고 계속 대기: $parseError");
                }
              }
            },
            onError: (Object error) {
              debugPrint(' [SSE] 연결 오류 → 폴링 전환: $error');
              if (completer.isCompleted) return;

              // 버퍼에 \n\n 없이 수신된 부분 데이터도 파싱 시도
              final remaining = buffer.toString().trim();
              if (remaining.isNotEmpty) {
                String? rawData;
                // \n\n 구분 없이 버퍼 전체를 단일 블록으로 파싱
                for (final line in remaining.split('\n')) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('data:')) {
                    rawData = trimmed.substring(5).trim();
                  }
                }
                if (rawData != null && rawData.isNotEmpty) {
                  try {
                    final jsonData =
                        jsonDecode(rawData) as Map<String, dynamic>;
                    final payload = (jsonData['data'] is Map<String, dynamic>)
                        ? jsonData['data'] as Map<String, dynamic>
                        : jsonData;
                    final status = payload['status']?.toString().toUpperCase();
                    if (status == 'COMPLETED') {
                      final resultUrl = payload['resultImgUrl']?.toString();
                      if (resultUrl != null && resultUrl.isNotEmpty) {
                        debugPrint(
                          ' [SSE onError→버퍼 복구] COMPLETED: $resultUrl',
                        );
                        completer.complete(resultUrl);
                        return;
                      }
                    } else if (status == 'FAILED') {
                      debugPrint(' [SSE onError→버퍼 복구] FAILED 확인');
                      completer.completeError(
                        Exception('백엔드 피팅 처리 실패 (FAILED)'),
                      );
                      return;
                    }
                  } catch (parseErr) {
                    debugPrint('⚠ [SSE onError 버퍼 파싱 실패] $parseErr');
                  }
                }
              }

              completer.complete(null); // 버퍼에도 결과 없음 → 폴링 전환
            },
            onDone: () {
              // 버퍼에 남은 데이터 처리
              final remaining = buffer.toString().trim();
              if (remaining.isNotEmpty && !completer.isCompleted) {
                String? rawData;
                for (final line in remaining.split('\n')) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('data:')) {
                    rawData = trimmed.substring(5).trim();
                  }
                }
                if (rawData != null && rawData.isNotEmpty) {
                  try {
                    final jsonData =
                        jsonDecode(rawData) as Map<String, dynamic>;
                    final payload = (jsonData['data'] is Map<String, dynamic>)
                        ? jsonData['data'] as Map<String, dynamic>
                        : jsonData;
                    final status = payload['status']?.toString().toUpperCase();
                    if (status == 'COMPLETED') {
                      final resultUrl = payload['resultImgUrl']?.toString();
                      if (resultUrl != null && resultUrl.isNotEmpty) {
                        completer.complete(resultUrl);
                        return;
                      }
                    }
                  } catch (_) {}
                }
              }
              if (!completer.isCompleted) {
                debugPrint(' [SSE] 결과 없이 종료 → 폴링 전환');
                completer.complete(null); // 에러가 아닌 null로 complete → 폴링 전환
              }
            },
            cancelOnError: false,
          );

      // 5. Completer가 complete 될 때까지 기다립니다.
      final sseUrl = await completer.future;

      // 6. 스트림 정리
      await streamSubscription.cancel();
      if (!cancelToken.isCancelled) cancelToken.cancel();

      // 7. SSE에서 결과를 받았으면 바로 완료, 아니면 폴링 전환
      String? finalUrl = sseUrl;
      if (finalUrl == null || finalUrl.isEmpty) {
        debugPrint(' [SSE→폴링] SSE에서 결과를 못 받아 폴링으로 전환합니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('서버와 연결 중... 잠시만 기다려주세요.')),
          );
        }
        finalUrl = await _pollFittingResult(taskId);
      }

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
        final msg =
            (e.toString().contains('피팅 실패') || e.toString().contains('FAILED'))
            ? '피팅에 실패했어요. 전신 사진과 옷 사진이 선명한지 확인한 뒤 다시 시도해주세요.'
            : '오류 발생: ${e.toString().replaceAll('Exception: ', '')}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  /// SSE 연결이 끊겼을 때 상태 API를 주기적으로 호출해 결과 URL 복구.
  /// 초반엔 자주, 시간이 지날수록 간격을 늘려 서버/네트워크 부담을 줄인다.
  /// 누적 대기 시간이 [_pollMaxDuration]을 넘으면 중단.
  static const _pollMaxDuration = Duration(minutes: 5);
  static const _pollMinInterval = Duration(seconds: 1);
  static const _pollMaxInterval = Duration(seconds: 10);

  Future<String?> _pollFittingResult(int taskId) async {
    final deadline = DateTime.now().add(_pollMaxDuration);
    var interval = _pollMinInterval;
    var attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (attempt > 0) await Future<void>.delayed(interval);
      if (!mounted) return null;
      attempt++;
      try {
        final resp = await _fittingRepository.checkStatus(taskId: taskId);
        final data = resp.data;
        if (data != null) {
          final status = data.status.toUpperCase();
          if (status == 'COMPLETED') {
            final url = data.resultImgUrl?.trim();
            if (url != null && url.isNotEmpty) return url;
          }
          if (status == 'FAILED') {
            throw Exception('백엔드 피팅 처리 실패 (FAILED)');
          }
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('FAILED')) rethrow;
        debugPrint("⏳ [폴링 #$attempt, 다음 ${interval.inSeconds}s] 대기 중...");
      }
      // 1s → 2s → 4s → 8s → 10s(cap) 백오프
      final nextMs = (interval.inMilliseconds * 2).clamp(
        _pollMinInterval.inMilliseconds,
        _pollMaxInterval.inMilliseconds,
      );
      interval = Duration(milliseconds: nextMs);
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
        setState(() {
          _selectedTopFile = null;
          _selectedTopUrl = null;
          _selectedBottomFile = null;
          _selectedBottomUrl = null;
          _selectedStyleImage = null;
        });
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
        setState(() {
          _selectedTopFile = null;
          _selectedTopUrl = null;
          _selectedBottomFile = null;
          _selectedBottomUrl = null;
          _selectedStyleImage = null;
        });
        if (resp.success) {
          _progress.clearResult();
          ref.invalidate(myClosetProvider);
          await AppDialog.success(
            context: context,
            title: '저장 완료',
            content: '옷장에 저장되었습니다.',
          );
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
      final clothesIds = <int>[
        if (_selectedTopClothesId != null) _selectedTopClothesId!,
        if (_selectedBottomClothesId != null) _selectedBottomClothesId!,
      ];
      final resp = await _clothesSetRepository.saveClothesSet(
        SaveClothesSetRequest(
          setName: name,
          fittingTaskId: taskId,
          clothesIds: clothesIds,
        ),
      );
      if (mounted) {
        if (resp.success) {
          _progress.clearResult();
          setState(() {
            _selectedTopFile = null;
            _selectedTopUrl = null;
            _selectedBottomFile = null;
            _selectedBottomUrl = null;
          });
          ref.invalidate(myClosetProvider);
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
    final bool hasStyle = _selectedStyleImage != null;
    final bool isReady = _mode == _FittingMode.itemCombination
        ? (hasUser && hasTop)
        : (hasUser && hasStyle);

    final String helperText;
    if (!hasUser) {
      helperText = "전신 사진을 선택하세요";
    } else if (_mode == _FittingMode.itemCombination) {
      helperText = "상의를 선택하세요";
    } else {
      helperText = "입혀볼 스타일 사진을 선택하세요";
    }

    final bool hasResult =
        _progress.resultImageUrl != null && _progress.currentTaskId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      bottomNavigationBar: hasResult
          ? _ResultActionBar(
              latencyText: _progress.latency != null
                  ? '${_progress.latency} 소요'
                  : null,
              onClose: _closeFittingResult,
              onSave: _saveFittingToWardrobe,
              onSaveToFolder: _saveToFolder,
            )
          : !_progress.isFittingNow
          ? _BottomCtaBar(
              isReady: isReady,
              helperText: helperText,
              ctaLabel: _mode == _FittingMode.itemCombination
                  ? '가상 피팅 시작'
                  : '스타일 입혀보기',
              onPressed: isReady ? _onCtaPressed : null,
            )
          : null,
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 결과 표시 중에는 모드 전환 숨김 (결과는 단일 뷰)
                    if (!hasResult)
                      _FittingModeToggle(
                        mode: _mode,
                        onChanged: _switchMode,
                      ),
                    const SizedBox(height: 16),
                    if (_mode == _FittingMode.itemCombination)
                      FittingMainStage(
                        mainImagePath:
                            _progress.resultImageUrl ?? _selectedUserImage?.path,
                        isLoading: _progress.isFittingNow,
                        isResult:
                            _progress.resultImageUrl != null &&
                            !_progress.isFittingNow,
                        onUserImageTap: _progress.resultImageUrl != null
                            ? _openResultImageFullScreen
                            : _pickUserImage,
                        onUserImageRemove: _progress.resultImageUrl == null
                            ? () => setState(() => _selectedUserImage = null)
                            : null,
                        topImageFile: _selectedTopFile,
                        topImageUrl: _selectedTopUrl,
                        onTopTap: () => showAddClothingBottomSheet(
                          context,
                          '상의',
                          onWardrobeTap: () => _openWardrobePicker('TOP'),
                          onImageSelected: (file) async {
                            // Ask fit type FIRST before updating state.
                            final fit = await _promptFitTypeFor(isTop: true);
                            if (fit == null || !mounted) return;
                            // Fit confirmed — update state atomically.
                            setState(() {
                              _selectedTopFile = file;
                              _selectedTopUrl = null;
                              _selectedTopClothesId = null;
                              _selectedTopFit = fit;
                            });
                          },
                        ),
                        onTopRemove: () => setState(() {
                          _selectedTopFile = null;
                          _selectedTopUrl = null;
                          _selectedTopClothesId = null;
                        }),
                        bottomImageFile: _selectedBottomFile,
                        bottomImageUrl: _selectedBottomUrl,
                        onBottomTap: () => showAddClothingBottomSheet(
                          context,
                          '하의',
                          onWardrobeTap: () => _openWardrobePicker('BOTTOM'),
                          onImageSelected: (file) async {
                            // Ask fit type FIRST before updating state.
                            final fit = await _promptFitTypeFor(isTop: false);
                            if (fit == null || !mounted) return;
                            // Fit confirmed — update state atomically.
                            setState(() {
                              _selectedBottomFile = file;
                              _selectedBottomUrl = null;
                              _selectedBottomClothesId = null;
                              _selectedBottomFit = fit;
                            });
                          },
                        ),
                        onBottomRemove: () => setState(() {
                          _selectedBottomFile = null;
                          _selectedBottomUrl = null;
                          _selectedBottomClothesId = null;
                        }),
                      )
                    else
                      _StylePhotoStage(
                        userImage: _selectedUserImage,
                        styleImage: _selectedStyleImage,
                        resultUrl: _progress.resultImageUrl,
                        isLoading: _progress.isFittingNow,
                        onUserTap: _progress.resultImageUrl != null
                            ? _openResultImageFullScreen
                            : _pickUserImage,
                        onUserRemove: _progress.resultImageUrl == null
                            ? () => setState(() => _selectedUserImage = null)
                            : null,
                        onStyleTap: _pickStyleImage,
                        onStyleRemove: () =>
                            setState(() => _selectedStyleImage = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const SectionHeader(title: '내 최근 코디'),
              if (_loadingOutfits)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_savedOutfits.isEmpty)
                _EmptyOutfitBanner(onTap: _pickUserImage)
              else
                SavedOutfitRack(items: _savedOutfits, onItemTap: (_) {}),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단 세그먼트: 피팅룸 | AI 스타일리스트 (토글 스타일, 중앙 정렬)

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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.white, Color(0xFFFBFCFE)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.PRIMARYCOLOR.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (latencyText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.SUCCESS_COLOR.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.SUCCESS_COLOR.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: AppColors.SUCCESS_COLOR,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        latencyText!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.SUCCESS_COLOR,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
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
                        foregroundColor: AppColors.BODY_COLOR,
                        backgroundColor: AppColors.INPUT_BG_COLOR,
                        side: const BorderSide(
                          color: AppColors.BORDER_COLOR,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.PRIMARYCOLOR, Color(0xFF3F4651)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.PRIMARYCOLOR.withValues(
                              alpha: 0.38,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        child: const Text('저장하기'),
                      ),
                    ),
                  ),
                ],
              ),
              if (onSaveToFolder != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextButton.icon(
                    onPressed: onSaveToFolder,
                    icon: const Icon(Icons.folder_outlined, size: 18),
                    label: const Text('폴더에 저장'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ACCENT_BLUE,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

/// 하단 CTA 바 (핏감 선택은 바텀시트 팝업으로 분리됨)
class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.isReady,
    required this.helperText,
    required this.ctaLabel,
    required this.onPressed,
  });

  final bool isReady;
  final String helperText;
  final String ctaLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.white, Color(0xFFFBFCFE)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.PRIMARYCOLOR.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 14 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 안내 문구 ──────────
              if (!isReady)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ACCENT_BLUE.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.ACCENT_BLUE.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.ACCENT_BLUE,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        helperText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.ACCENT_BLUE,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── CTA 버튼 ──────────
              GestureDetector(
                onTap: onPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isReady
                        ? const LinearGradient(
                            colors: [
                              AppColors.ACCENT_BLUE,
                              AppColors.ACCENT_PURPLE,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isReady ? null : AppColors.BORDER_COLOR,
                    boxShadow: isReady
                        ? [
                            BoxShadow(
                              color: AppColors.ACCENT_BLUE.withValues(
                                alpha: 0.36,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.ACCENT_PURPLE.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isReady) ...[
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          isReady ? ctaLabel : helperText,
                          style: TextStyle(
                            color: isReady
                                ? Colors.white
                                : AppColors.MEDIUM_GREY,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
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
                    return const Center(child: LoadingIndicator());
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

/// 상단 모드 전환 토글: 아이템 조합 ↔ 스타일 사진 (WardrobePickerSheet 스타일과 동일)
class _FittingModeToggle extends StatelessWidget {
  const _FittingModeToggle({required this.mode, required this.onChanged});

  final _FittingMode mode;
  final ValueChanged<_FittingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_FittingMode value, String label) {
      final selected = mode == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.BLACK : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E4E4),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tab(_FittingMode.itemCombination, '아이템 조합'),
            tab(_FittingMode.stylePhoto, '스타일 사진'),
          ],
        ),
      ),
    );
  }
}

/// 스타일 사진 모드 스테이지: 내 사진 + 입혀볼 스타일 사진 2-슬롯
class _StylePhotoStage extends StatelessWidget {
  const _StylePhotoStage({
    required this.userImage,
    required this.styleImage,
    required this.resultUrl,
    required this.isLoading,
    required this.onUserTap,
    required this.onUserRemove,
    required this.onStyleTap,
    required this.onStyleRemove,
  });

  final File? userImage;
  final File? styleImage;
  final String? resultUrl;
  final bool isLoading;
  final VoidCallback onUserTap;
  final VoidCallback? onUserRemove;
  final VoidCallback onStyleTap;
  final VoidCallback onStyleRemove;

  @override
  Widget build(BuildContext context) {
    final showResult = resultUrl != null && !isLoading;

    if (showResult) {
      return GestureDetector(
        onTap: onUserTap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                resultUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: LoadingIndicator());
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.MEDIUM_GREY,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Row(
        children: [
          Expanded(
            child: _StyleSlot(
              label: '내 사진',
              hint: '전신 사진을 추가하세요',
              icon: Icons.person_outline_rounded,
              file: userImage,
              onTap: onUserTap,
              onRemove: userImage != null ? onUserRemove : null,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StyleSlot(
              label: '입혀볼 스타일',
              hint: '참고할 룩 사진을 추가하세요',
              icon: Icons.auto_awesome_outlined,
              file: styleImage,
              onTap: onStyleTap,
              onRemove: styleImage != null ? onStyleRemove : null,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleSlot extends StatelessWidget {
  const _StyleSlot({
    required this.label,
    required this.hint,
    required this.icon,
    required this.file,
    required this.onTap,
    required this.onRemove,
    required this.isLoading,
  });

  final String label;
  final String hint;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasImage = file != null;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasImage
                ? AppColors.PRIMARYCOLOR.withValues(alpha: 0.18)
                : AppColors.BORDER_COLOR.withValues(alpha: 0.6),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: hasImage
                    ? Image.file(file!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 36, color: AppColors.MEDIUM_GREY),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.BODY_COLOR,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.MEDIUM_GREY,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (hasImage)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            if (hasImage && onRemove != null)
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: LoadingIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 내 옷장 미리보기 — AI 스타일리스트 탭 하단 ─────────────────────────────────

/// 내 최근 코디 — 빈 상태 배너 (HomeScreen 에서 이동)
class _EmptyOutfitBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyOutfitBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDD5FF), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                size: 28,
                color: AppColors.ACCENT_PURPLE,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '아직 저장된 코디가 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '가상 피팅으로 나만의 코디를 만들어보세요',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6E6E73),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B85F5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '피팅 시작하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
