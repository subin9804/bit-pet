import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/auth_provider.dart';

enum _PwStrength { none, weak, medium, strong }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _pwCtrl       = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  bool _obscurePw        = true;
  bool _obscurePwConfirm = true;
  _PwStrength _pwStrength = _PwStrength.none;

  // 약관 동의
  bool _agreeTerms     = false; // 이용약관 (필수)
  bool _agreePrivacy   = false; // 개인정보 처리방침 (필수)
  bool _agreeMarketing = false; // 마케팅 수신 (선택)

  bool get _requiredAgreed => _agreeTerms && _agreePrivacy;
  bool get _agreeAll => _agreeTerms && _agreePrivacy && _agreeMarketing;

  void _setAgreeAll(bool value) => setState(() {
        _agreeTerms = value;
        _agreePrivacy = value;
        _agreeMarketing = value;
      });

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  _PwStrength _calcStrength(String pw) {
    if (pw.isEmpty) return _PwStrength.none;
    if (pw.length < 10) return _PwStrength.weak;
    final hasLetter  = RegExp(r'[a-zA-Z]').hasMatch(pw);
    final hasDigit   = RegExp(r'[0-9]').hasMatch(pw);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pw);
    final types = [hasLetter, hasDigit, hasSpecial].where((e) => e).length;
    if (types >= 3) return _PwStrength.strong;
    if (types >= 2) return _PwStrength.medium;
    return _PwStrength.weak;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_requiredAgreed) {
      ToastMessage.show(context, '필수 약관에 동의해주세요', type: ToastType.error);
      return;
    }
    await ref.read(authStateProvider.notifier).signup(
      _emailCtrl.text.trim(),
      _pwCtrl.text,
      _nicknameCtrl.text.trim(),
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      error: (e, _) => ToastMessage.show(context, '에러입니다', type: ToastType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '회원가입',
          style: GoogleFonts.vt323(
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── EMAIL ────────────────────────────────────────────
                  _InputField(
                    label: 'EMAIL',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '이메일을 입력하세요';
                      final ok = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                      if (!ok.hasMatch(v)) return '올바른 이메일 형식이 아닙니다';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── P/W ──────────────────────────────────────────────
                  _InputField(
                    label: 'P/W',
                    controller: _pwCtrl,
                    obscureText: _obscurePw,
                    enabled: !isLoading,
                    onChanged: (v) =>
                        setState(() => _pwStrength = _calcStrength(v)),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePw = !_obscurePw),
                      child: Icon(
                        _obscurePw
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 10) return '최소 10자 이상이어야 합니다';
                      final hasLetter  = RegExp(r'[a-zA-Z]').hasMatch(v);
                      final hasDigit   = RegExp(r'[0-9]').hasMatch(v);
                      final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v);
                      final types = [hasLetter, hasDigit, hasSpecial].where((e) => e).length;
                      if (types < 2) return '영문·숫자·특수문자 중 2종류 이상 조합하세요';
                      return null;
                    },
                  ),

                  // ── 비밀번호 강도 게이지 ──────────────────────────────
                  const SizedBox(height: 8),
                  _PasswordStrengthBar(strength: _pwStrength),

                  const SizedBox(height: 12),

                  // ── P/W CONFIRM ──────────────────────────────────────
                  _InputField(
                    label: 'P/W CONFIRM',
                    controller: _pwConfirmCtrl,
                    obscureText: _obscurePwConfirm,
                    enabled: !isLoading,
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePwConfirm = !_obscurePwConfirm),
                      child: Icon(
                        _obscurePwConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '비밀번호 확인을 입력하세요';
                      if (v != _pwCtrl.text) return '비밀번호가 일치하지 않습니다';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── NICKNAME ─────────────────────────────────────────
                  _InputField(
                    label: 'NICKNAME',
                    controller: _nicknameCtrl,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '닉네임을 입력하세요';
                      if (v.length > 20) return '20자 이하로 입력하세요';
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── 약관 동의 ─────────────────────────────────────────
                  Text(
                    'TERMS',
                    style: GoogleFonts.vt323(
                      fontSize: 13,
                      color: AppColors.textDisabled,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _TermsRow(
                          label: '전체 동의',
                          checked: _agreeAll,
                          badge: null,
                          isBold: true,
                          onTap: () => _setAgreeAll(!_agreeAll),
                        ),
                        Divider(height: 1, thickness: 1, color: AppColors.border),
                        _TermsRow(
                          label: '이용약관 동의',
                          checked: _agreeTerms,
                          badge: '필수',
                          onTap: () =>
                              setState(() => _agreeTerms = !_agreeTerms),
                        ),
                        _TermsRow(
                          label: '개인정보 처리방침 동의',
                          checked: _agreePrivacy,
                          badge: '필수',
                          onTap: () =>
                              setState(() => _agreePrivacy = !_agreePrivacy),
                        ),
                        _TermsRow(
                          label: '마케팅 정보 수신 동의',
                          checked: _agreeMarketing,
                          badge: '선택',
                          onTap: () =>
                              setState(() => _agreeMarketing = !_agreeMarketing),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 가입하기 버튼 ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (isLoading || !_requiredAgreed) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _requiredAgreed
                            ? AppColors.primary
                            : AppColors.border,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              '가입하기',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _requiredAgreed
                                    ? Colors.white
                                    : AppColors.textDisabled,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 이미 계정이 있으신가요? ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 비밀번호 강도 게이지 바 ──────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final _PwStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength == _PwStrength.none) return const SizedBox.shrink();

    final filled = switch (strength) {
      _PwStrength.weak   => 1,
      _PwStrength.medium => 2,
      _PwStrength.strong => 3,
      _PwStrength.none   => 0,
    };
    final color = switch (strength) {
      _PwStrength.weak   => AppColors.error,
      _PwStrength.medium => AppColors.warning,
      _PwStrength.strong => AppColors.success,
      _PwStrength.none   => AppColors.border,
    };
    final label = switch (strength) {
      _PwStrength.weak   => '약함',
      _PwStrength.medium => '보통',
      _PwStrength.strong => '강함',
      _PwStrength.none   => '',
    };

    return Row(
      children: [
        ...List.generate(3, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < filled ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── 약관 동의 행 ──────────────────────────────────────────────────────────────
class _TermsRow extends StatelessWidget {
  final String label;
  final bool checked;
  final String? badge;  // '필수' | '선택' | null
  final bool isBold;
  final VoidCallback onTap;

  const _TermsRow({
    required this.label,
    required this.checked,
    required this.onTap,
    this.badge,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _PixelCheckbox(checked: checked),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    color: badge == '필수'
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 픽셀 체크박스 ────────────────────────────────────────────────────────────
class _PixelCheckbox extends StatelessWidget {
  final bool checked;
  const _PixelCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

// ─── 공통 입력 필드 ────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.vt323(
            fontSize: 13,
            color: AppColors.textDisabled,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
          cursorColor: AppColors.textPrimary,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.textPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle:
                const TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
