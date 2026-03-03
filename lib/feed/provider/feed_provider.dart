import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feed API Repository를 앱 전역에서 공유.
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 전체 피드 목록
// ─────────────────────────────────────────────

/// [비유] 진열대 담당자: build()에서 처음 채우고, refresh()로 새로고침.
class FeedListNotifier extends AsyncNotifier<List<FeedListItem>> {
  @override
  Future<List<FeedListItem>> build() => _fetch();

  Future<List<FeedListItem>> _fetch() async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.getFeeds();
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final feedListProvider =
    AsyncNotifierProvider<FeedListNotifier, List<FeedListItem>>(
  FeedListNotifier.new,
);

// ─────────────────────────────────────────────
// 내 피드 목록
// ─────────────────────────────────────────────

class MyFeedListNotifier extends AsyncNotifier<List<FeedListItem>> {
  @override
  Future<List<FeedListItem>> build() => _fetch();

  Future<List<FeedListItem>> _fetch() async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.getMyFeeds();
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final myFeedListProvider =
    AsyncNotifierProvider<MyFeedListNotifier, List<FeedListItem>>(
  MyFeedListNotifier.new,
);

// ─────────────────────────────────────────────
// 피드 상세 (feedId 기반 family provider)
// ─────────────────────────────────────────────

/// [비유] 특정 상품의 상세 페이지 담당자.
/// feedId별로 독립된 인스턴스를 유지한다.
class FeedDetailNotifier
    extends FamilyAsyncNotifier<FeedDetailData, int> {
  @override
  Future<FeedDetailData> build(int arg) => _fetch(arg);

  Future<FeedDetailData> _fetch(int feedId) async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.getFeedDetail(feedId);
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final feedDetailProvider = AsyncNotifierProviderFamily<FeedDetailNotifier,
    FeedDetailData, int>(
  FeedDetailNotifier.new,
);
