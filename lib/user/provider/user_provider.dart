import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/repository/user_repository.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 인증 API Repository (로그인/회원가입용 plain Dio 사용).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Dio(), baseUrl: baseUrl);
});

/// 유저 정보 관련 Repository (인증된 Dio 사용).
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 현재 로그인 유저 정보
// ─────────────────────────────────────────────

class UserMeNotifier extends AsyncNotifier<UserMe?> {
  @override
  Future<UserMe?> build() => _fetch();

  /// 401(만료된 인증): null 반환 (authDio가 자동 refresh를 이미 시도한 결과).
  /// 그 외 에러는 throw해 UI가 에러 상태를 보여줄 수 있게 한다.
  Future<UserMe?> _fetch() async {
    final repo = ref.read(authRepositoryProvider);
    final authDio = ref.read(authDioProvider);
    try {
      return await repo.getMe(authDio);
    } on UnauthorizedException {
      return null;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final userMeProvider = AsyncNotifierProvider<UserMeNotifier, UserMe?>(
  UserMeNotifier.new,
);

// ─────────────────────────────────────────────
// 타인 공개 프로필 정보
// ─────────────────────────────────────────────

final userPublicProfileProvider =
    FutureProvider.family<UserPublicProfile, int>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  final resp = await repo.getPublicProfile(userId);
  if (!resp.success || resp.data == null) {
    throw Exception(resp.message);
  }
  return resp.data!;
});

/// 특정 유저의 피드 목록 (전체 피드에서 닉네임 기준 필터링)
final userFeedsProvider = FutureProvider.family<
    List<FeedListResponseDto>, ({int userId, String? nickname})>(
  (ref, args) async {
    final nickname = args.nickname?.trim();
    if (nickname == null || nickname.isEmpty) return const [];

    // 전체 피드 목록에서 해당 유저의 글만 필터링 (임시)
    final listState = await ref.watch(feedListProvider.future);
    return listState.items
        .where((f) => (f.authorNickname ?? '').trim() == nickname)
        .toList();
  },
);

// ─────────────────────────────────────────────
// 유저 검색
// ─────────────────────────────────────────────

class UserSearchNotifier
    extends FamilyAsyncNotifier<List<UserSearchItem>, String> {
  @override
  Future<List<UserSearchItem>> build(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    final repo = ref.watch(userRepositoryProvider);
    final resp = await repo.search(keyword);
    if (!resp.success) throw Exception(resp.message);
    return resp.data ?? const [];
  }
}

final userSearchProvider = AsyncNotifierProvider.family<UserSearchNotifier,
    List<UserSearchItem>, String>(UserSearchNotifier.new);
