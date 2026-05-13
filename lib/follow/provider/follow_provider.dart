import 'dart:async';

import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/repository/follow_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

class FollowRequestsNotifier
    extends AsyncNotifier<List<FollowRequestResponse>> {
  Timer? _timer;

  @override
  Future<List<FollowRequestResponse>> build() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(),
    );
    ref.onDispose(() => _timer?.cancel());
    return _fetch();
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
    ref.invalidate(myFollowersProvider);
  }

  Future<void> reject(int followId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.rejectFollow(followId);
    if (!resp.success) throw Exception(resp.message);
    state = AsyncData(cur.where((r) => r.followId != followId).toList());
    ref.invalidate(myFollowersProvider);
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

class MyFollowersNotifier extends AsyncNotifier<List<FollowResponse>> {
  @override
  Future<List<FollowResponse>> build() => _fetch();

  Future<List<FollowResponse>> _fetch() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getFollowers();
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final myFollowersProvider =
    AsyncNotifierProvider<MyFollowersNotifier, List<FollowResponse>>(
  MyFollowersNotifier.new,
);

class MyFollowingsNotifier extends AsyncNotifier<List<FollowResponse>> {
  @override
  Future<List<FollowResponse>> build() => _fetch();

  Future<List<FollowResponse>> _fetch() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getFollowings();
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> unfollow(int targetUserId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final original = [...cur];
    state = AsyncData(cur.where((f) => f.userId != targetUserId).toList());
    try {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.cancelOrUnfollow(targetUserId);
      if (!resp.success) {
        state = AsyncData(original);
        throw Exception(resp.message);
      }
    } catch (e) {
      state = AsyncData(original);
      rethrow;
    }
  }
}

final myFollowingsProvider =
    AsyncNotifierProvider<MyFollowingsNotifier, List<FollowResponse>>(
  MyFollowingsNotifier.new,
);

/// 액션 트리거 전용 — state 머신 불필요. follow/unfollow 후 변경된 캐시만 invalidate.
class FollowActionNotifier extends FamilyNotifier<void, int> {
  @override
  void build(int arg) {}

  Future<void> follow() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.sendFollowRequest(arg);
    if (!resp.success) throw Exception(resp.message);
    ref.invalidate(myFollowingsProvider);
  }

  Future<void> unfollow() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.cancelOrUnfollow(arg);
    if (!resp.success) throw Exception(resp.message);
    ref.invalidate(myFollowingsProvider);
  }
}

final followActionProvider =
    NotifierProviderFamily<FollowActionNotifier, void, int>(
  FollowActionNotifier.new,
);
