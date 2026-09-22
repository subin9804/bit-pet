import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/push/push_service.dart';
import '../../../core/upload/image_upload.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

// 현재 로그인된 유저 상태 (null = 미로그인)
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repo;
  final Ref _ref;

  late final StreamSubscription<void> _expiredSub;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    // 토큰이 서버에 거부돼 세션이 끝난 경우. 인터셉터는 Riverpod 을 모르기 때문에
    // 여기서 받아 상태를 내려야 라우터(refreshListenable)가 /login 으로 보낸다.
    // 이게 없으면 토큰만 조용히 사라지고 화면은 로그인된 채로 남는다.
    _expiredSub = _ref.read(tokenStorageProvider).onSessionExpired.listen((_) {
      if (mounted) state = const AsyncValue.data(null);
    });
    _init();
  }

  @override
  void dispose() {
    _expiredSub.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final hasToken = await _repo.isLoggedIn;
    if (!hasToken) {
      state = const AsyncValue.data(null);
      return;
    }
    state = await AsyncValue.guard(() => _repo.getMe());
    if (state.hasError) {
      await _repo.logout();
      state = const AsyncValue.data(null);
      return;
    }
    await _setUpPush();
  }

  /// FCM 초기화 + 디바이스 토큰 등록. 실패해도 로그인 흐름은 막지 않는다.
  Future<void> _setUpPush() async {
    try {
      await _ref.read(pushServiceProvider).initialize();
    } catch (e) {
      debugPrint('[FCM] 푸시 초기화 실패: $e');
    }
  }

  Future<void> login(String email, String password, {bool keepLoggedIn = true}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.login(
        LoginRequest(email: email, password: password),
        keepLoggedIn: keepLoggedIn,
      ),
    );
    if (state.hasValue && state.value != null) {
      await _setUpPush();
    }
  }

  Future<void> signup(
    String email,
    String password,
    String nickname, {
    required bool agreeTos,
    required bool agreePrivacy,
    required bool agreeAge,
    required bool agreeMarketing,
    String profileColor = 'peach',
    PickedImage? profileImage,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signup(
        SignupRequest(
        email: email,
        password: password,
        nickname: nickname,
        profileColor: profileColor,
        agreeTos: agreeTos,
        agreePrivacy: agreePrivacy,
        agreeAge: agreeAge,
        agreeMarketing: agreeMarketing,
        ),
        profileImage: profileImage,
      ),
    );
    if (state.hasValue && state.value != null) {
      await _setUpPush();
    }
  }

  /// 로그아웃. **어느 단계가 실패하든 마지막 두 줄은 반드시 실행된다.**
  ///
  /// 순서(푸시 해제 → 서버 로그아웃 → 상태 비우기)는 그대로 두되, 앞의 두 개는
  /// 네트워크에 매달린 일이라 실패할 수 있다. 실패했다고 로그아웃이 안 되면
  /// 안 된다 — 사용자가 누른 건 "이 기기에서 나가겠다"이고, 그건 서버 사정과
  /// 무관하게 **로컬에서 완결될 수 있는 일**이다.
  ///
  /// 예전엔 앞 단계에 시간 제한이 없어서, 푸시 토큰 조회가 안 돌아오면
  /// (`PushService.unregisterToken` 주석 참고) 로그아웃이 통째로 멈췄다.
  Future<void> logout() async {
    // 서버에서 디바이스 토큰을 먼저 지운다 — JWT가 살아있는 동안 호출해야 인증이 통과된다
    try {
      await _ref.read(pushServiceProvider).unregisterToken();
    } catch (e) {
      debugPrint('[FCM] 푸시 토큰 해제 실패: $e');
    }
    try {
      await _repo.logout().timeout(const Duration(seconds: 5));
    } catch (e) {
      // 서버에 못 닿아도 이 기기에서는 나간다. 서버의 refresh 토큰은 14일 뒤
      // 알아서 만료되고, 남아 있어도 그것만으로는 아무것도 할 수 없다.
      debugPrint('[Auth] 서버 로그아웃 실패 — 로컬 토큰만 정리: $e');
      // `_repo.logout()` 의 finally 가 끝까지 못 갔을 수 있어 직접 한 번 더 지운다.
      // 토큰이 남으면 다음 실행에서 `_init` 이 로그인 상태로 복원해버린다.
      try {
        await _ref.read(tokenStorageProvider).clearTokens();
      } catch (e2) {
        debugPrint('[Auth] 로컬 토큰 정리 실패: $e2');
      }
    }
    state = const AsyncValue.data(null);
  }

  /// 프로필 이미지 업로드 후 상태 갱신
  Future<void> uploadProfileImage(PickedImage image) async {
    final updated = await _repo.uploadProfileImage(image);
    state = AsyncValue.data(updated);
  }

  /// 가계도 닉네임 공개 설정 변경. 서버가 돌려준 값으로 상태를 덮어써
  /// 화면 토글과 실제 설정이 갈라지지 않게 한다
  Future<void> setShowNicknameInPedigree(bool value) async {
    final updated = await _repo.updateMe(showNicknameInPedigree: value);
    state = AsyncValue.data(updated);
  }

  /// 탈퇴 전 미리보기 — 공동 사육자가 있는 개체 목록 (비면 선택지 없이 진행)
  Future<List<SharedPetPreview>> withdrawPreview() => _repo.getWithdrawPreview();

  /// 회원 탈퇴 — 서버가 개체 처리(삭제/익명화)까지 한 트랜잭션으로 끝낸 뒤
  /// 로컬 토큰을 지운다. 순서를 바꾸면 인증이 빠져 탈퇴 요청 자체가 401이 된다
  Future<void> withdraw({bool handOverSharedPets = true}) async {
    try {
      await _ref.read(pushServiceProvider).unregisterToken();
    } catch (e) {
      debugPrint('[FCM] 푸시 토큰 해제 실패: $e');
    }
    await _repo.withdraw(handOverSharedPets: handOverSharedPets);
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
