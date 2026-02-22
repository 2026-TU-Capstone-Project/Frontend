import 'package:flutter/material.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/network/auth_dio.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';
import 'package:capstone_fe/personal_closet/view/clothes_set_detail_screen.dart';

/// 코디 폴더 목록 화면 (폴더로 나눠서 관리)
class ClothesSetListScreen extends StatefulWidget {
  const ClothesSetListScreen({super.key});

  @override
  State<ClothesSetListScreen> createState() => _ClothesSetListScreenState();
}

class _ClothesSetListScreenState extends State<ClothesSetListScreen> {
  late ClothesSetRepository _repository;
  List<ClothesSetModel> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ClothesSetRepository(createAuthDio(), baseUrl: baseUrl);
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _repository.getClothesSets();
      if (mounted && resp.success) {
        setState(() => _folders = resp.data ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 목록 로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.BLACK),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '코디 폴더',
          style: TextStyle(
            color: AppColors.BLACK,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
            )
          : RefreshIndicator(
              onRefresh: _loadFolders,
              color: AppColors.PRIMARYCOLOR,
              child: _folders.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return _FolderCard(
                          folder: folder,
                          onTap: () => _openDetail(folder),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 64,
                color: AppColors.BORDER_COLOR,
              ),
              SizedBox(height: 16),
              Text(
                '아직 코디 폴더가 없어요',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.BODY_COLOR,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '피팅 결과에서 "폴더에 저장"으로\n폴더를 만들 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.MEDIUM_GREY,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDetail(ClothesSetModel folder) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ClothesSetDetailScreen(
          folder: folder,
          onUpdated: _loadFolders,
        ),
      ),
    ).then((_) => _loadFolders());
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onTap,
  });

  final ClothesSetModel folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = (folder.fittingTasks?.length ?? 0) + (folder.clothes?.length ?? 0);
    final imageUrl = folder.representativeImageUrl ??
        folder.fittingTasks?.firstOrNull?.resultImgUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.BORDER_COLOR),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.setName ?? '이름 없는 폴더',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.BLACK,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${count}개의 코디',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.MEDIUM_GREY,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.MEDIUM_GREY,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.INPUT_BG_COLOR,
      child: const Icon(Icons.folder_outlined, color: AppColors.BORDER_COLOR),
    );
  }
}
