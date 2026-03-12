import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:capstone_fe/common/camera/photo_guide_screen.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/util/clothes_category_util.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/personal_closet/view/clothes_set_list_screen.dart';
import 'package:capstone_fe/personal_closet/view/clothing_upload_progress_dialog.dart';

// 홈 화면과 통일된 배경색 (Apple-style light grey)
const _kBg = Color(0xFFF5F5F7);

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  /// 옷장 탭 선택 시 호출 (닉네임 등 로컬 저장값 갱신용)
  static void Function()? onWardrobeTabSelected;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late ClothesRepository _clothesRepository;
  late FittingRepository _fittingRepository;

  List<ClothesModel> _allClothes = [];
  List<ClothesModel> _filteredClothes = [];
  List<SavedFittingData> _savedFittings = [];

  String _selectedCategory = "전체";
  final List<String> _categories = ["전체", "상의", "하의", "아우터", "원피스", "신발", "기타"];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WardrobeScreen.onWardrobeTabSelected = _loadWardrobe;
    _initRepository();
  }

  @override
  void dispose() {
    WardrobeScreen.onWardrobeTabSelected = null;
    super.dispose();
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
      if (mounted) {
        setState(() {
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
    Navigator.pop(context); // 상세 모달 닫기

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClothingDeleteProgressDialog(
        clothId: id,
        repository: _clothesRepository,
      ),
    );

    if (!mounted) return;
    if (success == true) {
      _loadWardrobe();
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
        final cat = cloth.category?.toUpperCase() ?? "";

        if (_selectedCategory == "상의") return isTopCategory(cloth.category);
        if (_selectedCategory == "하의") return isBottomCategory(cloth.category);
        if (_selectedCategory == "아우터") {
          return cat.contains("OUTER") ||
              cat.contains("COAT") ||
              cat.contains("JACKET");
        }
        if (_selectedCategory == "원피스") {
          return cat.contains("DRESS") || cat.contains("ONEPIECE");
        }
        if (_selectedCategory == "신발") return cat.contains("SHOES");
        return true;
      }).toList();
    }
  }

  void _onAddCloth() async {
    // 1단계: 카테고리 선택
    String? selectedCat = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.BORDER_COLOR,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.MEDIUM_GREY,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '카테고리를 선택하세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.BLACK,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildCategoryOption("상의", "Top"),
              _buildCategoryOption("하의", "Bottom"),
              // TODO: 백엔드 API 명세 확인 필요 — OpenAPI 기준 Top/Bottom/Shoes만 공식 지원.
              // "Outer"는 현재 서버에서 Top으로 처리될 수 있으므로 백엔드와 협의 후 매핑 확정 필요.
              _buildCategoryOption("아우터", "Outer"),
              _buildCategoryOption("신발", "Shoes"),
              // TODO: "Dress"도 OpenAPI 명세에 없는 값. 백엔드 지원 여부 확인 필요.
              _buildCategoryOption("원피스", "Dress"),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (selectedCat == null || !mounted) return;

    // 2단계: 사진 소스 선택 (카메라 / 갤러리)
    final String? source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.BORDER_COLOR,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'PHOTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.MEDIUM_GREY,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.BORDER_COLOR,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _imageSourceTile(
                context: ctx,
                icon: Icons.camera_alt_outlined,
                label: "사진 촬영",
                onTap: () => Navigator.pop(ctx, "camera"),
              ),
              _imageSourceTile(
                context: ctx,
                icon: Icons.photo_library_outlined,
                label: "갤러리에서 선택",
                onTap: () => Navigator.pop(ctx, "gallery"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    // 3단계: 사진 획득 (카메라 or 갤러리)
    File? file;
    if (source == "camera") {
      if (selectedCat == "Top" || selectedCat == "Bottom") {
        final guideType = selectedCat == "Top"
            ? PhotoGuideType.topClothing
            : PhotoGuideType.bottomClothing;
        file = await PhotoGuideScreen.open(context, type: guideType);
      } else {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(source: ImageSource.camera);
        if (picked != null) file = File(picked.path);
      }
    } else {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) file = File(picked.path);
    }

    if (file == null || !mounted) return;

    try {
      final resp = await _clothesRepository.uploadSingleCloth(
        category: selectedCat,
        file: file,
      );

      if (!resp.success) throw Exception(resp.message);
      if (!mounted) return;

      // 서버 응답: {"data": {"taskId": 1}}
      final data = resp.data as Map<String, dynamic>?;
      final taskId = data?['taskId'] as int?;
      if (taskId == null) throw Exception('taskId를 받지 못했습니다.');

      // SSE 진행 다이얼로그 표시 (사용자가 직접 닫을 수 없음)
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ClothingUploadProgressDialog(taskId: taskId),
      );

      if (!mounted) return;

      if (success == true) {
        _loadWardrobe();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('옷 등록에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    }
  }

  Widget _imageSourceTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: AppColors.PRIMARYCOLOR),
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
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.MEDIUM_GREY,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.MEDIUM_GREY,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: GestureDetector(
        onTap: _onAddCloth,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.ACCENT_BLUE, AppColors.ACCENT_PURPLE],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
            )
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    const Text(
                      '옷장',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.BLACK,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClothesSetListScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.PRIMARYCOLOR,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '코디 폴더',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${_allClothes.length}개의 아이템 · $_selectedCategory",
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.MEDIUM_GREY,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
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
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'SAVED OUTFITS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.MEDIUM_GREY,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _savedFittings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _savedFittings[index];
                final imageUrl = item.resultImgUrl;
                if (imageUrl == null || imageUrl.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => _showSavedFittingFullScreen(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 115,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.BORDER_COLOR,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.MEDIUM_GREY,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            right: 10,
                            child: Text(
                              item.setName ?? "저장한 코디",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          height: 52,
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
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.PRIMARYCOLOR
                        : AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.PRIMARYCOLOR.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    category,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.BODY_COLOR,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final cloth = _filteredClothes[index];
          return GestureDetector(
            onTap: () => _showClothDetail(context, cloth),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        cloth.imgUrl ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _kBg,
                          child: const Icon(
                            Icons.checkroom_outlined,
                            color: AppColors.MEDIUM_GREY,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cloth.category ?? "",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.MEDIUM_GREY,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cloth.name ?? "이름 없음",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.BLACK,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _filteredClothes.length),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              size: 36,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "$_selectedCategory 아이템이 없어요",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.BLACK,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "+ 버튼으로 새 아이템을 추가해보세요",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.MEDIUM_GREY,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _onAddCloth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.PRIMARYCOLOR,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                "아이템 추가",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // 상단 핸들 + 삭제
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.BORDER_COLOR,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.ERROR_COLOR,
                            ),
                            onPressed: () => _deleteCloth(cloth.id),
                            tooltip: '삭제',
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 상품 이미지
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              cloth.imgUrl ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.INPUT_BG_COLOR,
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: AppColors.MEDIUM_GREY,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 상품 정보 블록 (쇼핑몰 스타일)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카테고리 뱃지
                          if (_isNotEmpty(cloth.category))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cloth.category!.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.MEDIUM_GREY,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          // 상품명
                          Text(
                            cloth.name ?? "이름 없는 옷",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.BLACK,
                              height: 1.3,
                            ),
                          ),
                          if (_isNotEmpty(cloth.brand)) ...[
                            const SizedBox(height: 6),
                            Text(
                              cloth.brand!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.BODY_COLOR,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          // 가격
                          if (cloth.price != null && cloth.price! > 0) ...[
                            const SizedBox(height: 14),
                            Text(
                              _formatPrice(cloth.price!),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.BLACK,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // 구매하기 버튼 (buyUrl 있을 때만)
                          if (_isNotEmpty(cloth.buyUrl))
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(cloth.buyUrl!),
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                ),
                                label: const Text("구매 링크로 이동"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.PRIMARYCOLOR,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (_isNotEmpty(cloth.buyUrl))
                            const SizedBox(height: 24),
                          // 구분선
                          const Divider(
                            height: 32,
                            color: AppColors.BORDER_COLOR,
                          ),
                          // 상세 정보 섹션들 (값 있는 것만 표시)
                          ..._buildDetailSection("기본 정보", [
                            _row("색상", cloth.color),
                            _row("계절", cloth.season),
                            _row("소재", cloth.material),
                            _row("두께감", cloth.thickness),
                          ]),
                          ..._buildDetailSection("스타일 · 착용", [
                            _row("스타일", cloth.style),
                            _row("핏", cloth.fit),
                            _row("기장", cloth.length),
                            _row("착용 상황", cloth.occasion),
                          ]),
                          ..._buildDetailSection("디테일", [
                            _row("넥라인", cloth.neckLine),
                            _row("소매", cloth.sleeveType),
                            _row("패턴", cloth.pattern),
                            _row("단추/잠금", cloth.closure),
                            _row("질감", cloth.texture),
                          ]),
                          if (_isNotEmpty(cloth.detail)) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "상세 설명",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.BLACK,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cloth.detail!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.BODY_COLOR,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isNotEmpty(String? v) => v != null && v.trim().isNotEmpty;

  String _formatPrice(int price) {
    if (price >= 10000) {
      return "${(price / 10000).toStringAsFixed(price % 10000 == 0 ? 0 : 1)}만 원";
    }
    return "$price 원";
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  List<Widget> _buildDetailSection(String title, List<Widget?> rows) {
    final valid = rows.whereType<Widget>().toList();
    if (valid.isEmpty) return [];
    return [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.BLACK,
        ),
      ),
      const SizedBox(height: 10),
      ...valid,
      const SizedBox(height: 20),
    ];
  }

  Widget? _row(String label, String? value) {
    if (!_isNotEmpty(value)) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
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
              value!,
              style: const TextStyle(
                color: AppColors.BLACK,
                fontSize: 14,
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
