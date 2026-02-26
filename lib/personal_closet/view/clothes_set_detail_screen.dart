import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/common/widget/app_dialog.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';

/// 폴더 상세: 폴더 이름 수정, 착장 목록, 착장 개별 삭제, 폴더 전체 삭제
class ClothesSetDetailScreen extends StatefulWidget {
  const ClothesSetDetailScreen({
    super.key,
    required this.folder,
    required this.onUpdated,
  });

  final ClothesSetModel folder;
  final VoidCallback onUpdated;

  @override
  State<ClothesSetDetailScreen> createState() => _ClothesSetDetailScreenState();
}

class _ClothesSetDetailScreenState extends State<ClothesSetDetailScreen> {
  late ClothesSetRepository _repository;
  late ClothesSetModel _folder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = ClothesSetRepository(createAuthDio(), baseUrl: baseUrl);
    _folder = widget.folder;
  }

  Future<void> _updateFolderName(String newName) async {
    setState(() => _isLoading = true);
    try {
      final resp = await _repository.updateClothesSet(
        _folder.id,
        UpdateClothesSetRequest(newName: newName),
      );
      if (mounted && resp.success) {
        setState(() => _folder = ClothesSetModel(
          id: _folder.id,
          setName: newName,
          representativeImageUrl: _folder.representativeImageUrl,
          fittingTasks: _folder.fittingTasks,
          clothes: _folder.clothes,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('폴더 이름이 변경되었어요')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFolder() async {
    final ok = await AppDialog.confirm(
      context: context,
      title: '폴더 삭제',
      content: '이 폴더와 안에 있는 모든 코디가 삭제됩니다. 계속할까요?',
      confirmLabel: '삭제',
      confirmIsDestructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final resp = await _repository.deleteClothesSet(_folder.id);
      if (mounted && resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('폴더가 삭제되었어요')),
        );
        widget.onUpdated();
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFittingFromSet(int taskId) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: '코디 삭제',
      content: '이 코디를 폴더에서 삭제할까요?',
      confirmLabel: '삭제',
      confirmIsDestructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final resp = await _repository.deleteFittingFromSet(taskId);
      if (mounted && resp.success) {
        setState(() {
          _folder = ClothesSetModel(
            id: _folder.id,
            setName: _folder.setName,
            representativeImageUrl: _folder.representativeImageUrl,
            fittingTasks: _folder.fittingTasks
                ?.where((t) => t.taskId != taskId)
                .toList(),
            clothes: _folder.clothes,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('폴더에서 삭제되었어요')),
        );
        widget.onUpdated();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRenameDialog() {
    AppDialog.prompt(
      context: context,
      title: '폴더 이름 수정',
      hintText: '폴더 이름',
      initialValue: _folder.setName ?? '',
      confirmLabel: '저장',
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        _updateFolderName(name);
      }
    });
  }

  void _showImageFullScreen(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _folder.fittingTasks ?? [];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.BLACK),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _folder.setName ?? '폴더',
          style: const TextStyle(
            color: AppColors.BLACK,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.BLACK),
            onPressed: _isLoading ? null : _showRenameDialog,
            tooltip: '이름 수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.ERROR_COLOR),
            onPressed: _isLoading ? null : _deleteFolder,
            tooltip: '폴더 삭제',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
            )
          : tasks.isEmpty
              ? _buildEmpty()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final imageUrl = task.resultImgUrl;
                    final taskId = task.taskId;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _FittingCard(
                      imageUrl: imageUrl,
                      onTap: () => _showImageFullScreen(imageUrl),
                      onDelete: taskId != null
                          ? () => _deleteFittingFromSet(taskId)
                          : null,
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 56,
            color: AppColors.BORDER_COLOR,
          ),
          SizedBox(height: 16),
          Text(
            '이 폴더에 코디가 없어요',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.BODY_COLOR,
            ),
          ),
        ],
      ),
    );
  }
}

class _FittingCard extends StatelessWidget {
  const _FittingCard({
    required this.imageUrl,
    required this.onTap,
    this.onDelete,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.BORDER_COLOR),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.INPUT_BG_COLOR,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.MEDIUM_GREY,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
