import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_message.dart';
import 'password_reset_provider.dart';
import 'password_reset_widgets.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 1단계 — 이메일 입력 → 인증 코드 발송
// ════════════════════════════════════════════════════════════════

class PasswordResetRequestScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState
    extends ConsumerState<PasswordResetRequestScreen> {
  final _emailCtrl = TextEditingController();

  bool get _emailValid =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(_emailCtrl.text.trim());

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_emailValid) {
      ToastMessage.show(context, '올바른 이메일 형식이 아닙니다.', type: ToastType.error);
      return;
    }
    final ok = await ref
        .read(passwordResetProvider.notifier)
        .requestCode(_emailCtrl.text.trim());
    if (!mounted) return;

    if (ok) {
      context.push('/password-reset/verify');
    } else {
      final msg = ref.read(passwordResetProvider).errorMessage;
      ToastMessage.show(context, msg ?? '인증 코드 발송에 실패했어요.',
          type: ToastType.error);
    }
  }

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
              const ResetGuideText('가입 시 사용한 이메일을 입력해 주세요.\n인증 코드를 보내드립니다.'),
              const SizedBox(height: 28),
              ResetInputField(
                controller: _emailCtrl,
                hintText: 'example@bit-pet.com',
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              ResetFullButton(
                label: '코드 발송',
                isLoading: isLoading,
                onPressed: _emailValid ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
