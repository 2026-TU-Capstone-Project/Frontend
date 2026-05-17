import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/feed/model/feed_model.dart';
import 'package:capstone_fe/feed/provider/feed_provider.dart';
import 'package:capstone_fe/user/model/user_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:capstone_fe/user/repository/user_repository.dart';
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

class UserMeNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() => _fetch();

  Future<UserModel?> _fetch() async {
    final repo = ref.read(userRepositoryProvider);
    try {
      final resp = await repo.getMe();
      debugPrint('[UserMeNotifier] success=${resp.success}, data=${resp.data?.toJson()}');
      if (!resp.success) throw Exception(resp.message);
      return resp.data;
    } on DioException catch (e) {
      debugPrint('[UserMeNotifier] DioException: ${e.response?.statusCode} / ${e.response?.data}');
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<UserModel?> updateProfile({
    String? nickname,
    double? height,
    double? weight,
    String? gender,
    File? file,
  }) async {
    final repo = ref.read(userRepositoryProvider);
    final resp = await repo.updateProfile(
      nickname: nickname,
      height: height,
      weight: weight,
      gender: gender,
      file: file,
    );
    if (!resp.success) throw Exception(resp.message);
    state = AsyncValue.data(resp.data);
    return resp.data;
  }
}

final userMeProvider = AsyncNotifierProvider<UserMeNotifier, UserModel?>(
  UserMeNotifier.new,
);

// ─────────────────────────────────────────────
// 타인 공개 프로필 정보
// ─────────────────────────────────────────────

final userPublicProfileProvider =
    FutureProvider.family<PublicUserInfo, int>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  final resp = await repo.getPublicProfile(userId);
  if (!resp.success || resp.data == null) {
    throw Exception(resp.message);
  }
  return resp.data!;
});

/// 특정 유저의 피드 목록.
/// - 본인이면 /feeds/me 사용
/// - 타인이면 GET /api/v1/feeds/users/{userId} 사용
final userFeedsProvider = FutureProvider.family<
    List<FeedListResponseDto>, ({int userId, String? nickname})>(
  (ref, args) async {
    final me = ref.read(userMeProvider).valueOrNull;
    final repo = ref.read(feedRepositoryProvider);

    if (me != null && args.userId == me.userId) {
      final resp = await repo.listMy(0, 50);
      if (!resp.success || resp.data == null) return const [];
      return resp.data!.content;
    }

    try {
      final resp = await repo.listByUser(args.userId, 0, 20);
      debugPrint('[userFeedsProvider] userId=${args.userId}, success=${resp.success}, dataNull=${resp.data == null}, contentLen=${resp.data?.content.length}');
      if (!resp.success || resp.data == null) return const [];
      return resp.data!.content;
    } catch (e, st) {
      debugPrint('[userFeedsProvider] ERROR for userId=${args.userId}: $e\n$st');
      return const [];
    }
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
