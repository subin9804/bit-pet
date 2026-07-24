import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/upload/image_upload.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

// 현재 로그인된 유저 상태 (null = 미로그인)
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
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
  }

  Future<void> signup(String email, String password, String nickname) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signup(
          SignupRequest(email: email, password: password, nickname: nickname)),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  /// 프로필 이미지 업로드 후 상태 갱신
  Future<void> uploadProfileImage(PickedImage image) async {
    final updated = await _repo.uploadProfileImage(image);
    state = AsyncValue.data(updated);
  }
}
