import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/personal_closet/view/clothes_set_list_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late ClothesRepository _clothesRepository;
  late FittingRepository _fittingRepository;

  List<ClothesModel> _allClothes = [];
  List<ClothesModel> _filteredClothes = [];
  List<SavedFittingData> _savedFittings = [];
  String? _nickname;

  String _selectedCategory = "전체";
  final List<String> _categories = [
    "전체",
    "상의",
    "하의",
    "아우터",
    "원피스",
    "신발",
    "기타"
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final dio = createAuthDio();
    _clothesRepository = ClothesRepository(dio, baseUrl: baseUrl);
    _fittingRepository = FittingRepository(dio, baseUrl: baseUrl);
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    setState(() => _isLoading = true);
    try {
      final clothesResp = await _clothesRepository.getClothesList();
      final savedResp = await _fittingRepository.getMyCloset();
      final n = await const FlutterSecureStorage().read(key: 'NICKNAME');
      if (mounted) {
        setState(() {
          _nickname = n;
          if (clothesResp.success) _allClothes = clothesResp.data ?? [];
          _filterClothes();
          if (savedResp.success) _savedFittings = savedResp.data ?? [];
        });
      }
    } catch (e) {
      debugPrint("옷장/저장 코디 로드 실패: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSavedFittingFullScreen(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FullScreenImageView(imageUrl: imageUrl),
    );
  }

  Future<void> _deleteCloth(int id) async {
    try {
      Navigator.pop(context); // 모달 닫기

      final resp = await _clothesRepository.deleteCloth(id: id);
      if (resp.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("옷이 삭제되었습니다.")),
          );
        }
        _loadWardrobe(); // 목록 갱신
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("삭제 실패: ${resp.message}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("에러 발생: $e")),
        );
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterClothes();
    });
  }

  void _filterClothes() {
    if (_selectedCategory == "전체") {
      _filteredClothes = List.from(_allClothes);
    } else {
      _filteredClothes = _allClothes.where((cloth) {
        final serverCat = cloth.category?.toUpperCase() ?? "";

        if (_selectedCategory == "상의") {
          return serverCat.contains("TOP") ||
              serverCat.contains("SHIRT") ||
              serverCat.contains("BLOUSE");
        }
        if (_selectedCategory == "하의") {
          return serverCat.contains("BOTTOM") ||
              serverCat.contains("PANTS") ||
              serverCat.contains("SKIRT");
        }
        if (_selectedCategory == "아우터") {
          return serverCat.contains("OUTER") ||
              serverCat.contains("COAT") ||
              serverCat.contains("JACKET");
        }
        if (_selectedCategory == "원피스") {
          return serverCat.contains("DRESS") || serverCat.contains("ONEPIECE");
        }
        if (_selectedCategory == "신발") {
          return serverCat.contains("SHOES");
        }
        return true; // 기타
      }).toList();
    }
  }

  void _onAddCloth() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!mounted) return;

    // 카테고리 선택 다이얼로그 (디자인 개선)
    String? selectedCat = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "카테고리 선택",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.BLACK,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildCategoryOption("상의 (Top)", "Top"),
            _buildCategoryOption("하의 (Bottom)", "Bottom"),
            _buildCategoryOption("아우터 (Outer)", "Outer"),
            _buildCategoryOption("신발 (Shoes)", "Shoes"),
            _buildCategoryOption("원피스 (Dress)", "Dress"),
          ],
        ),
      ),
    );

    if (selectedCat == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("옷을 등록하고 분석 중입니다... 잠시만 기다려주세요.")),
    );

    try {
      final file = File(image.path);
      final resp = await _clothesRepository.uploadSingleCloth(
        category: selectedCat,
        file: file,
      );

      if (resp.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("옷 등록 완료! 목록을 갱신합니다.")),
        );
        Future.delayed(const Duration(seconds: 1), () => _loadWardrobe());
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("등록 실패: $e")),
      );
    }
  }

  Widget _buildCategoryOption(String label, String value) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.BORDER_COLOR)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: AppColors.BODY_COLOR),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // 전체 배경 흰색
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddCloth,
        backgroundColor: AppColors.PRIMARYCOLOR, // 차콜색 버튼
        elevation: 0, // 그림자 제거
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR))
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWardrobe,
          color: AppColors.PRIMARYCOLOR,
          child: CustomScrollView(
            slivers: [
              _buildIntroHeader(),
              _buildSavedOutfitsSection(),
              _buildCategoryFilter(),
              _buildGridOrEmpty(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroHeader() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  (_nickname != null && _nickname!.isNotEmpty)
                      ? '${_nickname!}의 옷장'
                      : '나의 옷장',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.BLACK,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClothesSetListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_outlined, size: 18),
                  label: const Text('코디 폴더'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.PRIMARYCOLOR,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "총 ${_filteredClothes.length}개의 아이템 · $_selectedCategory",
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.MEDIUM_GREY,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 저장한 코디 목록 섹션 (가로 스크롤 카드)
  Widget _buildSavedOutfitsSection() {
    if (_savedFittings.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              "저장한 코디",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.BLACK,
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _savedFittings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _savedFittings[index];
                final imageUrl = item.resultImgUrl;
                if (imageUrl == null || imageUrl.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => _showSavedFittingFullScreen(imageUrl),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.BORDER_COLOR),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.INPUT_BG_COLOR,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            right: 8,
                            child: Text(
                              item.setName ?? "저장한 코디",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return GestureDetector(
                onTap: () => _onCategorySelected(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.PRIMARYCOLOR
                        : AppColors.INPUT_BG_COLOR,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.PRIMARYCOLOR
                          : AppColors.BORDER_COLOR,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.BODY_COLOR,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridOrEmpty() {
    if (_filteredClothes.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7, // 비율 조정
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final cloth = _filteredClothes[index];
            return GestureDetector(
              onTap: () => _showClothDetail(context, cloth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.BORDER_COLOR), // 테두리 추가
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          cloth.imgUrl ?? "",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.INPUT_BG_COLOR,
                                child: const Icon(Icons.broken_image_rounded,
                                    color: AppColors.MEDIUM_GREY),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cloth.category ?? "카테고리 없음",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.MEDIUM_GREY,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cloth.name ?? "이름 없음",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.BLACK,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _filteredClothes.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checkroom_outlined,
              size: 56, color: AppColors.BORDER_COLOR),
          const SizedBox(height: 20),
          Text(
            "아직 $_selectedCategory 아이템이 없어요",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.BODY_COLOR,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _onAddCloth,
            child: const Text(
              "아이템 추가하기",
              style: TextStyle(
                color: AppColors.PRIMARYCOLOR,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClothDetail(BuildContext context, ClothesModel cloth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // 높이 확장
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.BORDER_COLOR,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 이미지 영역 (꽉 차게)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        cloth.imgUrl ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: AppColors.INPUT_BG_COLOR,
                          child: const Icon(Icons.broken_image_rounded,
                              size: 40, color: AppColors.MEDIUM_GREY),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 정보 영역
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.INPUT_BG_COLOR,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                Border.all(color: AppColors.BORDER_COLOR),
                              ),
                              child: Text(
                                cloth.category ?? "ETC",
                                style: const TextStyle(
                                  color: AppColors.BODY_COLOR,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.ERROR_COLOR),
                              onPressed: () {
                                _deleteCloth(cloth.id);
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cloth.name ?? "이름 없는 옷",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.BLACK,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 상세 정보 테이블
                        _buildDetailRow("브랜드", cloth.brand),
                        _buildDetailRow("소재", cloth.material),
                        _buildDetailRow("계절", cloth.season),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.MEDIUM_GREY,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "정보 없음",
              style: const TextStyle(
                color: AppColors.BLACK,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 저장한 코디 피팅 결과 이미지 전체 화면 뷰어
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