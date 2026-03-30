import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/model/fit_type.dart';

/// 가상피팅 시작 전 핏감(슬림/레귤러/오버)을 선택하는 바텀시트.
/// 선택 후 "피팅 시작" 버튼을 누르면 [FitType]을 반환하며 닫힘.
class FitTypeSelectorSheet extends StatefulWidget {
  const FitTypeSelectorSheet({super.key});

  /// 바텀시트를 표시하고, 사용자가 선택한 [FitType]을 반환.
  /// 시트를 닫으면(바깥 탭 등) null.
  static Future<FitType?> show(BuildContext context) {
    return showModalBottomSheet<FitType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FitTypeSelectorSheet(),
    );
  }

  @override
  State<FitTypeSelectorSheet> createState() => _FitTypeSelectorSheetState();
}

class _FitTypeSelectorSheetState extends State<FitTypeSelectorSheet> {
  FitType _selected = FitType.regular; // 기본값: 레귤러핏

  static const _fitIcons = <FitType, IconData>{
    FitType.slim: Icons.compress,
    FitType.regular: Icons.straighten,
    FitType.oversize: Icons.open_in_full_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.BORDER_COLOR,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // 타이틀
            const Text(
              '핏감 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.BLACK,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '원하는 핏감을 선택하고 피팅을 시작하세요',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.MEDIUM_GREY,
              ),
            ),
            const SizedBox(height: 24),
            // 3지선다 카드
            Row(
              children: FitType.values.map((type) {
                final isSelected = type == _selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(
                        left: type == FitType.slim ? 0 : 6,
                        right: type == FitType.oversize ? 0 : 6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.PRIMARYCOLOR
                            : AppColors.INPUT_BG_COLOR,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.PRIMARYCOLOR
                              : AppColors.BORDER_COLOR,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.PRIMARYCOLOR
                                      .withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _fitIcons[type],
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : AppColors.MEDIUM_GREY,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.BLACK,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // 설명 텍스트 행
            Row(
              children: FitType.values.map((type) {
                final isSelected = type == _selected;
                return Expanded(
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.BLACK
                            : AppColors.MEDIUM_GREY,
                      ),
                      child: Text(type.description),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            // CTA 버튼: 피팅 시작
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _selected);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.PRIMARYCOLOR,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.PRIMARYCOLOR.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '피팅 시작하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
