/// 의류 카테고리 판별 유틸
/// 피팅룸·옷장 선택 시트·옷장 화면 3곳에서 공통으로 사용합니다.
library;

/// 상의 슬롯 판별: 상의(TOP/SHIRT/BLOUSE) + 아우터(OUTER/COAT/JACKET) 포함
bool isTopCategory(String? category) {
  final cat = (category ?? '').toUpperCase();
  return cat.contains('TOP') ||
      cat.contains('SHIRT') ||
      cat.contains('BLOUSE') ||
      cat.contains('OUTER') ||
      cat.contains('COAT') ||
      cat.contains('JACKET') ||
      cat == '상의' ||
      cat == '아우터';
}

/// 하의 슬롯 판별: BOTTOM / PANTS / SKIRT / JEANS 포함
bool isBottomCategory(String? category) {
  final cat = (category ?? '').toUpperCase();
  return cat.contains('BOTTOM') ||
      cat.contains('PANTS') ||
      cat.contains('SKIRT') ||
      cat.contains('JEANS') ||
      cat == '하의';
}
