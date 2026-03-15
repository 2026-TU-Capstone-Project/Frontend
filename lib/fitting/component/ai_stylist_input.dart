import 'package:capstone_fe/chat/view/ai_chat_screen.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:flutter/material.dart';

class AiStylistInput extends StatefulWidget {
  final String? nickname;
  const AiStylistInput({super.key, this.nickname});

  @override
  State<AiStylistInput> createState() => _AiStylistInputState();
}

class _AiStylistInputState extends State<AiStylistInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _suggestions = [
    {'label': '오늘 날씨 코디', 'query': '오늘 날씨에 맞는 코디 추천해줘'},
    {'label': '데이트 룩', 'query': '데이트 코디 추천해줘'},
    {'label': '출근룩 추천', 'query': '캐주얼한 오피스룩 알려줘'},
    {'label': '미니멀 스타일', 'query': '미니멀한 스타일 보여줘'},
    {'label': '주말 나들이', 'query': '주말 나들이 코디 알려줘'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            AiChatScreen(initialMessage: q),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.46,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE9),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          const Positioned(
            bottom: 0, left: 0, right: 0, height: 220,
            child: _GradientBlob(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'HELLO ${(widget.nickname ?? '').toUpperCase()}!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A9A9E),
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '무엇을 도와드릴까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.center,
                  children: _suggestions
                      .map((s) => _buildChip(s['label']!, s['query']!))
                      .toList(),
                ),
                const Spacer(),
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String query) {
    return GestureDetector(
      onTap: () => _submit(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return Container(
          padding: const EdgeInsets.only(left: 18, right: 5, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF1D1D1F)),
                  decoration: const InputDecoration(
                    hintText: 'AI 스타일리스트에게 물어보세요',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFAEAEB2),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: hasText ? () => _submit(_controller.text) : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.ACCENT_PURPLE
                        : AppColors.PRIMARYCOLOR,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasText ? Icons.send_rounded : Icons.mic_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 하단 그라디언트 블롭 ──────────────────────────────────────────────────────

class _GradientBlob extends StatelessWidget {
  const _GradientBlob();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(), size: Size.infinite);
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (
        Offset(size.width * 0.15, size.height * 0.55),
        size.width * 0.52,
        const Color(0xFFFF6040),
      ),
      (
        Offset(size.width * 0.45, size.height * 0.40),
        size.width * 0.45,
        const Color(0xFFFFAA30),
      ),
      (
        Offset(size.width * 0.80, size.height * 0.60),
        size.width * 0.42,
        const Color(0xFF8B5CF6),
      ),
      (
        Offset(size.width * 0.60, size.height * 0.75),
        size.width * 0.38,
        const Color(0xFF3B82F6),
      ),
      (
        Offset(size.width * 0.25, size.height * 0.85),
        size.width * 0.35,
        const Color(0xFFEC4899),
      ),
    ];

    for (final (center, radius, color) in blobs) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.75),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => false;
}
