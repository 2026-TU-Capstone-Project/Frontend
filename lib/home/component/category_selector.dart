import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  // 1. 카테고리 데이터 리스트
  final List<String> categories = [
    '전체',
    '상의',
    '하의',
    '아우터',
    '신발',
    '가방',
    '기타',
  ];

  // 2. 현재 선택된 인덱스 저장 (0번='전체'가 기본값)
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50, // 리스트의 높이 제한 (필수)
      child: ListView.separated(
        scrollDirection: Axis.horizontal, // 가로 스크롤 설정
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // 양옆 여백
        itemCount: categories.length,

        // 아이템 사이의 간격 (10px)
        separatorBuilder: (context, index) => const SizedBox(width: 10),

        itemBuilder: (context, index) {
          // 3. 현재 그려지는 아이템이 선택된 상태인지 확인
          final bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              // 클릭 시 선택된 인덱스 변경 -> 화면 다시 그리기
              setState(() {
                selectedIndex = index;
              });
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              decoration: BoxDecoration(
                // 선택되면 빨간색(브랜드 컬러), 아니면 연한 회색
                color: isSelected ? const Color(0xFFFF5F6D) : Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0), // 둥근 캡슐 모양

                // 선택된 놈만 그림자 주기 (이미지 디테일)
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFFFF5F6D).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  // 선택되면 흰색, 아니면 짙은 회색
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 15.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}