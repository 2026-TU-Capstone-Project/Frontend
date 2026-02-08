import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart'; // ip 주소
import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_client.dart';
import '../theme/fitting_room_theme.dart';

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

class _AiStylistInputState extends State<AiStylistInput> with SingleTickerProviderStateMixin {
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
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: 'ACCESS_TOKEN');

      if (accessToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final client = ClothesClient(dio, baseUrl: 'http://$ip');
      final response = await client.getRecommendations(query: query);

      if (mounted) {
        setState(() {
          _results = response.data?.recommendations ?? [];
        });
      }
    } catch (e) {
      print("AI 추천 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("추천 중 오류가 발생했습니다.")),
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


            if (!_hasSearched) ...[

              _buildAiMessageBubble(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "안녕하세요! 오늘은 어떤 스타일을 찾으시나요?",
                      style: _baseTextStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
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
            ] else ...[

              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  margin: const EdgeInsets.only(left: 40, bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PRIMARYCOLOR, Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PRIMARYCOLOR.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _userQuery,
                    style: _baseTextStyle.copyWith(
                      color: Colors.white,
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
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: PRIMARYCOLOR)),
                      const SizedBox(width: 12),
                      Text("AI가 옷장을 분석 중이에요...", style: _baseTextStyle.copyWith(color: Colors.grey[600], fontSize: 14)),
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
                _buildAiMessageBubble(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "요청하신 스타일에 딱 맞는 코디를 찾았어요! 🎁",
                        style: _baseTextStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildResultList(),
                    ],
                  ),
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
                    child: Text("  다른 스타일 추천받기", style: _baseTextStyle.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }



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
            child: const Icon(Icons.auto_awesome,
                color: PRIMARYCOLOR, size: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                        letterSpacing: -0.2
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '당신만의 퍼스널 코디네이터',
              style: _baseTextStyle.copyWith(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w400),
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
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
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
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, letterSpacing: -0.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          suffixIcon: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: PRIMARYCOLOR,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
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
      children: widget.chips.map((chip) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.controller.text = chip['label'];
            _searchAiStyle();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      )).toList(),
    );
  }

  Widget _buildResultList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        final imageUrl = item.resultImgUrl ?? "";
        final score = item.score ?? 0.0;
        final analysis = item.styleAnalysis ?? "분석 정보 없음";

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  height: 450,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 450,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: PRIMARYCOLOR,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            "AI 매칭률 ${(score * 100).toInt()}%",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      analysis,
                      style: _baseTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}