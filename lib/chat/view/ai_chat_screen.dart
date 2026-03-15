import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/chat/model/chat_model.dart';
import 'package:capstone_fe/chat/provider/chat_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';

// =============================================================================
// AI 스타일리스트 채팅 화면
// =============================================================================

class AiChatScreen extends ConsumerStatefulWidget {
  /// 홈 검색바 초기 입력값 (선택적으로 첫 메시지를 미리 채울 때 사용)
  final String? initialMessage;

  const AiChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();

  // 디자인 상수
  static const Color _bgColor = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF6E6E73);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      // 외부 탭 시 키보드 닫기
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty
                  ? _EmptyState(
                      onSuggestionTap: _sendMessage,
                    )
                  : ListView.builder(
                      // reverse: true — 새 메시지가 항상 하단에 표시, 수동 스크롤 불필요
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            chatState.messages.length - 1 - index;
                        return _buildMessageItem(
                            chatState.messages[reversedIndex]);
                      },
                    ),
            ),
            _InputBar(
              controller: _inputController,
              isSending: chatState.isSending,
              onSend: () => _sendMessage(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 스타일리스트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'LookPick Assistant',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E5EA)),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isLoading) return const _LoadingBubble();
    if (message.errorMessage != null) {
      return _ErrorBubble(message: message.errorMessage!);
    }
    if (message.isUser) return _UserBubble(text: message.text ?? '');
    return _BotBubble(message: message);
  }
}

// =============================================================================
// 빈 화면 — 첫 진입 시 빠른 질문 제안 칩
// =============================================================================

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestionTap;

  const _EmptyState({required this.onSuggestionTap});

  static const _suggestions = [
    '오늘 날씨에 맞는 코디 추천해줘',
    '데이트 코디 추천해줘',
    '캐주얼한 오피스룩 알려줘',
    '미니멀한 스타일 보여줘',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ACCENT_PURPLE, AppColors.ACCENT_BLUE],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI 스타일리스트',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '원하는 스타일, 날씨, 상황을 알려주세요.\n맞춤 코디를 추천해드릴게요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6E6E73),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(
                        text: s,
                        onTap: () => onSuggestionTap(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ACCENT_PURPLE,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 말풍선 — 유저 (오른쪽, 보라색)
// =============================================================================

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 60),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ACCENT_PURPLE, AppColors.ACCENT_BLUE],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 말풍선 — 봇 (왼쪽, 흰색 + 추천 카드)
// =============================================================================

class _BotBubble extends StatelessWidget {
  final ChatMessage message;

  const _BotBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final data = message.responseData;

    final outfits = data?.recommendations?.recommendations
            ?.whereType<RecommendationItem>()
            .toList() ??
        [];
    final tops = data?.recommendationsTops?.items
            ?.whereType<ClothesScoreItem>()
            .toList() ??
        [];
    final bottoms = data?.recommendationsBottoms?.items
            ?.whereType<ClothesScoreItem>()
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아이콘
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B85F5), Color(0xFF6366F1)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 텍스트 말풍선
                if (message.text != null && message.text!.isNotEmpty)
                  _BotTextBubble(text: message.text!),

                // 코디 추천 (전신 이미지 카드)
                if (outfits.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _OutfitRecommendationSection(items: outfits),
                ],

                // 상의 추천
                if (tops.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ClothesSection(title: '추천 상의', items: tops),
                ],

                // 하의 추천
                if (bottoms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ClothesSection(title: '추천 하의', items: bottoms),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotTextBubble extends StatelessWidget {
  final String text;

  const _BotTextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontSize: 15,
          height: 1.55,
        ),
      ),
    );
  }
}

// =============================================================================
// 로딩 말풍선 — 타이핑 인디케이터
// =============================================================================

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B85F5), Color(0xFF6366F1)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingIndicator(),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _anims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.translate(
              offset: Offset(0, -5 * _anims[i].value),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 에러 말풍선
// =============================================================================

class _ErrorBubble extends StatelessWidget {
  final String message;

  const _ErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 16, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 코디 추천 섹션 (resultImgUrl 전신 이미지)
// =============================================================================

class _OutfitRecommendationSection extends StatelessWidget {
  final List<RecommendationItem> items;

  const _OutfitRecommendationSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.style_rounded,
          label: '코디 추천 ${items.length}개',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _OutfitCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final RecommendationItem item;

  const _OutfitCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final imgUrl = item.resultImgUrl;
    final score = item.score;
    final analysis = item.styleAnalysis;

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null && imgUrl.isNotEmpty)
                  Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                else
                  _placeholder(),
                // 점수 배지
                if (score != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
          ),
          // 스타일 분석 텍스트
          if (analysis != null && analysis.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                analysis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1D1D1F),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE5E5EA),
      child: const Icon(Icons.checkroom_outlined,
          size: 48, color: Color(0xFFAEAEB2)),
    );
  }
}

// =============================================================================
// 상의 / 하의 추천 섹션
// =============================================================================

class _ClothesSection extends StatelessWidget {
  final String title;
  final List<ClothesScoreItem> items;

  const _ClothesSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.checkroom_rounded,
          label: '$title ${items.length}개',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ClothesCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _ClothesCard extends StatelessWidget {
  final ClothesScoreItem item;

  const _ClothesCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final clothes = item.clothes;
    final imgUrl = clothes?.imgUrl;
    final name = clothes?.name ?? '';
    final brand = clothes?.brand ?? '';
    final score = item.score;

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null && imgUrl.isNotEmpty)
                  Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                else
                  _placeholder(),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
          ),
          // 이름 / 브랜드
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    brand,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6E6E73),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE5E5EA),
      child: const Icon(Icons.checkroom_outlined,
          size: 36, color: Color(0xFFAEAEB2)),
    );
  }
}

// =============================================================================
// 공통 위젯
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.ACCENT_PURPLE),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ACCENT_PURPLE,
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// 하단 입력 바
// =============================================================================

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSending
                      ? const Color(0xFFE5E5EA)
                      : AppColors.ACCENT_PURPLE.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  hintText: '스타일, 날씨, 상황을 알려주세요...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFAEAEB2), fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSending
                    ? AppColors.ACCENT_PURPLE.withValues(alpha: 0.45)
                    : AppColors.ACCENT_PURPLE,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
