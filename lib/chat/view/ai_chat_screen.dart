import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:capstone_fe/common/component/loading_indicator.dart';
import 'package:capstone_fe/chat/model/chat_model.dart';
import 'package:capstone_fe/chat/provider/chat_provider.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/fitting/util/weather_util.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';

// =============================================================================
// AI 스타일리스트 채팅 화면 — Premium Redesign
// =============================================================================

class AiChatScreen extends ConsumerStatefulWidget {
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

  // Quick-reply 추천 칩
  static const List<String> _quickReplies = [
    '오늘 날씨에 맞는 코디',
    '트렌디 룩',
    '오피스 룩',
    '데님 스타일링',
    '데이트 코디',
    '미니멀 룩',
  ];

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
    final weather = ref.watch(cachedWeatherProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // 4. Floating Context Header
            if (weather != null) _ContextHeader(weather: weather),

            // 메시지 영역
            Expanded(
              child: chatState.messages.isEmpty
                  ? _EmptyState(onSuggestionTap: _sendMessage)
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            chatState.messages.length - 1 - index;
                        return _buildMessageItem(
                          chatState.messages[reversedIndex],
                        );
                      },
                    ),
            ),

            // 2. Quick Reply Recommendation Chips
            if (chatState.messages.isNotEmpty)
              _QuickReplyChips(
                chips: _quickReplies,
                onTap: _sendMessage,
              ),

            // 5. Polished Input Bar
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
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ACCENT_PURPLE, AppColors.ACCENT_BLUE],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
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
// 4. Floating Context Header — 날씨 / 컨텍스트 바
// =============================================================================

class _ContextHeader extends StatelessWidget {
  final WeatherInfo weather;

  const _ContextHeader({required this.weather});

