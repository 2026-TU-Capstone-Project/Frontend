import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';

const _kBg = Color(0xFFF5F5F7);

class ClothesDetailBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required ClothesModel cloth,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return _ClothesDetailContent(
              cloth: cloth,
              scrollController: scrollController,
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}

class _ClothesDetailContent extends StatelessWidget {
  final ClothesModel cloth;
  final ScrollController scrollController;
  final VoidCallback? onDelete;

  const _ClothesDetailContent({
    required this.cloth,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.BORDER_COLOR,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.ERROR_COLOR,
                      ),
                      onPressed: onDelete,
                      tooltip: '삭제',
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      cloth.imgUrl ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.INPUT_BG_COLOR,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.MEDIUM_GREY,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isNotEmpty(cloth.category))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cloth.category!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.MEDIUM_GREY,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    cloth.name ?? "이름 없는 옷",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.BLACK,
                      height: 1.3,
                    ),
                  ),
                  if (_isNotEmpty(cloth.brand)) ...[
                    const SizedBox(height: 6),
                    Text(
                      cloth.brand!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.BODY_COLOR,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (cloth.price != null && cloth.price! > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      _formatPrice(cloth.price!),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.BLACK,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_isNotEmpty(cloth.buyUrl))
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _launchUrl(cloth.buyUrl!),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                        label: const Text("구매 링크로 이동"),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.PRIMARYCOLOR,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (_isNotEmpty(cloth.buyUrl)) const SizedBox(height: 24),
                  const Divider(height: 32, color: AppColors.BORDER_COLOR),
                  ..._buildDetailSection("기본 정보", [
                    _row("색상", cloth.color),
                    _row("계절", cloth.season),
                    _row("소재", cloth.material),
                    _row("두께감", cloth.thickness),
                  ]),
                  ..._buildDetailSection("스타일 · 착용", [
                    _row("스타일", cloth.style),
                    _row("핏", cloth.fit),
                    _row("기장", cloth.length),
                    _row("착용 상황", cloth.occasion),
                  ]),
                  ..._buildDetailSection("디테일", [
                    _row("넥라인", cloth.neckLine),
                    _row("소매", cloth.sleeveType),
                    _row("패턴", cloth.pattern),
                    _row("단추/잠금", cloth.closure),
                    _row("질감", cloth.texture),
                  ]),
                  if (_isNotEmpty(cloth.detail)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "상세 설명",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.BLACK,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cloth.detail!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.BODY_COLOR,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isNotEmpty(String? v) => v != null && v.trim().isNotEmpty;

  String _formatPrice(int price) {
    if (price >= 10000) {
      return "${(price / 10000).toStringAsFixed(price % 10000 == 0 ? 0 : 1)}만 원";
    }
    return "$price 원";
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  List<Widget> _buildDetailSection(String title, List<Widget?> rows) {
    final valid = rows.whereType<Widget>().toList();
    if (valid.isEmpty) return [];
    return [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.BLACK,
        ),
      ),
      const SizedBox(height: 10),
      ...valid,
      const SizedBox(height: 20),
    ];
  }

  Widget? _row(String label, String? value) {
    if (!_isNotEmpty(value)) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.MEDIUM_GREY,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                color: AppColors.BLACK,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
