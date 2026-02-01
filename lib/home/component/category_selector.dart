import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  final List<String> categories = ['전체', '상의', '하의', '아우터', '신발', '가방', '기타'];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 24.0 : 16.0,
                  vertical: 10.0
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF5F6D) : Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: isSelected
                    ? Border.all(color: Colors.transparent)
                    : Border.all(color: Colors.grey[300]!),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFFFF5F6D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}