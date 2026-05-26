import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final loggedIn = await _repo.isLoggedIn;
    state = AsyncValue.data(loggedIn ? null : null);
    // 추후 /auth/me API 연동으로 실제 유저 정보 로드
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.login(LoginRequest(email: email, password: password)),
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
}
