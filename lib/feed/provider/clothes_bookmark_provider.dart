import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/clothes_bookmark_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clothesBookmarkRepositoryProvider =
    Provider<ClothesBookmarkRepository>((ref) {
  return ClothesBookmarkRepository(
    ref.watch(authDioProvider),
    baseUrl: baseUrl,
  );
});

class ClothesBookmarkNotifier
    extends AsyncNotifier<List<ClothesBookmarkDto>> {
  @override
  Future<List<ClothesBookmarkDto>> build() => _fetch();

  Future<List<ClothesBookmarkDto>> _fetch() async {
    final repo = ref.read(clothesBookmarkRepositoryProvider);
    final resp = await repo.listBookmarks();
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// feedId+position 기준 토글. 이미 있으면 DELETE, 없으면 POST.
  Future<bool> toggleBookmark(int feedId, String position) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final repo = ref.read(clothesBookmarkRepositoryProvider);

    final idx = current.indexWhere(
      (b) => b.feedId == feedId && b.position == position,
    );

    if (idx >= 0) {
      final existing = current[idx];
      final optimistic =
          current.where((b) => b.id != existing.id).toList(growable: false);
      state = AsyncData(optimistic);
      try {
        final resp = await repo.deleteBookmark(bookmarkId: existing.id);
        if (!resp.success) {
          state = AsyncData(current);
          return false;
        }
        return true;
      } catch (_) {
        state = AsyncData(current);
        return false;
      }
    } else {
      try {
        final resp =
            await repo.saveBookmark(feedId: feedId, position: position);
        if (!resp.success || resp.data == null) return false;
        state = AsyncData([resp.data!, ...current]);
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}

final clothesBookmarkListProvider = AsyncNotifierProvider<
    ClothesBookmarkNotifier, List<ClothesBookmarkDto>>(
  ClothesBookmarkNotifier.new,
);
