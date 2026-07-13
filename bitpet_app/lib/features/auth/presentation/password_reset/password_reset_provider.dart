import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_response.dart';
import '../../data/auth_repository.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 3단계 플로우 상태
// email·resetToken은 화면 파라미터가 아닌 이 Provider로만 전달한다.
// autoDispose — 플로우를 완전히 벗어나면(전 화면 pop) 상태가 초기화된다.
// ════════════════════════════════════════════════════════════════

final passwordResetProvider = StateNotifierProvider.autoDispose<
    PasswordResetNotifier, PasswordResetState>((ref) {
  return PasswordResetNotifier(ref.watch(authRepositoryProvider));
});

class PasswordResetState {
  final String email;
  final String? resetToken;
  final bool isLoading;
  final String? errorMessage;

  const PasswordResetState({
    this.email = '',
    this.resetToken,
    this.isLoading = false,
    this.errorMessage,
  });

  PasswordResetState copyWith({
    String? email,
    String? resetToken,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PasswordResetState(
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // 매 액션마다 새로 세팅 (null = 에러 없음)
    );
  }
}

class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final AuthRepository _repo;

  PasswordResetNotifier(this._repo) : super(const PasswordResetState());

  /// 1단계 — 인증 코드 발송. 성공 시 true.
  Future<bool> requestCode(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.requestPasswordReset(email);
      state = state.copyWith(email: email, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFrom(e, '인증 코드 발송에 실패했어요. 잠시 후 다시 시도해 주세요.'),
      );
      return false;
    }
  }

  /// 2단계 — 코드 인증. 성공 시 resetToken을 상태에 저장하고 true.
  Future<bool> verifyCode(String code) async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _repo.verifyResetCode(state.email, code);
      state = state.copyWith(resetToken: token, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFrom(e, '인증 코드 확인에 실패했어요. 잠시 후 다시 시도해 주세요.'),
      );
      return false;
    }
  }

  /// 3단계 — 새 비밀번호 저장. 성공 시 true.
  Future<bool> confirmReset(String newPassword) async {
    final token = state.resetToken;
    if (token == null) {
      state = state.copyWith(errorMessage: '인증 정보가 없어요. 처음부터 다시 시도해 주세요.');
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      await _repo.confirmPasswordReset(token, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFrom(e, '비밀번호 변경에 실패했어요. 잠시 후 다시 시도해 주세요.'),
      );
      return false;
    }
  }

  /// 서버 에러 코드(PASSWORD_RESET_*)를 사용자 메시지로 변환
  String _messageFrom(Object e, String fallback) {
    String? code;
    String? serverMessage;

    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>?;
        code = error?['code'] as String?;
        serverMessage = error?['message'] as String?;
      }
    } else if (e is ApiException) {
      code = e.errorCode;
      serverMessage = e.message;
    }

    return switch (code) {
      'PASSWORD_RESET_CODE_NOT_FOUND' => '인증 코드가 만료되었어요. 코드를 다시 요청해 주세요.',
      'PASSWORD_RESET_CODE_INVALID' => '인증 코드가 올바르지 않아요. 다시 확인해 주세요.',
      'PASSWORD_RESET_TOKEN_INVALID' => '재설정 유효 시간이 지났어요. 처음부터 다시 시도해 주세요.',
      _ => serverMessage ?? fallback,
    };
  }
}
