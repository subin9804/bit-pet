import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _init();
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

  Future<void> signup(String email, String password, String nickname) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signup(
          SignupRequest(email: email, password: password, nickname: nickname)),
    );
    if (state.hasValue && state.value != null) {
      await _setUpPush();
    }
  }

  Future<void> logout() async {
    // 서버에서 디바이스 토큰을 먼저 지운다 — JWT가 살아있는 동안 호출해야 인증이 통과된다
    try {
      await _ref.read(pushServiceProvider).unregisterToken();
    } catch (e) {
      debugPrint('[FCM] 푸시 토큰 해제 실패: $e');
    }
    await _repo.logout();
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
