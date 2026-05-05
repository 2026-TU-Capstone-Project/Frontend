import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/repository/feed_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _kDefaultPage = 0;
const int _kDefaultPageSize = 20;

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

class FeedListState {
  final List<FeedListResponseDto> items;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool isFetchingMore;
  final bool isLast;

  const FeedListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    this.isFetchingMore = false,
    this.isLast = false,
  });

  FeedListState copyWith({
    List<FeedListResponseDto>? items,
    int? page,
    int? totalPages,
    int? totalElements,
    bool? isFetchingMore,
    bool? isLast,
  }) {
    return FeedListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      isLast: isLast ?? this.isLast,
    );
  }
}

class FeedListNotifier extends AsyncNotifier<FeedListState> {
  @override
  Future<FeedListState> build() => _fetchPage(0);

  Future<FeedListState> _fetchPage(int page) async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.listAll(page, _kDefaultPageSize);
    if (!resp.success || resp.data == null) {
      throw Exception(resp.message);
    }
    final p = resp.data!;
    return FeedListState(
      items: p.content,
      page: p.number,
      totalPages: p.totalPages,
      totalElements: p.totalElements,
      isLast: p.last,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> fetchMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isFetchingMore || current.isLast) return;
    state = AsyncData(current.copyWith(isFetchingMore: true));
    try {
      final repo = ref.read(feedRepositoryProvider);
      final nextPage = current.page + 1;
      final resp = await repo.listAll(nextPage, _kDefaultPageSize);
      if (!resp.success || resp.data == null) {
        state = AsyncData(current.copyWith(isFetchingMore: false));
        return;
      }
      final p = resp.data!;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...p.content],
        page: p.number,
        totalPages: p.totalPages,
        totalElements: p.totalElements,
        isFetchingMore: false,
        isLast: p.last,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isFetchingMore: false));
    }
  }

  Future<void> toggleLike(int feedId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.items.indexWhere((f) => f.feedId == feedId);
    if (idx == -1) return;
    final original = current.items[idx];
    final wasLiked = original.liked ?? false;
    final originalCount = original.likeCount ?? 0;
    final optimistic = FeedListResponseDto(
      feedId: original.feedId,
      feedTitle: original.feedTitle,
      styleImageUrl: original.styleImageUrl,
      authorNickname: original.authorNickname,
      authorProfileImageUrl: original.authorProfileImageUrl,
      likeCount: wasLiked ? originalCount - 1 : originalCount + 1,
      visibility: original.visibility,
      liked: !wasLiked,
    );
    final newItems = [...current.items];
    newItems[idx] = optimistic;
    state = AsyncData(current.copyWith(items: newItems));

    try {
      final repo = ref.read(feedRepositoryProvider);
      final resp = await repo.toggleLike(feedId);
      if (!resp.success) {
        _revert(idx, original);
      }
    } catch (_) {
      _revert(idx, original);
    }
  }

  void _revert(int idx, FeedListResponseDto original) {
    final s = state.valueOrNull;
    if (s == null || idx < 0 || idx >= s.items.length) return;
    final reverted = [...s.items];
    reverted[idx] = original;
    state = AsyncData(s.copyWith(items: reverted));
  }
}

final feedListProvider =
    AsyncNotifierProvider<FeedListNotifier, FeedListState>(
  FeedListNotifier.new,
);

class MyFeedListNotifier extends AsyncNotifier<List<FeedListResponseDto>> {
  @override
  Future<List<FeedListResponseDto>> build() => _fetch();

  Future<List<FeedListResponseDto>> _fetch() async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.listMy(_kDefaultPage, _kDefaultPageSize);
    if (resp.success && resp.data != null) return resp.data!.content;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final myFeedListProvider =
    AsyncNotifierProvider<MyFeedListNotifier, List<FeedListResponseDto>>(
  MyFeedListNotifier.new,
);

class FeedDetailNotifier
    extends FamilyAsyncNotifier<FeedDetailResponseDto, int> {
  @override
  Future<FeedDetailResponseDto> build(int arg) => _fetch(arg);

  Future<FeedDetailResponseDto> _fetch(int feedId) async {
    final repo = ref.read(feedRepositoryProvider);
    final resp = await repo.getDetail(feedId);
    if (resp.success && resp.data != null) return resp.data!;
    throw Exception(resp.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final feedDetailProvider = AsyncNotifierProviderFamily<FeedDetailNotifier,
    FeedDetailResponseDto, int>(
  FeedDetailNotifier.new,
);
