import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_message.dart';
import 'password_reset_provider.dart';
import 'password_reset_widgets.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 3단계 — 새 비밀번호 입력 → 변경 완료
// ════════════════════════════════════════════════════════════════

class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  const PasswordResetConfirmScreen({super.key});

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState
    extends ConsumerState<PasswordResetConfirmScreen> {
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscurePw2 = true;

  bool get _pwValid => _pwCtrl.text.length >= 8;
  bool get _pw2Mismatch =>
      _pw2Ctrl.text.isNotEmpty && _pwCtrl.text != _pw2Ctrl.text;
  bool get _canSubmit =>
      _pwValid && _pw2Ctrl.text.isNotEmpty && !_pw2Mismatch;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(passwordResetProvider.notifier)
        .confirmReset(_pwCtrl.text);
    if (!mounted) return;

    if (ok) {
      ToastMessage.show(context, '비밀번호가 변경되었습니다.', type: ToastType.success);
      context.go('/login');
    } else {
      final msg = ref.read(passwordResetProvider).errorMessage;
      ToastMessage.show(context, msg ?? '비밀번호 변경에 실패했어요.',
          type: ToastType.error);
    }
  }

  Widget _obscureToggle(bool obscure, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textDisabled,
          size: 20,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordResetProvider).isLoading;

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
              const ResetGuideText('새 비밀번호를 입력해 주세요.'),
              const SizedBox(height: 28),

              // ── 새 비밀번호 ─────────────────────────────────
              ResetInputField(
                controller: _pwCtrl,
                hintText: '새 비밀번호 (8자 이상)',
                obscureText: _obscurePw,
                autofocus: true,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                suffixIcon: _obscureToggle(
                    _obscurePw, () => setState(() => _obscurePw = !_obscurePw)),
                errorText: (_pwCtrl.text.isNotEmpty && !_pwValid)
                    ? '비밀번호는 8자 이상이어야 합니다.'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── 비밀번호 확인 ───────────────────────────────
              ResetInputField(
                controller: _pw2Ctrl,
                hintText: '비밀번호 확인',
                obscureText: _obscurePw2,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                suffixIcon: _obscureToggle(_obscurePw2,
                    () => setState(() => _obscurePw2 = !_obscurePw2)),
                errorText: _pw2Mismatch ? '비밀번호가 일치하지 않습니다.' : null,
              ),
              const SizedBox(height: 32),

              ResetFullButton(
                label: '변경 완료',
                isLoading: isLoading,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
