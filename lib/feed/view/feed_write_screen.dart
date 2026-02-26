import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:flutter/material.dart';

/// 피드 작성: 내 저장 코디 선택 → 미리보기 → 제목/내용 입력 → POST
class FeedWriteScreen extends StatefulWidget {
  const FeedWriteScreen({super.key});

  @override
  State<FeedWriteScreen> createState() => _FeedWriteScreenState();
}

class _FeedWriteScreenState extends State<FeedWriteScreen> {
  final FittingRepository _fittingRepo =
      FittingRepository(createAuthDio(), baseUrl: baseUrl);
  final FeedRepository _feedRepo =
      FeedRepository(createAuthDio(), baseUrl: baseUrl);

  List<SavedFittingData> _savedList = [];
  bool _loadingList = true;
  String? _listError;

  SavedFittingData? _selected;
  FeedPreviewData? _preview;
  bool _loadingPreview = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadMyCloset();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCloset() async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final resp = await _fittingRepo.getMyCloset();
      if (!mounted) return;
      setState(() {
        _savedList = resp.data ?? [];
        _loadingList = false;
        if (_savedList.isEmpty) _listError = '저장된 코디가 없어요.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _listError = e.toString();
          _loadingList = false;
        });
      }
    }
  }

  Future<void> _selectFitting(SavedFittingData item) async {
    final taskId = item.taskId;
    if (taskId == null) return;
    setState(() {
      _selected = item;
      _preview = null;
      _loadingPreview = true;
    });
    try {
      final resp = await _feedRepo.getFeedPreview(taskId);
      if (!mounted) return;
      setState(() {
        _preview = resp.data;
        _loadingPreview = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPreview = false;
          _preview = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('미리보기 조회 실패: $e')),
        );
      }
    }
  }

  Future<void> _publish() async {
    final taskId = _selected?.taskId;
    if (taskId == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final resp = await _feedRepo.createFeed(
        CreateFeedBody(
          fittingTaskId: taskId,
          feedTitle: title,
          feedContent: _contentController.text.trim(),
        ).toJson(),
      );
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피드가 게시되었어요.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '피드 작성',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.BLACK,
          ),
        ),
      ),
      body: _loadingList
          ? const Center(child: CircularProgressIndicator())
          : _listError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _listError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.BODY_COLOR),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadMyCloset,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '올릴 코디를 선택하세요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.BLACK,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _savedList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = _savedList[index];
                            final isSelected = _selected?.taskId == item.taskId;
                            final imageUrl = item.resultImgUrl;
                            return GestureDetector(
                              onTap: () => _selectFitting(item),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.ACCENT_COLOR
                                        : AppColors.BORDER_COLOR,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.checkroom),
                                      )
                                    : const Center(
                                        child: Icon(Icons.checkroom),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loadingPreview)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_preview != null) ...[
                        const Text(
                          '미리보기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.BLACK,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.network(
                              _preview!.styleImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.BORDER_COLOR,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                        if (_preview!.topName != null ||
                            _preview!.bottomName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '상의: ${_preview!.topName ?? "-"} / 하의: ${_preview!.bottomName ?? "-"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.MEDIUM_GREY,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        // 제목·내용 입력 카드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.INPUT_BG_COLOR.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.BORDER_COLOR,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 20,
                                    color: AppColors.ACCENT_COLOR,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '글 쓰기',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.BLACK,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _titleController,
                                maxLength: 50,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.BLACK,
                                ),
                                decoration: InputDecoration(
                                  hintText: '오늘의 코디를 한 줄로 표현해보세요',
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.MEDIUM_GREY.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.BORDER_COLOR,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.BORDER_COLOR,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.ACCENT_COLOR,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _contentController,
                                maxLines: 5,
                                minLines: 3,
                                maxLength: 500,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.BODY_COLOR,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      '코디 포인트, 착용 팁, 스타일링 후기 등을 자유롭게 적어주세요',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.MEDIUM_GREY.withOpacity(0.9),
                                    height: 1.5,
                                  ),
                                  counterStyle: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.MEDIUM_GREY,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.BORDER_COLOR,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.BORDER_COLOR,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.ACCENT_COLOR,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _posting ? null : _publish,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.PRIMARYCOLOR,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _posting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('게시하기'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