  @override
  Widget build(BuildContext context) {
    final label = weatherLabel(weather.conditionCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(label.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '${weather.temp.round()}°C · ${label.description}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          if (weather.cityName.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '· ${weather.cityName}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6E6E73),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '날씨 반영 중',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.ACCENT_PURPLE,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. Quick Reply Recommendation Chips
// =============================================================================

class _QuickReplyChips extends StatelessWidget {
  final List<String> chips;
  final void Function(String) onTap;

  const _QuickReplyChips({required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(chips[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              chips[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ACCENT_PURPLE,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 빈 화면 — 첫 진입 시 빠른 질문 제안 칩
// =============================================================================

class _EmptyState extends ConsumerWidget {
  final void Function(String) onSuggestionTap;

  const _EmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(userMeProvider).valueOrNull?.nickname;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Lottie.asset(
                'asset/json/ai_animation.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppColors.ACCENT_PURPLE,
                  Color(0xFFB8A8FF),
                ],
              ).createShader(bounds),
              child: Text(
                nickname != null && nickname.isNotEmpty
                    ? '안녕하세요, $nickname 님'
                    : '안녕하세요',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '오늘 무엇을 도와드릴까요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            _SuggestionGrid(onTap: onSuggestionTap),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 추천 카드 그리드 — 2×2, 카테고리 아이콘 + 타이틀 + 설명
// =============================================================================

class _SuggestionItem {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final String prompt;

  const _SuggestionItem({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });
}

class _SuggestionGrid extends StatelessWidget {
  final void Function(String) onTap;

  const _SuggestionGrid({required this.onTap});

  static const List<_SuggestionItem> _items = [
    _SuggestionItem(
      icon: Icons.wb_sunny_rounded,
      tint: Color(0xFFFFA726),
      title: '오늘 날씨 코디',
      subtitle: '날씨에 딱 맞는 추천',
      prompt: '오늘 날씨에 맞는 코디 추천해줘',
    ),
    _SuggestionItem(
      icon: Icons.favorite_rounded,
      tint: Color(0xFFFF6B9D),
      title: '데이트 룩',
      subtitle: '데이트·소개팅 코디',
      prompt: '데이트 코디 추천해줘',
    ),
    _SuggestionItem(
      icon: Icons.work_outline_rounded,
      tint: Color(0xFF5B8DEF),
      title: '오피스 룩',
      subtitle: '캐주얼한 오피스 스타일',
      prompt: '캐주얼한 오피스룩 알려줘',
    ),
    _SuggestionItem(
      icon: Icons.auto_awesome_rounded,
      tint: AppColors.ACCENT_PURPLE,
      title: '미니멀 룩',
      subtitle: '심플한 데일리 룩',
      prompt: '미니멀한 스타일 보여줘',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 24 * 2 - 10) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _items
          .map(
            (item) => SizedBox(
              width: width,
              child: _SuggestionCard(
                item: item,
                onTap: () => onTap(item.prompt),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _SuggestionItem item;
  final VoidCallback onTap;

  const _SuggestionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: item.tint.withValues(alpha: 0.08),
        highlightColor: item.tint.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.tint, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E6E73),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. Premium User Bubble (오른쪽, 그라데이션)
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.3),
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
// 1. Premium Bot Bubble (왼쪽, 소프트 네이비 그라데이션 + 스타일리스트 아이콘)
// =============================================================================

class _BotBubble extends StatelessWidget {
  final ChatMessage message;

  const _BotBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final data = message.responseData;

    final outfits =
        data?.recommendations?.recommendations
            ?.whereType<RecommendationItem>()
            .toList() ??
        [];
    final tops =
        data?.recommendationsTops?.items
            ?.whereType<ClothesScoreItem>()
            .toList() ??
        [];
    final bottoms =
        data?.recommendationsBottoms?.items
            ?.whereType<ClothesScoreItem>()
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 스타일리스트 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B85F5), Color(0xFF6366F1)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 스타일리스트 이름 태그
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'AI Stylist',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ACCENT_PURPLE,
                    ),
                  ),
                ),

                // 텍스트 말풍선 (소프트 그라데이션)
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
        // 소프트 네이비 그라데이션
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF0EEFF), // 아주 연한 퍼플
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.15),
          width: 1,
        ),
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
// 3. Dynamic Typing Indicator — "AI 스타일리스트가 코디를 고르고 있어요..."
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
          // 아이콘 (애니메이션 포함)
          const _PulsingAiIcon(),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'AI Stylist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ACCENT_PURPLE,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF0EEFF),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _TypingDots(),
                    const SizedBox(width: 10),
                    Text(
                      '코디를 고르고 있어요...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 로딩 중 AI 아이콘 애니메이션
class _PulsingAiIcon extends StatelessWidget {
  const _PulsingAiIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Lottie.asset(
        'asset/json/ai_animation.json',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// 세 개의 점이 순서대로 튀는 타이핑 애니메이션
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.translate(
              offset: Offset(0, -4 * _anims[i].value),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.ACCENT_PURPLE.withValues(
                    alpha: 0.4 + 0.4 * _anims[i].value,
                  ),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null && imgUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, imgUrl),
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _ShimmerBox(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    ),
                  )
                else
                  _placeholder(),
                if (score != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
          ),
          if (analysis != null && analysis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  static Widget _placeholder() {
    return Container(
      color: const Color(0xFFE5E5EA),
      child: const Icon(
        Icons.checkroom_outlined,
        size: 48,
        color: Color(0xFFAEAEB2),
      ),
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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null && imgUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, imgUrl),
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _ShimmerBox(),
                      errorWidget: (_, __, ___) => _clothesPlaceholder(),
                    ),
                  )
                else
                  _clothesPlaceholder(),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
          ),
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

  static Widget _clothesPlaceholder() {
    return Container(
      color: const Color(0xFFE5E5EA),
      child: const Icon(
        Icons.checkroom_outlined,
        size: 36,
        color: Color(0xFFAEAEB2),
      ),
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
// 5. Polished Input Bar — 필 모양 + 플러스 아이콘 + 전송 애니메이션
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 플러스 아이콘 (이미지 업로드 힌트)
          GestureDetector(
            onTap: () {
              // 향후 이미지 업로드 기능 연결 가능
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Color(0xFF6E6E73),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 필 모양 텍스트 필드
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSending
                      ? const Color(0xFFE5E5EA)
                      : AppColors.ACCENT_PURPLE.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style:
                    const TextStyle(fontSize: 15, color: Color(0xFF1D1D1F)),
                decoration: const InputDecoration(
                  hintText: '스타일, 날씨, 상황을 알려주세요...',
                  hintStyle: TextStyle(
                    color: Color(0xFFAEAEB2),
                    fontSize: 15,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 전송 버튼 (스케일 애니메이션)
          _SendButton(isSending: isSending, onSend: onSend),
        ],
      ),
    );
  }
}

/// 전송 버튼 — 탭 시 스케일 애니메이션
class _SendButton extends StatefulWidget {
  final bool isSending;
  final VoidCallback onSend;

  const _SendButton({required this.isSending, required this.onSend});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isSending) _scaleCtrl.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleCtrl.reverse();
    if (!widget.isSending) widget.onSend();
  }

  void _handleTapCancel() {
    _scaleCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: widget.isSending
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ACCENT_PURPLE, AppColors.ACCENT_BLUE],
                  ),
            color: widget.isSending
                ? AppColors.ACCENT_PURPLE.withValues(alpha: 0.4)
                : null,
            shape: BoxShape.circle,
            boxShadow: widget.isSending
                ? null
                : [
                    BoxShadow(
                      color: AppColors.ACCENT_PURPLE.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.isSending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: LoadingIndicator(size: 24),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// 이미지 로딩 Shimmer 플레이스홀더
// =============================================================================

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const [
                Color(0xFFE5E5EA),
                Color(0xFFF5F5F7),
                Color(0xFFE5E5EA),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// 전체 화면 이미지 뷰어
// =============================================================================

void _showFullScreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      fullscreenDialog: true,
      pageBuilder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    minScale: 0.5,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
