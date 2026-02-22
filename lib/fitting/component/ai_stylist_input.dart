import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/clothes/model/recommend_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
  late final PageController _resultPageController;

  @override
  void initState() {
    super.initState();
    _resultPageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _resultPageController.dispose();
    super.dispose();
  }

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
    _resultPageController.jumpToPage(0);

    try {
      final dio = createAuthDio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 20);
      final repository = RecommendRepository(dio, baseUrl: baseUrl);
      final response = await repository.getRecommendations(query: query);

      if (mounted) {
        final list = response.data?.recommendations ?? [];
        setState(() => _results = list);
        if (list.isEmpty && response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "조건에 맞는 추천이 없어요. 다른 키워드로 검색해보거나, 옷장에 저장된 피팅 결과가 있는지 확인해주세요.",
              ),
            ),
          );
        }
      }
    } on TypeError catch (e) {
      debugPrint("🚨 AI 추천 응답 파싱 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("추천 결과를 불러오는 데 실패했어요. 다시 시도해주세요.")),
        );
      }
    } on DioException catch (e) {
      debugPrint("🚨 AI 추천 API 에러: ${e.type} ${e.response?.statusCode} ${e.response?.data}");
      if (mounted) {
        String msg;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          msg = "응답이 지연되고 있어요. 네트워크를 확인한 뒤 다시 시도해주세요.";
        } else if (e.response?.data is Map && e.response?.data['message'] != null) {
          msg = e.response!.data['message'] as String;
        } else if (e.response?.statusCode == 500) {
          msg = "서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.";
        } else {
          msg = "추천 중 오류가 발생했습니다. 다시 시도해주세요.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  // ✅ 상세 정보 모달 (미니멀 테마 적용)
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
            color: AppColors.white,
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
                    color: AppColors.BORDER_COLOR,
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
                      color: AppColors.PRIMARYCOLOR, // 차콜 컬러
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
              const Text(
                "스타일 분석",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.BLACK,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analysis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.BODY_COLOR,
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
    color: AppColors.BLACK,
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
          color: AppColors.INPUT_BG_COLOR, // 배경: 아주 연한 회색
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppColors.BORDER_COLOR, width: 1.0), // 테두리: 연한 회색
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
                        color: AppColors.BODY_COLOR,
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
              // 사용자 입력 말풍선
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(left: 40, bottom: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.BORDER_COLOR, // 사용자 말풍선: 연한 회색 (통일)
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    _userQuery,
                    style: _baseTextStyle.copyWith(
                      color: AppColors.BLACK,
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
                          color: AppColors.PRIMARYCOLOR,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "AI가 옷장을 분석 중이에요...",
                        style: _baseTextStyle.copyWith(
                          color: AppColors.MEDIUM_GREY,
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
                    style: _baseTextStyle.copyWith(
                        height: 1.5, color: AppColors.BODY_COLOR),
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
                      foregroundColor: AppColors.BLACK,
                      backgroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.BORDER_COLOR),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "  다른 스타일 추천받기",
                      style: _baseTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.BODY_COLOR,
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

  // ✅ 결과 리스트 — 한 장씩 끊어서 스크롤 (PageView 스냅)
  Widget _buildResultHorizontalList() {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        itemCount: _results.length,
        padEnds: true,
        controller: _resultPageController,
        itemBuilder: (context, index) {
          final item = _results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildResultCard(item),
          );
        },
      ),
    );
  }

  /// 결과 카드 한 장 (탭 시 상세 모달)
  Widget _buildResultCard(RecommendationModel item) {
    final imageUrl = item.resultImgUrl ?? "";
    return GestureDetector(
      onTap: () => _showDetailModal(item),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: AppColors.INPUT_BG_COLOR,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.MEDIUM_GREY,
                      size: 40,
                    ),
                  ),
                ),
              ),
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
                        AppColors.BLACK.withOpacity(0.7),
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
  }

  // ✅ [수정] 헤더: 그라데이션 제거 -> 깔끔한 라인 스타일
  Widget _buildAiProfileHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.BORDER_COLOR, width: 1.5), // 깔끔한 테두리
            color: AppColors.white,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.PRIMARYCOLOR, // 아이콘 배경을 차콜로
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white, // 아이콘은 흰색
              size: 16,
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
                    color: AppColors.PRIMARYCOLOR.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.PRIMARYCOLOR,
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
                color: AppColors.MEDIUM_GREY,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ [수정] 말풍선: 그림자 줄이고 테두리 추가
  Widget _buildAiMessageBubble({required Widget child}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border:
          Border.all(color: AppColors.BORDER_COLOR, width: 1.0), // 테두리 추가
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), // 그림자 아주 연하게
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ✅ [수정] 입력창: 테두리 스타일 통일
  Widget _buildInputArea({required bool isEnabled}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.BORDER_COLOR), // 테두리
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
          hintStyle:
          const TextStyle(color: AppColors.MEDIUM_GREY, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.PRIMARYCOLOR, // 차콜색 버튼
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

  // ✅ [수정] 칩: 흰색 배경에 깔끔한 테두리
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.BORDER_COLOR), // 테두리
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip['icon'], size: 14, color: AppColors.BODY_COLOR),
                  const SizedBox(width: 6),
                  Text(
                    chip['label'].toString().split(' ')[0],
                    style: _baseTextStyle.copyWith(
                      color: AppColors.BODY_COLOR,
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