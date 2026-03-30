import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/model/fit_type.dart';

/// 핏감 3지선다 카드 셀렉터
/// isReady(전신사진 + 상의 선택 완료) 시 위로 슬라이드-인 애니메이션으로 등장
class FitTypeSelector extends StatefulWidget {
  final FitType selected;
  final ValueChanged<FitType> onChanged;
  final bool isEnabled;

  const FitTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  State<FitTypeSelector> createState() => _FitTypeSelectorState();
}

class _FitTypeSelectorState extends State<FitTypeSelector> {
  // 탭 시 바운스 효과를 위한 눌림 상태
  FitType? _pressing;

  void _onTap(FitType type) {
    if (!widget.isEnabled) return;
    HapticFeedback.selectionClick();
    widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isEnabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '핏감 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.BLACK,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: FitType.values.map((type) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type != FitType.oversize ? 8 : 0,
                  ),
                  child: _FitCard(
                    type: type,
                    isSelected: widget.selected == type,
                    isPressing: _pressing == type,
                    onTapDown: () => setState(() => _pressing = type),
                    onTapUp: () {
                      setState(() => _pressing = null);
                      _onTap(type);
                    },
                    onTapCancel: () => setState(() => _pressing = null),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FitCard extends StatelessWidget {
  final FitType type;
  final bool isSelected;
  final bool isPressing;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const _FitCard({
    required this.type,
    required this.isSelected,
    required this.isPressing,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  IconData get _icon {
    switch (type) {
      case FitType.slim:
        return Icons.vertical_align_center_rounded;
      case FitType.regular:
        return Icons.checkroom_rounded;
      case FitType.oversize:
        return Icons.zoom_out_map_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressing ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.PRIMARYCOLOR : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.PRIMARYCOLOR
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.PRIMARYCOLOR.withValues(alpha: 0.20),
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
                _icon,
                size: 26,
                color: isSelected ? Colors.white : AppColors.BODY_COLOR,
              ),
              const SizedBox(height: 6),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.BLACK,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type.description,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.MEDIUM_GREY,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
