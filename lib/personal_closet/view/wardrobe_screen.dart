import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 토큰
import 'package:image_picker/image_picker.dart'; // 사진 선택
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
// 👇 경로 확인 필요
import '../component/wardrobe_card.dart';
import '../component/category_filter_bar.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late ClothesRepository _clothesRepository;

  List<ClothesModel> _allClothes = [];
  List<ClothesModel> _filteredClothes = [];

  String _selectedCategory = "전체";

  final List<String> _categories = ["전체", "상의", "하의", "아우터", "원피스", "신발", "기타"];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final dio = Dio();
    final storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    if (accessToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // 👇 로그 확인용 (필요 없으면 주석 처리)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // 👇 [주의] api/v1으로 경로가 바뀌었으므로 baseUrl도 확인 필요하지만,
    // Repository 내부에서 경로를 바꿨다면 여기는 그대로 둬도 됩니다.
    _clothesRepository = ClothesRepository(dio, baseUrl: 'http://$ip');
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _clothesRepository.getClothesList();
      if (resp.success) {
        setState(() {
          _allClothes = resp.data ?? [];
          _filterClothes();
        });
        print("✅ 옷장 로딩 완료: ${_allClothes.length}개");
      }
    } catch (e) {
      debugPrint("🚨 옷장 로딩 실패: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 👇 [복구] 삭제 기능 구현
  Future<void> _deleteCloth(int id) async {
    try {
      Navigator.pop(context); // 바텀 시트 닫기

      final resp = await _clothesRepository.deleteCloth(id: id);
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("옷이 삭제되었습니다.")),
        );
        _loadWardrobe(); // 목록 갱신
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("삭제 실패: ${resp.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러 발생: $e")),
      );
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
          return serverCat.contains("TOP") || serverCat.contains("SHIRT") || serverCat.contains("BLOUSE");
        }
        if (_selectedCategory == "하의") {
          return serverCat.contains("BOTTOM") || serverCat.contains("PANTS") || serverCat.contains("SKIRT");
        }
        if (_selectedCategory == "아우터") {
          return serverCat.contains("OUTER") || serverCat.contains("COAT") || serverCat.contains("JACKET");
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

    String? selectedCat = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("카테고리 선택"),
          children: [
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Top"), child: const Text("상의 (Top)")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Bottom"), child: const Text("하의 (Bottom)")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Outer"), child: const Text("아우터 (Outer)")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Shoes"), child: const Text("신발 (Shoes)")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Dress"), child: const Text("원피스 (Dress)")),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddCloth,
        backgroundColor: Colors.black,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWardrobe,
          color: Colors.black,
          child: CustomScrollView(
            slivers: [
              _buildIntroHeader(),
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "나의 옷장",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "총 ${_filteredClothes.length}개의 아이템 · $_selectedCategory",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return GestureDetector(
                onTap: () => _onCategorySelected(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 22,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final cloth = _filteredClothes[index];
            return GestureDetector(
              onTap: () => _showClothDetail(context, cloth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          cloth.imgUrl ?? "",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
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
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cloth.name ?? "이름 없음",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
          Icon(Icons.checkroom_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "아직 $_selectedCategory 아이템이 없어요",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _onAddCloth,
            child: const Text("아이템 추가하기"),
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
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 이미지 영역 (flex: 3)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      cloth.imgUrl ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
              ),

              // 👇 [수정됨] 정보 영역이 길어지면 스크롤 되도록 변경 (에러 해결!)
              Expanded(
                flex: 2,
                child: SingleChildScrollView( // 여기가 핵심
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cloth.category ?? "ETC",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),

                            // 👇 [복구] 삭제 기능 연결 완료
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                _deleteCloth(cloth.id);
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cloth.name ?? "이름 없는 옷",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "브랜드: ${cloth.brand ?? '정보 없음'}\n소재: ${cloth.material ?? '정보 없음'}\n계절: ${cloth.season ?? '정보 없음'}",
                          style: TextStyle(color: Colors.grey[600], height: 1.5),
                        ),
                        // 하단 여유 공간
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
}