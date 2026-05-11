import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/follow/model/follow_model.dart';
import 'package:capstone_fe/follow/repository/follow_repository.dart';
import 'package:capstone_fe/user/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

class FollowRequestsNotifier
    extends AsyncNotifier<List<FollowRequestResponse>> {
  @override
  Future<List<FollowRequestResponse>> build() => _fetch();

  Future<List<FollowRequestResponse>> _fetch() async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getPendingRequests();
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
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

class UserFollowersNotifier
    extends FamilyAsyncNotifier<List<FollowResponse>, int> {
  @override
  Future<List<FollowResponse>> build(int arg) => _fetch(arg);

  Future<List<FollowResponse>> _fetch(int userId) async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getUserFollowers(userId);
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final userFollowersProvider = AsyncNotifierProviderFamily<UserFollowersNotifier,
    List<FollowResponse>, int>(UserFollowersNotifier.new);

class UserFollowingsNotifier
    extends FamilyAsyncNotifier<List<FollowResponse>, int> {
  @override
  Future<List<FollowResponse>> build(int arg) => _fetch(arg);

  Future<List<FollowResponse>> _fetch(int userId) async {
    final repo = ref.read(followRepositoryProvider);
    final resp = await repo.getUserFollowings(userId);
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final userFollowingsProvider = AsyncNotifierProviderFamily<
    UserFollowingsNotifier,
    List<FollowResponse>,
    int>(UserFollowingsNotifier.new);

class FollowActionNotifier extends FamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> follow() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.sendFollowRequest(arg);
      if (!resp.success) throw Exception(resp.message);
      ref.invalidate(myFollowingsProvider);
      ref.invalidate(myFollowersProvider);
      ref.invalidate(userPublicProfileProvider(arg));
      ref.invalidate(userFollowersProvider(arg));
      ref.invalidate(userFollowingsProvider(arg));
      return true;
    });
  }

  Future<void> unfollow() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(followRepositoryProvider);
      final resp = await repo.cancelOrUnfollow(arg);
      if (!resp.success) throw Exception(resp.message);
      ref.invalidate(myFollowingsProvider);
      ref.invalidate(myFollowersProvider);
      ref.invalidate(userPublicProfileProvider(arg));
      ref.invalidate(userFollowersProvider(arg));
      ref.invalidate(userFollowingsProvider(arg));
      return false;
    });
  }
}

final followActionProvider =
    AsyncNotifierProviderFamily<FollowActionNotifier, bool, int>(
  FollowActionNotifier.new,
);
