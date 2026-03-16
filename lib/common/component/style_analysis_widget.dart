import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';

// =============================================================================
// 내부 데이터 타입
// =============================================================================
class _StyleEntry {
  final String label;
  final String content;
  final IconData icon;

  const _StyleEntry(this.label, this.content, this.icon);
}

// =============================================================================
// 파싱 유틸리티
// =============================================================================
class StyleAnalysisParser {
  static const Map<String, IconData> _iconMap = {
    '상의': Icons.dry_cleaning_outlined,
    '하의': Icons.straighten_rounded,
    '아우터': Icons.umbrella_outlined,
    '신발': Icons.directions_walk_rounded,
    '가방': Icons.shopping_bag_outlined,
    '액세서리': Icons.watch_outlined,
    '포인트': Icons.lightbulb_outline,
    '색상': Icons.palette_outlined,
    '스타일': Icons.auto_awesome_outlined,
    '전체': Icons.checkroom_outlined,
    '코디': Icons.checkroom_outlined,
  };

  static IconData _iconFor(String label) {
    for (final entry in _iconMap.entries) {
      if (label.contains(entry.key)) return entry.value;
    }
    return Icons.fiber_manual_record_rounded;
  }

  /// 마크다운 볼드(**text**) 제거
  static String stripMarkdown(String text) =>
      text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1').trim();

  /// "**카테고리**: 내용" 또는 "카테고리: 내용" 패턴 파싱
  static List<_StyleEntry> _parseCategories(String raw) {
    final entries = <_StyleEntry>[];
    // \n 이스케이프 리터럴 → 실제 줄바꿈으로 변환 후 분리
    final lines = raw
        .replaceAll(r'\n', '\n')
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    // "(?:**)카테고리(?:**) : 내용" 패턴
    final linePattern = RegExp(
      r'^(?:\*\*)?([가-힣a-zA-Z ]{1,8})(?:\*\*)?\s*[：:\-]\s*(.+)',
    );

    for (final line in lines) {
      final match = linePattern.firstMatch(line);
      if (match != null) {
        final label = stripMarkdown(match.group(1)!).trim();
        final content = stripMarkdown(match.group(2)!).trim();
        if (label.isNotEmpty && content.isNotEmpty) {
          entries.add(_StyleEntry(label, content, _iconFor(label)));
        }
      }
    }
    return entries;
  }

  /// 칩 표시용 키워드 추출
  /// 카테고리가 파싱되면 카테고리명, 아니면 의미 있는 단어 추출
  static List<String> extractKeywords(String raw) {
    final entries = _parseCategories(raw);
    if (entries.isNotEmpty) {
      return entries.map((e) => e.label).toList();
    }
    // 카테고리 없으면 2~6자 단어 추출
    return stripMarkdown(raw)
        .replaceAll(r'\n', ' ')
        .split(RegExp(r'[,，\s]+'))
        .map((w) => w.trim())
        .where((w) => w.length >= 2 && w.length <= 6)
        .take(5)
        .toList();
  }

  /// "**text**" → InlineSpan 리스트로 변환 (볼드 하이라이트)
  static List<InlineSpan> buildRichSpans(
    String text, {
    double fontSize = 14,
    Color normalColor = AppColors.BODY_COLOR,
    Color boldColor = AppColors.BLACK,
  }) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*([^*]+)\*\*');
    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: TextStyle(fontSize: fontSize, color: normalColor, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: boldColor,
          height: 1.5,
        ),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: TextStyle(fontSize: fontSize, color: normalColor, height: 1.5),
      ));
    }
    return spans;
  }
}

// =============================================================================
// StyleAnalysisView — 전체 표시 (RecommendationCard용)
// =============================================================================
class StyleAnalysisView extends StatelessWidget {
  final String? styleAnalysis;

  const StyleAnalysisView({super.key, required this.styleAnalysis});

  @override
  Widget build(BuildContext context) {
    final raw = styleAnalysis;
    if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();

    final entries = StyleAnalysisParser._parseCategories(raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnalysisHeader(),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _PlainText(raw: raw)
        else
          ...entries.map((e) => _CategoryRow(entry: e)),
      ],
    );
  }
}

class _AnalysisHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ACCENT_BLUE, AppColors.ACCENT_PURPLE],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AI 스타일 분석',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _StyleEntry entry;

  const _CategoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.ACCENT_BLUE.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(entry.icon, size: 14, color: AppColors.ACCENT_BLUE),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.MEDIUM_GREY,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.BLACK,
                    height: 1.45,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainText extends StatelessWidget {
  final String raw;

  const _PlainText({required this.raw});

  @override
  Widget build(BuildContext context) {
    final clean = raw.replaceAll(r'\n', '\n');
    return RichText(
      text: TextSpan(
        children: StyleAnalysisParser.buildRichSpans(clean),
      ),
    );
  }
}

// =============================================================================
// StyleAnalysisChipsView — 칩 형태 + 자세히 보기 (OutfitCard용)
// =============================================================================
class StyleAnalysisChipsView extends StatelessWidget {
  final String? styleAnalysis;

  const StyleAnalysisChipsView({super.key, required this.styleAnalysis});

  void _showDetail(BuildContext context) {
    final raw = styleAnalysis;
    if (raw == null || raw.trim().isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnalysisDetailSheet(styleAnalysis: raw),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = styleAnalysis;
    if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();

    final keywords = StyleAnalysisParser.extractKeywords(raw);
    const maxVisible = 2;
    final visible = keywords.take(maxVisible).toList();
    final remaining = (keywords.length - maxVisible).clamp(0, 99);

    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visible.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...visible.map((k) => _KeywordChip(label: k)),
                  if (remaining > 0)
                    _KeywordChip(label: '+$remaining', isMore: true),
                ],
              ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  '자세히 보기',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.ACCENT_BLUE,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 1),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 12,
                  color: AppColors.ACCENT_BLUE,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String label;
  final bool isMore;

  const _KeywordChip({required this.label, this.isMore = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isMore
            ? AppColors.ACCENT_PURPLE.withValues(alpha: 0.10)
            : AppColors.ACCENT_BLUE.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isMore ? AppColors.ACCENT_PURPLE : AppColors.ACCENT_BLUE,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// =============================================================================
// 상세 BottomSheet
// =============================================================================
class _AnalysisDetailSheet extends StatelessWidget {
  final String styleAnalysis;

  const _AnalysisDetailSheet({required this.styleAnalysis});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.BORDER_COLOR,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.ACCENT_BLUE, AppColors.ACCENT_PURPLE],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI 스타일 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.BLACK,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.MEDIUM_GREY,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            // 내용
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  StyleAnalysisView(styleAnalysis: styleAnalysis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
