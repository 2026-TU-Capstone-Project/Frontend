import 'package:flutter/material.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/util/clothes_category_util.dart';
import 'package:capstone_fe/common/const/colors.dart';
import '../theme/fitting_room_theme.dart';

class WardrobePickerSheet extends StatefulWidget {
  final List<ClothesModel> clothes;
  final Function(ClothesModel) onClothSelected;
  final String category;

  const WardrobePickerSheet({
    required this.clothes,
    required this.onClothSelected,
    required this.category,
    super.key,
  });

  @override
  State<WardrobePickerSheet> createState() => _WardrobePickerSheetState();
}

class _WardrobePickerSheetState extends State<WardrobePickerSheet> {
  List<ClothesModel> _filteredClothes = [];
  int _pressedIndex = -1;

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

  String _categoryLabel(String? category) {
    if (category == null) return '';
    final upper = category.toUpperCase();
    if (isTopCategory(upper)) return 'TOP';
    if (isBottomCategory(upper)) return 'BOTTOM';
    return upper;
  }

  @override
  Widget build(BuildContext context) {
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FittingRoomTheme.kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredClothes.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredClothes.length,
                    itemBuilder: (context, index) =>
                        _buildClothItem(index),
                  ),
          ),
        ],
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
              color: AppColors.INPUT_BG_COLOR,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              size: 40,
              color: AppColors.MEDIUM_GREY,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "등록된 옷이 없어요",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.BODY_COLOR,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "옷장에 옷을 추가하고\n가상 피팅을 시작해 보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.MEDIUM_GREY,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothItem(int index) {
    final cloth = _filteredClothes[index];
    final isPressed = _pressedIndex == index;

    return GestureDetector(
      onTap: () {
        widget.onClothSelected(cloth);
        Navigator.pop(context);
      },
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = -1),
      onTapCancel: () => setState(() => _pressedIndex = -1),
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.INPUT_BG_COLOR,
                          border: Border.all(
                            color: AppColors.BORDER_COLOR,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          image: cloth.imgUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(cloth.imgUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: cloth.imgUrl == null
                            ? const Icon(Icons.checkroom,
                                color: AppColors.MEDIUM_GREY)
                            : null,
                      ),
                      if (cloth.imgUrl != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cloth.name ?? "-",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _categoryLabel(cloth.category),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ],
        ),
      ),
    );
  }
}