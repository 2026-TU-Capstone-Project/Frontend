// file: lib/feed/component/worn_product_card.dart

import 'package:capstone_fe/common/const/colors.dart';
import 'package:flutter/material.dart';

class WornProductCard extends StatelessWidget {
  final String? imageUrl;
  final String productName;
  final String label;
  final VoidCallback? onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  const WornProductCard({
    super.key,
    this.imageUrl,
    required this.productName,
    required this.label,
    this.onTap,
    this.isBookmarked = false,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.BORDER_COLOR),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.BLACK)),
                const SizedBox(height: 4),
                Text(productName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.BLACK,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onBookmarkTap != null)
            IconButton(
              onPressed: onBookmarkTap,
              icon: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isBookmarked ? AppColors.BLACK : AppColors.MEDIUM_GREY,
              ),
              tooltip: isBookmarked ? '북마크 해제' : '북마크',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _placeholder() => Container(
      color: AppColors.BORDER_COLOR,
      child: const Icon(Icons.checkroom_rounded,
          size: 36, color: AppColors.MEDIUM_GREY));
}
