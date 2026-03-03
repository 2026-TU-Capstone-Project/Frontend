import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/user/model/auth_model.dart';
import 'package:capstone_fe/user/repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 인증 API Repository (로그인/회원가입용 plain Dio 사용).
/// getMe()는 authDio를 별도로 주입받으므로 plain Dio로 초기화.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Dio(), baseUrl: baseUrl);
});

// ─────────────────────────────────────────────
// 현재 로그인 유저 정보
// ─────────────────────────────────────────────

/// [비유] 내 명함 담당자: 서버에서 내 프로필을 가져온다.
/// 실패해도 null로 처리해 앱이 crash 나지 않도록 한다.
class UserMeNotifier extends AsyncNotifier<UserMe?> {
  @override
  Future<UserMe?> build() => _fetch();

  Future<UserMe?> _fetch() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final authDio = ref.read(authDioProvider);
      return await repo.getMe(authDio);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final userMeProvider = AsyncNotifierProvider<UserMeNotifier, UserMe?>(
  UserMeNotifier.new,
);
