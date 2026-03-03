import 'package:flutter/material.dart';
import 'package:capstone_fe/chat/view/ai_chat_screen.dart';
import 'package:capstone_fe/common/const/colors.dart';

// =============================================================================
// 홈 검색창 탭 시 호출 — 기존 홈 화면 위에 팝업 오버레이로 표시
//
// topOffset: 검색창 하단 y좌표 (HomeScreen에서 GlobalKey로 측정해서 전달)
// =============================================================================

void showAiSearchOverlay(BuildContext context, {required double topOffset}) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent, // 홈 화면이 그대로 보임
    barrierDismissible: false,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => _AiSearchOverlay(
      topOffset: topOffset,
      onNavigateToChat: (query) {
        Navigator.of(ctx).pop(); // 오버레이 닫기
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AiChatScreen(initialMessage: query),
          ),
        );
      },
      onClose: () => Navigator.of(ctx).pop(),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// =============================================================================
// 오버레이 메인 위젯
// =============================================================================

class _AiSearchOverlay extends StatefulWidget {
  final double topOffset;
  final void Function(String) onNavigateToChat;
  final VoidCallback onClose;

  const _AiSearchOverlay({
    required this.topOffset,
    required this.onNavigateToChat,
    required this.onClose,
  });

  @override
  State<_AiSearchOverlay> createState() => _AiSearchOverlayState();
}

class _AiSearchOverlayState extends State<_AiSearchOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _navigating = false;

  // ── 드래그-투-디스미스 ─────────────────────────────────────────
  double _dragOffset = 0;
  late final AnimationController _snapController;
  Animation<double>? _snapAnim;

  // 리스트 최상단 여부 확인용
  final _listController = ScrollController();

  static const List<String> _trending = [
    '오늘 날씨에 맞는 코디 추천해줘',
    '데이트 코디 추천해줘',
    '캐주얼한 오피스룩 알려줘',
    '미니멀한 스타일 보여줘',
    '봄 신상 코디 추천해줘',
    '출근룩 추천해줘',
    '주말 나들이 코디 알려줘',
    '여름 데일리룩 추천해줘',
  ];

  // ── 드래그 임계값 ──────────────────────────────────────────────
  static const double _dismissThreshold = 120.0;
  static const double _dismissVelocity = 600.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onSnapTick);
  }

  void _onSnapTick() {
    if (mounted && _snapAnim != null) {
      setState(() => _dragOffset = _snapAnim!.value);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  // ── 드래그 핸들러 ──────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dy < 0 && _dragOffset == 0) return; // 위로는 안 당겨짐
    setState(() {
      _dragOffset = (_dragOffset + d.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_dragOffset > _dismissThreshold || velocity > _dismissVelocity) {
      widget.onClose();
    } else {
      // 제자리로 스냅
      _snapAnim = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
      );
      _snapController.forward(from: 0);
    }
  }

  // ── 실시간 검색어 탭: 타이핑 애니메이션 후 채팅 이동 ──────────

  Future<void> _onSuggestionTap(String query) async {
    if (_navigating) return;
    _navigating = true;

    _controller.clear();
    for (var i = 0; i <= query.length; i++) {
      if (!mounted) return;
      setState(() {
        _controller.text = query.substring(0, i);
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      });
      await Future.delayed(const Duration(milliseconds: 18));
    }

    if (!mounted) return;
    widget.onNavigateToChat(query);
  }

  void _onSubmit() {
    final q = _controller.text.trim();
    if (q.isEmpty || _navigating) return;
    _navigating = true;
    widget.onNavigateToChat(q);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── 배경 전체: 탭하면 닫힘 ──────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // ── 오버레이 패널 ─────────────────────────────────────
          Positioned(
            top: widget.topOffset,
            left: 0,
            right: 0,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: GestureDetector(
                onTap: () {}, // 내부 탭은 닫힘 방지
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 드래그 핸들 (이 영역만 드래그로 닫힘) ──
                      GestureDetector(
                        onVerticalDragUpdate: _onDragUpdate,
                        onVerticalDragEnd: _onDragEnd,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            // 핸들 바
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 8),
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1D1D6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            // 헤더 행
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18,
                                    color: AppColors.ACCENT_PURPLE,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '실시간 검색어',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D1D1F),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'AI 추천',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ACCENT_PURPLE,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 구분선
                      const Divider(height: 1, color: Color(0xFFF2F2F7)),

                      // ── 검색어 목록 ─────────────────────────────
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            // 리스트 최상단에서 아래로 overscroll → 패널 드래그
                            if (n is OverscrollNotification &&
                                n.overscroll > 0) {
                              _onDragUpdate(DragUpdateDetails(
                                globalPosition: Offset.zero,
                                delta: Offset(0, n.overscroll),
                                primaryDelta: n.overscroll,
                              ));
                            }
                            if (n is ScrollEndNotification &&
                                _dragOffset > 0) {
                              _onDragEnd(DragEndDetails(
                                primaryVelocity: 0,
                              ));
                            }
                            return false;
                          },
                          child: ListView(
                            controller: _listController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: List.generate(
                              _trending.length,
                              (i) => _TrendingItem(
                                rank: i + 1,
                                query: _trending[i],
                                isHot: i < 3,
                                onTap: () => _onSuggestionTap(_trending[i]),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 구분선
                      const Divider(height: 1, color: Color(0xFFE5E5EA)),

                      // ── 하단 입력창 ─────────────────────────────
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.ACCENT_PURPLE
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '직접 질문을 입력해보세요...',
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
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) => _onSubmit(),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _onSubmit,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.ACCENT_PURPLE,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
// 실시간 검색어 항목
// =============================================================================

class _TrendingItem extends StatelessWidget {
  final int rank;
  final String query;
  final bool isHot;
  final VoidCallback onTap;

  const _TrendingItem({
    required this.rank,
    required this.query,
    required this.isHot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // 순위
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isHot
                      ? AppColors.ACCENT_PURPLE
                      : const Color(0xFFAEAEB2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 검색어
            Expanded(
              child: Text(
                query,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
            // HOT 배지 (상위 3개)
            if (isHot)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      AppColors.ACCENT_PURPLE.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'HOT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ACCENT_PURPLE,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
