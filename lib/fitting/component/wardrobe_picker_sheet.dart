import 'package:flutter/material.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/util/clothes_category_util.dart';
import '../theme/fitting_room_theme.dart';

class WardrobePickerSheet extends StatefulWidget {
  final List<ClothesModel> clothes;
  final Function(ClothesModel) onClothSelected;
  final String category; // 👇 [New] 필터링할 카테고리 (TOP, BOTTOM)

  const WardrobePickerSheet({
    required this.clothes,
    required this.onClothSelected,
    required this.category, // 필수 인자
    super.key,
  });

  @override
  State<WardrobePickerSheet> createState() => _WardrobePickerSheetState();
}

class _WardrobePickerSheetState extends State<WardrobePickerSheet> {
  List<ClothesModel> _filteredClothes = [];

  @override
  void initState() {
    super.initState();
    _filterClothes();
  }

  void _filterClothes() {
    _filteredClothes = widget.clothes.where((cloth) {
      final targetCat = widget.category.toUpperCase();
      if (targetCat == 'TOP') return isTopCategory(cloth.category);
      if (targetCat == 'BOTTOM') return isBottomCategory(cloth.category);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 제목 설정 (상의 선택하기 / 하의 선택하기)
    final title = widget.category == 'TOP' ? "상의 선택하기" : "하의 선택하기";

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
          Text(
            title, // 동적 제목
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FittingRoomTheme.kTextColor,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _filteredClothes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "해당 카테고리의 옷이 없습니다.",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredClothes.length,
              itemBuilder: (context, index) {
                final cloth = _filteredClothes[index];
                return GestureDetector(
                  onTap: () {
                    widget.onClothSelected(cloth);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            image: cloth.imgUrl != null
                                ? DecorationImage(
                              image: NetworkImage(cloth.imgUrl!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: cloth.imgUrl == null
                              ? const Icon(Icons.checkroom, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cloth.name ?? "-",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}