import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import '../component/wardrobe_card.dart';
import '../component/category_filter_bar.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late final ClothesRepository _clothesRepository;

  List<ClothesModel> _allClothes = [];
  List<ClothesModel> _filteredClothes = [];

  String _selectedCategory = "전체";
  final List<String> _categories = ["전체", "상의", "하의", "아우터", "원피스", "기타"];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _clothesRepository = ClothesRepository(dio, baseUrl: 'http://$ip');
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    try {
      final resp = await _clothesRepository.getClothesList();
      if (resp.success) {
        setState(() {
          _allClothes = resp.data;
          _filterClothes();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("옷장 로딩 실패: $e");
      setState(() => _isLoading = false);
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
        if (_selectedCategory == "상의") return serverCat.contains("TOP") || serverCat.contains("SHIRT");
        if (_selectedCategory == "하의") return serverCat.contains("BOTTOM") || serverCat.contains("PANTS");
        if (_selectedCategory == "아우터") return serverCat.contains("OUTER") || serverCat.contains("COAT");
        return true;
      }).toList();
    }
  }

  void _onAddCloth() {
    debugPrint(" 옷 추가");
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
              _buildSearchBar(),
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
            Text(
              "OO의 옷장",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_filteredClothes.length} items · $_selectedCategory",
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


  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: const [
              Icon(Icons.search, size: 20, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                "어떤 옷을 찾으세요?",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: CategoryFilterBar(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
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
            return Hero(
              tag: cloth.id ?? index,
              child: WardrobeCard(
                imageUrl: cloth.imgUrl,
                title: cloth.category,
                onTap: () => _showClothDetail(context, cloth),
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
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      cloth.imgUrl ?? "",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cloth.category ?? "",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}