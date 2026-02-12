import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';

import '../clothes/repository/recommend_repository.dart';

class AiStylistInput extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> chips;

  const AiStylistInput({
    required this.controller,
    required this.chips,
    super.key,
  });

  @override
  State<AiStylistInput> createState() => _AiStylistInputState();
}

class _AiStylistInputState extends State<AiStylistInput>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<RecommendationModel> _results = [];
  bool _hasSearched = false;
  String _userQuery = "";

  Future<void> _searchAiStyle() async {
    final query = widget.controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _userQuery = query;
      _results.clear();
      widget.controller.clear();
    });

    try {
      final dio = Dio();
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'ACCESS_TOKEN');

      if (accessToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final repository = RecommendRepository(dio, baseUrl: 'http://$ip');
      final response = await repository.getRecommendations(query: query);

      if (mounted) {
        setState(() {
          _results = response.data?.recommendations ?? [];
        });
      }
    } catch (e) {
      debugPrint("🚨 AI 추천 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("추천 중 오류가 발생했습니다. 다시 시도해주세요.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetSearch() {
    setState(() {
      _hasSearched = false;
      _results.clear();
      _userQuery = "";
      widget.controller.clear();
    });
  }

  // ✅ 상세 정보 모달 (이미지 클릭 시 호출)
  void _showDetailModal(RecommendationModel item) {
    final score = item.score ?? 0.0;
    final analysis = item.styleAnalysis ?? "분석 정보가 없습니다.";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: PRIMARYCOLOR,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "AI 매칭률 ${(score * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "스타일 분석",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analysis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  TextStyle get _baseTextStyle => const TextStyle(
    fontFamily: 'Pretendard',
    letterSpacing: -0.5,
    color: Color(0xFF222222),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAiProfileHeader(),
            const SizedBox(height: 20),

            // 검색 전 화면
            if (!_hasSearched) ...[
              _buildAiMessageBubble(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "안녕하세요! 오늘은 어떤 스타일을 찾으시나요?",
                      style: _baseTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "구체적인 상황을 알려주시면\n더 완벽한 코디를 추천해 드릴게요 ✨",
                      style: _baseTextStyle.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChipsArea(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInputArea(isEnabled: true),
            ]
            // 검색 후 화면
            else ...[
              // ✅ [수정됨] 사용자 입력 말풍선 (평범한 회색)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(left: 40, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // 평범한 회색 배경
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(4),
                    ),
                    // 그림자 제거
                  ),
                  child: Text(
                    _userQuery,
                    style: _baseTextStyle.copyWith(
                      color: Colors.black87, // 텍스트 검정색
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              if (_isLoading)
                _buildAiMessageBubble(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PRIMARYCOLOR,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "AI가 옷장을 분석 중이에요...",
                        style: _baseTextStyle.copyWith(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_results.isEmpty)
                _buildAiMessageBubble(
                  child: Text(
                    "죄송해요, 딱 맞는 결과를 찾지 못했어요 😭\n다른 키워드로 다시 물어봐주시겠어요?",
                    style: _baseTextStyle.copyWith(height: 1.5),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAiMessageBubble(
                      child: Text(
                        "요청하신 스타일에 딱 맞는 코디를 찾았어요!\n사진을 눌러 상세 정보를 확인해보세요. 👇",
                        style: _baseTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ✅ [수정됨] 가로 스크롤 결과 리스트
                    _buildResultHorizontalList(),
                  ],
                ),

              const SizedBox(height: 20),

              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _resetSearch,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "  다른 스타일 추천받기",
                      style: _baseTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ [수정됨] 결과를 가로 스크롤로 보여주는 위젯
  Widget _buildResultHorizontalList() {
    return SizedBox(
      height: 400, // 이미지 높이 확보
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _results.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _results[index];
          final imageUrl = item.resultImgUrl ?? "";

          return GestureDetector(
            onTap: () => _showDetailModal(item), // 클릭 시 모달 띄우기
            child: Container(
              width: 300, // 이미지 너비
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // 힌트 오버레이 (클릭 유도)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "터치하여 분석 보기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (헤더, 말풍선, 인풋, 칩 위젯 등 기존 코드는 그대로 사용)

  Widget _buildAiProfileHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFE1BEE7), PRIMARYCOLOR],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: PRIMARYCOLOR,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AI Stylist',
                  style: _baseTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: PRIMARYCOLOR.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: PRIMARYCOLOR,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '당신만의 퍼스널 코디네이터',
              style: _baseTextStyle.copyWith(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiMessageBubble({required Widget child}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildInputArea({required bool isEnabled}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        enabled: isEnabled,
        style: _baseTextStyle.copyWith(fontSize: 15),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _searchAiStyle(),
        decoration: InputDecoration(
          hintText: '예) 이번 주말 소개팅 룩 추천해줘',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: PRIMARYCOLOR,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: isEnabled ? _searchAiStyle : null,
          ),
        ),
      ),
    );
  }

  Widget _buildChipsArea() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.chips
          .map(
            (chip) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.controller.text = chip['label'];
              _searchAiStyle();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip['icon'], size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    chip['label'].toString().split(' ')[0],
                    style: _baseTextStyle.copyWith(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}