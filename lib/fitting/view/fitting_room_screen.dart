import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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


class FittingRoomScreen extends StatefulWidget {
  const FittingRoomScreen({super.key});

  @override
  State<FittingRoomScreen> createState() => _FittingRoomScreenState();
}

class _FittingRoomScreenState extends State<FittingRoomScreen> with SingleTickerProviderStateMixin {
  late final FittingRepository _fittingRepository;
  late final ClothesRepository _clothesRepository;

  // 피팅 결과 이미지 URL 및 상태 변수
  String? _resultImageUrl;
  bool _isFittingNow = false;
  String? _latency;

  // 사용자가 선택한 전신 사진 파일
  File? _selectedUserImage;

  // 선택된 옷 파일 (상의, 하의 구분)
  File? _selectedTopFile;
  File? _selectedBottomFile;

  // UI에서 선택 상태를 보여주기 위한 URL 저장 변
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


    final dio = Dio();
    _fittingRepository = FittingRepository(dio, baseUrl: 'http://$ip');
    _clothesRepository = ClothesRepository(dio, baseUrl: 'http://$ip');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );


    _loadWardrobe();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showOnboardingSheet();
      });
    });
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
      builder: (context) {
        return FittingOnboardingSheet(
          onStart: () {
            Navigator.pop(context);
            print("가상 피팅 룸 입장");
          },
        );
      },
    );
  }


  Future<void> _loadWardrobe() async {
    try {
      final resp = await _clothesRepository.getClothesList();
      if (resp.success) {
        setState(() {
          _serverClothes = resp.data;
        });
        print("옷장 로딩 완료. 개수: ${_serverClothes.length}");
      }
    } catch (e) {
      print("옷장 로딩 실패: $e");
    }
  }


  Future<void> _pickUserImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedUserImage = File(image.path);
      });
      print("사용자 이미지 선택됨: ${image.path}");
    }
  }


  Future<void> _selectCloth(ClothesModel cloth) async {
    final imageUrl = cloth.imgUrl!;

    final category = cloth.category?.toUpperCase() ?? "";
    final isTop = category.contains("TOP") || category.contains("상의") || category.contains("SHIRT");


    setState(() {
      if (isTop) {
        _selectedTopUrl = imageUrl;
      } else {
        _selectedBottomUrl = imageUrl;
      }
    });

    try {
      print("옷 이미지 다운로드 시작 ($category): $imageUrl");


      final tempDir = await getTemporaryDirectory();
      final fileName = 'cloth_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, tempPath);

      setState(() {
        if (isTop) {
          _selectedTopFile = File(tempPath);
          print("상의 선택 및 파일 변환 완료");
        } else {
          _selectedBottomFile = File(tempPath);
          print("하의 선택 및 파일 변환 완료");
        }
      });

    } catch (e) {
      print("옷 이미지 다운로드 실패: $e");
    }
  }


  Future<void> _startVirtualFitting() async {

    if (_selectedUserImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내 전신 사진을 먼저 선택해주세요.')));
      return;
    }
    if (_selectedTopFile == null && _selectedBottomFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('입어볼 옷을 최소 하나는 선택해주세요.')));
      return;
    }


    final stopwatch = Stopwatch()..start();

    setState(() {
      _isFittingNow = true;
      _resultImageUrl = null;
      _latency = null;
    });

    try {
      print("가상 피팅 요청 시작. (상의: ${_selectedTopFile != null}, 하의: ${_selectedBottomFile != null})");

      final reqResp = await _fittingRepository.requestFitting(
        userImage: _selectedUserImage!,
        topImage: _selectedTopFile,
        bottomImage: _selectedBottomFile,
      );

      final taskId = reqResp.data.taskId;
      print("요청 접수 완료. Task ID: $taskId");

      String? finalUrl;


      while (true) {
        await Future.delayed(const Duration(seconds: 2));

        final statusResp = await _fittingRepository.checkStatus(taskId: taskId);
        final statusData = statusResp.data;

        print("현재 작업 상태: ${statusData.status}");

        if (statusData.status == 'COMPLETED') {
          finalUrl = statusData.resultImgUrl;
          break;
        } else if (statusData.status == 'FAILED') {
          throw Exception('서버에서 작업을 실패했습니다.');
        }
      }

      if (finalUrl != null) {
        setState(() {
          _resultImageUrl = finalUrl;
        });
        print("피팅 완료. 결과 URL: $finalUrl");
      }

    } catch (e) {
      print("피팅 프로세스 에러 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    } finally {
      stopwatch.stop();
      final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);

      setState(() {
        _isFittingNow = false;
        _latency = "${seconds}s";
      });
      print("총 소요 시간: $_latency");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FittingRoomTheme.kBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isFittingNow ? null : _startVirtualFitting,
        backgroundColor: PRIMARYCOLOR,
        icon: const Icon(Icons.checkroom, color: Colors.white),
        label: Text(
          _isFittingNow ? "작업 진행 중..." : "가상 피팅 시작",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const FittingRoomHeader(),

              // 소요 시간
              if (_latency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            "$_latency 소요",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),


              GestureDetector(
                onTap: _pickUserImage,
                child: FittingMainStage(
                  imagePath: _resultImageUrl ?? _selectedUserImage?.path ?? 'asset/img/fitting1.jpg',
                  isLoading: _isFittingNow,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "이미지를 탭하여 전신 사진을 선택하세요",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),
              AiStylistInput(controller: _promptController, chips: _quickChips),

              const SizedBox(height: 32),
              const Text("내 옷장", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),


              SizedBox(
                height: 110,
                child: _serverClothes.isEmpty
                    ? const Center(child: Text("옷장이 비어있습니다."))
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _serverClothes.length,
                  itemBuilder: (context, index) {
                    final cloth = _serverClothes[index];


                    final isSelected = (cloth.imgUrl == _selectedTopUrl) || (cloth.imgUrl == _selectedBottomUrl);

                    return GestureDetector(
                      onTap: () {
                        if (cloth.imgUrl != null) {
                          _selectCloth(cloth);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(
                                color: isSelected ? PRIMARYCOLOR : Colors.grey.shade300,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              image: cloth.imgUrl != null
                                  ? DecorationImage(
                                image: NetworkImage(cloth.imgUrl!),
                                fit: BoxFit.cover,
                                opacity: isSelected ? 1.0 : 0.9,
                              )
                                  : null,
                            ),
                          ),

                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: PRIMARYCOLOR,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}