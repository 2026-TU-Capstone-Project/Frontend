import 'dart:async';

import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/repository/follow_repository.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

/// 팔로워/팔로잉 cursor pagination 상태.
class FollowListState {
  final List<FollowResponse> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isFetchingMore;

  const FollowListState({
    required this.items,
    this.nextCursor,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  static const empty = FollowListState(items: [], hasMore: false);

  FollowListState copyWith({
    List<FollowResponse>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return FollowListState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class FollowRequestsNotifier
    extends AsyncNotifier<List<FollowRequestResponse>> {
  static const _pollInterval = Duration(seconds: 30);

  Timer? _timer;
  _FollowPollingLifecycleObserver? _lifecycle;

  @override
  Future<List<FollowRequestResponse>> build() {
    _stopTimer();
    _detachLifecycle();

    _lifecycle = _FollowPollingLifecycleObserver(
      onResumed: () {
        _startTimer();
        refresh();
      },
      onPaused: _stopTimer,
    );
    WidgetsBinding.instance.addObserver(_lifecycle!);
    _startTimer();

    ref.onDispose(() {
      _stopTimer();
      _detachLifecycle();
    });

    return _fetch();
  }

  void _startTimer() {
    _timer ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _detachLifecycle() {
    if (_lifecycle != null) {
      WidgetsBinding.instance.removeObserver(_lifecycle!);
      _lifecycle = null;
    }
  }

  Future<List<FollowRequestResponse>> _fetch() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getPendingRequests();
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  /// 백그라운드 폴링/사용자 새로고침 공용 — UI 깜빡임 방지 위해 AsyncLoading 미사용.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> accept(int followId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.acceptFollow(followId);
    if (!resp.success) throw Exception(resp.message);
    state = AsyncData(cur.where((r) => r.followId != followId).toList());
    _invalidateMyFollowers();
  }

  Future<void> reject(int followId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.rejectFollow(followId);
    if (!resp.success) throw Exception(resp.message);
    state = AsyncData(cur.where((r) => r.followId != followId).toList());
    _invalidateMyFollowers();
  }

  void _invalidateMyFollowers() {
    final myId = ref.read(userMeProvider).valueOrNull?.userId;
    if (myId != null) ref.invalidate(followersProvider(myId));
  }
}

final followRequestsProvider = AsyncNotifierProvider<FollowRequestsNotifier,
    List<FollowRequestResponse>>(FollowRequestsNotifier.new);

final pendingRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(followRequestsProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
});

const int _kFollowPageSize = 20;

/// cursor string은 int 형태로 들어오지만 JSON에서 String으로도 전달될 수 있음.
int? _parseCursor(String? cursor) {
  if (cursor == null || cursor.isEmpty) return null;
  return int.tryParse(cursor);
}

class FollowersNotifier
    extends AutoDisposeFamilyAsyncNotifier<FollowListState, int> {
  @override
  Future<FollowListState> build(int userId) => _fetchFirst();

  Future<FollowListState> _fetchFirst() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getUserFollowers(arg, limit: _kFollowPageSize);
    if (!resp.success) throw Exception(resp.message);
    final page = resp.data;
    return FollowListState(
      items: page?.items ?? const [],
      nextCursor: page?.nextCursor,
      hasMore: page?.hasMore ?? false,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> fetchMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isFetchingMore || !cur.hasMore) return;
    state = AsyncData(cur.copyWith(isFetchingMore: true));
    try {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.getUserFollowers(
        arg,
        cursor: _parseCursor(cur.nextCursor),
        limit: _kFollowPageSize,
      );
      if (!resp.success || resp.data == null) {
        state = AsyncData(cur.copyWith(isFetchingMore: false));
        return;
      }
      final page = resp.data!;
      state = AsyncData(FollowListState(
        items: [...cur.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isFetchingMore: false));
    }
  }
}

final followersProvider = AsyncNotifierProvider.autoDispose
    .family<FollowersNotifier, FollowListState, int>(
  FollowersNotifier.new,
);

class FollowingsNotifier
    extends AutoDisposeFamilyAsyncNotifier<FollowListState, int> {
  @override
  Future<FollowListState> build(int userId) => _fetchFirst();

  Future<FollowListState> _fetchFirst() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getUserFollowings(arg, limit: _kFollowPageSize);
    if (!resp.success) throw Exception(resp.message);
    final page = resp.data;
    return FollowListState(
      items: page?.items ?? const [],
      nextCursor: page?.nextCursor,
      hasMore: page?.hasMore ?? false,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> fetchMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isFetchingMore || !cur.hasMore) return;
    state = AsyncData(cur.copyWith(isFetchingMore: true));
    try {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.getUserFollowings(
        arg,
        cursor: _parseCursor(cur.nextCursor),
        limit: _kFollowPageSize,
      );
      if (!resp.success || resp.data == null) {
        state = AsyncData(cur.copyWith(isFetchingMore: false));
        return;
      }
      final page = resp.data!;
      state = AsyncData(FollowListState(
        items: [...cur.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isFetchingMore: false));
    }
  }

  Future<void> unfollow(int targetUserId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final originalItems = [...cur.items];
    state = AsyncData(cur.copyWith(
      items: cur.items.where((f) => f.userId != targetUserId).toList(),
    ));
    try {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.cancelOrUnfollow(targetUserId);
      if (!resp.success) {
        state = AsyncData(cur.copyWith(items: originalItems));
        throw Exception(resp.message);
      }
      ref.invalidate(userPublicProfileProvider(targetUserId));
    } catch (e) {
      state = AsyncData(cur.copyWith(items: originalItems));
      rethrow;
    }
  }
}

final followingsProvider = AsyncNotifierProvider.autoDispose
    .family<FollowingsNotifier, FollowListState, int>(
  FollowingsNotifier.new,
);

/// 액션 트리거 전용 — state 머신 불필요. follow/unfollow 후 변경된 캐시만 invalidate.
class FollowActionNotifier extends FamilyNotifier<void, int> {
  @override
  void build(int arg) {}

  Future<void> follow() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.sendFollowRequest(arg);
    if (!resp.success) throw Exception(resp.message);
    _invalidateAfterAction();
  }

  Future<void> unfollow() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.cancelOrUnfollow(arg);
    if (!resp.success) throw Exception(resp.message);
    _invalidateAfterAction();
  }

  void _invalidateAfterAction() {
    final myId = ref.read(userMeProvider).valueOrNull?.userId;
    if (myId != null) ref.invalidate(followingsProvider(myId));
    ref.invalidate(followersProvider(arg));
    ref.invalidate(userPublicProfileProvider(arg));
  }
}

final followActionProvider =
    NotifierProviderFamily<FollowActionNotifier, void, int>(
  FollowActionNotifier.new,
);

/// 앱 라이프사이클을 듣고 foreground/background에 따라 콜백을 호출한다.
/// Notifier가 직접 WidgetsBindingObserver를 mixin할 수 없어서 별도 클래스로 분리.
class _FollowPollingLifecycleObserver with WidgetsBindingObserver {
  _FollowPollingLifecycleObserver({
    required this.onResumed,
    required this.onPaused,
  });

  final VoidCallback onResumed;
  final VoidCallback onPaused;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      onPaused();
    }
  }
}
