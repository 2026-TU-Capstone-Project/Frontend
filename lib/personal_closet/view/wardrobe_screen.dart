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
import 'package:capstone_fe/personal_closet/view/clothing_upload_progress_dialog.dart';

const _kBg = Color(0xFFF5F5F7);

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

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
  final List<String> _categories = ["전체", "상의", "하의", "아우터", "신발", "원피스", "기타"];

  bool _isLoading = true;
  bool _showClothesTab = true;

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
      if (mounted) setState(() => _isLoading = false);
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
    Navigator.pop(context);
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClothingDeleteProgressDialog(
        clothId: id,
        repository: _clothesRepository,
      ),
    );
    if (!mounted) return;
    if (success == true) _loadWardrobe();
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
              _buildCategoryOption("아우터", "Outer"),
              _buildCategoryOption("신발", "Shoes"),
              _buildCategoryOption("원피스", "Dress"),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (selectedCat == null || !mounted) return;

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
                    Expanded(child: Container(height: 1, color: AppColors.BORDER_COLOR)),
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

      final data = resp.data as Map<String, dynamic>?;
      final taskId = data?['taskId'] as int?;
      if (taskId == null) throw Exception('taskId를 받지 못했습니다.');

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
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
            const Icon(Icons.chevron_right, color: AppColors.MEDIUM_GREY, size: 20),
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
            const Icon(Icons.chevron_right, color: AppColors.MEDIUM_GREY, size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR))
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  _buildTopBar(),
                  const SizedBox(height: 18),
                  Center(child: _buildSegmentedTabs()),
                  const SizedBox(height: 16),
                  if (_showClothesTab) ...[
                    _buildCategoryFilterChips(),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadWardrobe,
                      color: AppColors.PRIMARYCOLOR,
                      child: _showClothesTab
                          ? _buildClothesGrid()
                          : _buildCollectionsGrid(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Search button
          _PillButton(
            icon: Icons.search_rounded,
            label: '검색',
            onTap: () {}, // 향후 검색 기능
          ),
          // Title
          const Expanded(
            child: Center(
              child: Text(
                '옷장',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.BLACK,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          // Upload button
          _PillButton(
            icon: Icons.add,
            label: '추가',
            onTap: _onAddCloth,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabChip(
            label: '옷',
            isSelected: _showClothesTab,
            onTap: () => setState(() => _showClothesTab = true),
          ),
          _TabChip(
            label: '컬렉션',
            isSelected: !_showClothesTab,
            onTap: () => setState(() => _showClothesTab = false),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => _onCategorySelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.BLACK : Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.0 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.BLACK,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClothesGrid() {
    if (_filteredClothes.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildEmptyState(),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _filteredClothes.length,
      itemBuilder: (context, index) {
        final cloth = _filteredClothes[index];
        return GestureDetector(
          onTap: () => _showClothDetail(context, cloth),
          child: _ClothGridCard(cloth: cloth),
        );
      },
    );
  }

  Widget _buildCollectionsGrid() {
    if (_savedFittings.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 60, color: AppColors.BORDER_COLOR),
                SizedBox(height: 16),
                Text(
                  '아직 저장된 코디가 없어요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.BLACK,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '피팅룸에서 코디를 만들어 저장해보세요',
                  style: TextStyle(fontSize: 13, color: AppColors.MEDIUM_GREY),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemCount: _savedFittings.length,
      itemBuilder: (context, index) {
        final item = _savedFittings[index];
        return GestureDetector(
          onTap: () {
            final url = item.resultImgUrl;
            if (url != null && url.isNotEmpty) _showSavedFittingFullScreen(url);
          },
          child: _CollectionGridCard(item: item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: const Icon(Icons.checkroom_outlined, size: 36, color: AppColors.MEDIUM_GREY),
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
            "상단 '추가' 버튼으로 새 아이템을 추가해보세요",
            style: TextStyle(fontSize: 13, color: AppColors.MEDIUM_GREY),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          if (_isNotEmpty(cloth.buyUrl))
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(cloth.buyUrl!),
                                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                                label: const Text("구매 링크로 이동"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.PRIMARYCOLOR,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (_isNotEmpty(cloth.buyUrl)) const SizedBox(height: 24),
                          const Divider(height: 32, color: AppColors.BORDER_COLOR),
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

// ============================================================
// Pill Button (검색 / 추가)
// ============================================================
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.BLACK),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.BLACK,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Segmented Tab Chip
// ============================================================
class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.BLACK : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Clothes Grid Card
// ============================================================
class _ClothGridCard extends StatefulWidget {
  final ClothesModel cloth;
  const _ClothGridCard({required this.cloth});

  @override
  State<_ClothGridCard> createState() => _ClothGridCardState();
}

class _ClothGridCardState extends State<_ClothGridCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            Image.network(
              widget.cloth.imgUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF0F0F0),
                child: const Icon(
                  Icons.checkroom_outlined,
                  color: Color(0xFFCCCCCC),
                  size: 40,
                ),
              ),
            ),
            // Heart icon (토글)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Icon(
                  _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22,
                  color: _liked ? const Color(0xFFFF3B30) : Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4),
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

// ============================================================
// Collection Grid Card (저장한 코디)
// ============================================================
class _CollectionGridCard extends StatefulWidget {
  final SavedFittingData item;
  const _CollectionGridCard({required this.item});

  @override
  State<_CollectionGridCard> createState() => _CollectionGridCardState();
}

class _CollectionGridCardState extends State<_CollectionGridCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final url = widget.item.resultImgUrl;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            url != null && url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
            // Heart icon (토글)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Icon(
                  _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22,
                  color: _liked ? const Color(0xFFFF3B30) : Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF0F0F0),
    child: const Center(
      child: Icon(Icons.person_outline, color: Color(0xFFCCCCCC), size: 40),
    ),
  );
}

// ============================================================
// Full Screen Image Viewer
// ============================================================
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
