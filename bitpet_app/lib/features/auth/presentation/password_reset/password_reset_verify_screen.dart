import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_message.dart';
import 'password_reset_provider.dart';
import 'password_reset_widgets.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 2단계 — 6자리 코드 입력 + 5분 카운트다운
// ════════════════════════════════════════════════════════════════

class PasswordResetVerifyScreen extends ConsumerStatefulWidget {
  const PasswordResetVerifyScreen({super.key});

  @override
  ConsumerState<PasswordResetVerifyScreen> createState() =>
      _PasswordResetVerifyScreenState();
}

class _PasswordResetVerifyScreenState
    extends ConsumerState<PasswordResetVerifyScreen> {
  static const _codeTtl = Duration(minutes: 5);

  final _codeCtrl = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = _codeTtl.inSeconds;

  bool get _expired => _remainingSeconds <= 0;
  bool get _codeComplete => _codeCtrl.text.length == 6;

  String get _timerLabel {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = _codeTtl.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _resend() async {
    final email = ref.read(passwordResetProvider).email;
    final ok =
        await ref.read(passwordResetProvider.notifier).requestCode(email);
    if (!mounted) return;

    if (ok) {
      _codeCtrl.clear();
      _startTimer();
      ToastMessage.show(context, '인증 코드를 다시 보냈어요.', type: ToastType.success);
    } else {
      final msg = ref.read(passwordResetProvider).errorMessage;
      ToastMessage.show(context, msg ?? '인증 코드 발송에 실패했어요.',
          type: ToastType.error);
    }
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(passwordResetProvider.notifier)
        .verifyCode(_codeCtrl.text);
    if (!mounted) return;

    if (ok) {
      context.push('/password-reset/confirm');
    } else {
      final msg = ref.read(passwordResetProvider).errorMessage;
      ToastMessage.show(context, msg ?? '인증 코드 확인에 실패했어요.',
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: passwordResetAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              ResetGuideText('${state.email}로 발송된\n6자리 코드를 입력해 주세요.'),
              const SizedBox(height: 28),

              // ── 코드 입력 + 타이머 ──────────────────────────
              ResetInputField(
                controller: _codeCtrl,
                hintText: '6자리 코드',
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isLoading && !_expired,
                onChanged: (_) => setState(() {}),
                suffixIcon: Text(
                  _timerLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _expired ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
              if (_expired) ...[
                const SizedBox(height: 8),
                const Text(
                  '코드가 만료되었습니다. 다시 요청해 주세요.',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 12),

              // ── 재발송 ──────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _resend,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '재발송',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ResetFullButton(
                label: '인증하기',
                isLoading: isLoading,
                onPressed: (_codeComplete && !_expired) ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
