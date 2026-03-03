import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/fitting/model/fitting_model.dart';
import 'package:capstone_fe/fitting/repository/fitting_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 피팅 관련 API Repository를 앱 전역에서 공유.
final fittingRepositoryProvider = Provider<FittingRepository>((ref) {
  return FittingRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 내 저장 코디 목록 (My Closet)
// ─────────────────────────────────────────────

/// [비유] 내 옷장 서랍 담당자: 피팅 결과 중 저장된 목록을 관리한다.
/// WardrobeScreen과 FeedWriteScreen이 동일 데이터를 공유한다.
class MyClosetNotifier extends AsyncNotifier<List<SavedFittingData>> {
  @override
  Future<List<SavedFittingData>> build() => _fetch();

  Future<List<SavedFittingData>> _fetch() async {
    final repo = ref.read(fittingRepositoryProvider);
    final resp = await repo.getMyCloset();
    return resp.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final myClosetProvider =
    AsyncNotifierProvider<MyClosetNotifier, List<SavedFittingData>>(
  MyClosetNotifier.new,
);
