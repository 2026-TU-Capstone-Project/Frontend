import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/fitting/clothes_set/model/clothes_set_model.dart';
import 'package:capstone_fe/fitting/clothes_set/repository/clothes_set_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 코디 폴더 API Repository를 앱 전역에서 공유.
final clothesSetRepositoryProvider = Provider<ClothesSetRepository>((ref) {
  return ClothesSetRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 코디 폴더 목록
// ─────────────────────────────────────────────

class ClothesSetListNotifier extends AsyncNotifier<List<ClothesSetModel>> {
  @override
  Future<List<ClothesSetModel>> build() => _fetch();

  Future<List<ClothesSetModel>> _fetch() async {
    final repo = ref.read(clothesSetRepositoryProvider);
    final resp = await repo.getClothesSets();
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final clothesSetListProvider =
    AsyncNotifierProvider<ClothesSetListNotifier, List<ClothesSetModel>>(
  ClothesSetListNotifier.new,
);
