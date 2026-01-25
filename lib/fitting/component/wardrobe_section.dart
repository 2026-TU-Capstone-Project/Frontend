import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart';
import 'add_clothing_sheet.dart';

class WardrobeSection extends StatelessWidget {
  final List<Map<String, dynamic>> slots;

  const WardrobeSection({required this.slots, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OUTFIT LAYOUT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${slots.where((e) => e['image'] != null).length}/${slots.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: FittingRoomTheme.kPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...slots.map((slot) => _StylishClothingSlot(slot: slot)).toList(),
      ],
    );
  }
}

class _StylishClothingSlot extends StatelessWidget {
  final Map<String, dynamic> slot;

  const _StylishClothingSlot({required this.slot});

  @override
  Widget build(BuildContext context) {
    bool hasImage = slot['image'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showAddClothingBottomSheet(context, slot['type']),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: hasImage
                  ? Border.all(color: FittingRoomTheme.kPrimaryColor.withOpacity(0.3), width: 1)
                  : Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: hasImage
                      ? FittingRoomTheme.kPrimaryColor.withOpacity(0.08)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.white : const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                    image: hasImage
                        ? DecorationImage(
                      image: NetworkImage(slot['image']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: hasImage
                      ? null
                      : Icon(slot['icon'], color: Colors.grey[400], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot['type'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: hasImage ? FittingRoomTheme.kTextColor : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasImage ? '선택 완료' : (slot['hint'] ?? ''),
                        style: TextStyle(
                          color: hasImage ? FittingRoomTheme.kPrimaryColor : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: hasImage ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasImage ? FittingRoomTheme.kSecondarySoft : Colors.white,
                    border: Border.all(
                      color: hasImage ? Colors.transparent : Colors.grey[200]!,
                    ),
                  ),
                  child: Icon(
                    hasImage ? Icons.edit : Icons.add,
                    size: 18,
                    color: hasImage ? FittingRoomTheme.kPrimaryColor : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}