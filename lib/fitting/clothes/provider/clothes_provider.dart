import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/fitting/clothes/model/clothes_model.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 옷(단품) API Repository를 앱 전역에서 공유.
final clothesRepositoryProvider = Provider<ClothesRepository>((ref) {
  return ClothesRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 내 옷장 옷 목록
// ─────────────────────────────────────────────

/// [비유] 옷장 재고 담당자: 서버에서 옷 목록을 가져와 캐싱한다.
/// 추가/삭제 후 refresh()를 호출하면 자동으로 UI가 갱신된다.
/// fetchByCategory()로 서버사이드 카테고리 필터 적용 가능.
class ClothesListNotifier extends AsyncNotifier<List<ClothesModel>> {
  /// 마지막으로 요청한 API 카테고리 (null = 전체)
  String? _currentApiCategory;

  @override
  Future<List<ClothesModel>> build() => _fetch(null);

  Future<List<ClothesModel>> _fetch(String? apiCategory) async {
    final repo = ref.read(clothesRepositoryProvider);
    final resp = await repo.getClothesList(category: apiCategory);
    return resp.data ?? [];
  }

  /// 카테고리 탭 변경 시 서버에 필터 요청
  Future<void> fetchByCategory(String? apiCategory) async {
    _currentApiCategory = apiCategory;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(apiCategory));
  }

  /// 현재 카테고리를 유지한 채로 재조회 (삭제/추가 후 갱신용)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(_currentApiCategory));
  }
}

final clothesListProvider =
    AsyncNotifierProvider<ClothesListNotifier, List<ClothesModel>>(
  ClothesListNotifier.new,
);
