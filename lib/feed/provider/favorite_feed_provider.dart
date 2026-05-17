import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteFeedListNotifier
    extends AsyncNotifier<List<FeedListResponseDto>> {
  @override
  Future<List<FeedListResponseDto>> build() => _fetch();

  Future<List<FeedListResponseDto>> _fetch() async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.listFavoriteFeeds();
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// feedId 기준 즐겨찾기 토글. 이미 있으면 optimistic remove, 없으면 서버 응답 후 재조회.
  /// 목록이 아직 로드되지 않은 상태(상세에서 첫 호출)에서도 동작한다.
  Future<bool> toggleFavorite(int feedId) async {
    final repo = ref.read(feedRepositoryProvider);
    final current = state.valueOrNull;
    final existed = current?.any((f) => f.feedId == feedId) ?? false;

    if (existed && current != null) {
      final optimistic =
          current.where((f) => f.feedId != feedId).toList(growable: false);
      state = AsyncData(optimistic);
    }

    try {
      final resp = await repo.toggleFavoriteFeed(feedId);
      if (!resp.success) {
        if (current != null) state = AsyncData(current);
        return false;
      }
      if (!existed) {
        state = const AsyncLoading();
        state = await AsyncValue.guard(_fetch);
      }
      return true;
    } catch (_) {
      if (current != null) state = AsyncData(current);
      return false;
    }
  }
}

final favoriteFeedListProvider = AsyncNotifierProvider<
    FavoriteFeedListNotifier, List<FeedListResponseDto>>(
  FavoriteFeedListNotifier.new,
);
