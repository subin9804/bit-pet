import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).signup(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    state.whenOrNull(
      error: (e, _) =>
          ToastMessage.show(context, e.toString(), type: ToastType.error),
    );
  }

  bool _validatePassword(String? v) {
    if (v == null || v.length < 10) return false;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
    final hasDigit = RegExp(r'[0-9]').hasMatch(v);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v);
    return [hasLetter, hasDigit, hasSpecial].where((e) => e).length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : '닉네임을 입력하세요',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : '올바른 이메일을 입력하세요',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  helperText: '10자 이상, 영문·숫자·특수문자 중 2종류 이상',
                  suffixIcon: IconButton(
                    icon:
                        Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => _validatePassword(v)
                    ? null
                    : '10자 이상, 영문·숫자·특수문자 중 2종류 이상 조합',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('가입하기'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('이미 계정이 있으신가요? 로그인',
                    style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
