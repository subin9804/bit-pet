import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/auth_provider.dart';

// ─── 교체 가능한 상단 아이콘 ────────────────────────────────────────────────
// ✏️ 아이콘 변경 시 이 위젯만 수정하세요.
//    예: Image.asset('assets/images/login_icon.png', width: 72, height: 72)
Widget get _loginIcon => Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: const Icon(Icons.cruelty_free_outlined, size: 36, color: AppColors.textSecondary),
    );

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _keepLoggedIn = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
      _emailCtrl.text.trim(),
      _pwCtrl.text,
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      error: (e, _) => ToastMessage.show(
        context, e.toString(), type: ToastType.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 56),

                  // ── 상단 아이콘 (교체 가능) ──────────────────────────
                  _loginIcon,

                  const SizedBox(height: 18),

                  // ── 로고 ────────────────────────────────────────────
                  Text(
                    'bit-pet',
                    style: GoogleFonts.vt323(
                      fontSize: 36,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── 슬로건 ──────────────────────────────────────────
                  Text(
                    '작은 친구들을 위한 사육 노트',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── EMAIL 입력 ───────────────────────────────────────
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

                  const SizedBox(height: 10),

                  // ── P/W 입력 ────────────────────────────────────────
                  _InputField(
                    label: 'P/W',
                    controller: _pwCtrl,
                    obscureText: _obscure,
                    enabled: !isLoading,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 10) {
                        return '비밀번호는 10자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // ── 로그인 상태 유지 + 비밀번호 찾기 ─────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _keepLoggedIn = !_keepLoggedIn),
                        child: Row(
                          children: [
                            _PixelCheckbox(checked: _keepLoggedIn),
                            const SizedBox(width: 6),
                            Text(
                              '로그인 상태 유지',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── 이메일로 로그인 버튼 ─────────────────────────────
                  _FullButton(
                    label: '이메일로 로그인',
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),

                  const SizedBox(height: 20),

                  // ── OR 구분선 ────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.border, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: GoogleFonts.vt323(
                            fontSize: 14,
                            color: AppColors.textDisabled,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.border, thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── 카카오 ───────────────────────────────────────────
                  _SocialButton(
                    label: '카카오로 시작하기',
                    backgroundColor: AppColors.kakao,
                    textColor: AppColors.textPrimary,
                    // ✏️ 아이콘 교체: assets/icons/kakao.png 준비 후 주석 해제
                    // iconPath: 'assets/icons/kakao.png',
                    fallbackIcon: const Text('💛', style: TextStyle(fontSize: 18)),
                    onPressed: () {},
                  ),

                  const SizedBox(height: 10),

                  // ── 네이버 ───────────────────────────────────────────
                  _SocialButton(
                    label: '네이버로 시작하기',
                    backgroundColor: AppColors.naver,
                    textColor: Colors.white,
                    // ✏️ 아이콘 교체: assets/icons/naver.png 준비 후 주석 해제
                    // iconPath: 'assets/icons/naver.png',
                    fallbackIcon: Text(
                      'N',
                      style: GoogleFonts.vt323(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {},
                  ),

                  const SizedBox(height: 10),

                  // ── Google ───────────────────────────────────────────
                  _SocialButton(
                    label: 'Google로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: AppColors.textPrimary,
                    hasBorder: true,
                    // ✏️ 아이콘 교체: assets/icons/google.png 준비 후 주석 해제
                    // iconPath: 'assets/icons/google.png',
                    fallbackIcon: Text(
                      'G',
                      style: GoogleFonts.vt323(
                        fontSize: 20,
                        color: const Color(0xFF4285F4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {},
                  ),

                  const SizedBox(height: 28),

                  // ── 처음이신가요? 회원가입 ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '처음이신가요?',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '회원가입',
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

                  const SizedBox(height: 20),

                  // ── 버전 푸터 ────────────────────────────────────────
                  Text(
                    '▼ bit-pet v0.2 ▼',
                    style: GoogleFonts.vt323(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                      letterSpacing: 1,
                    ),
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

  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

// ─── 메인 버튼 ────────────────────────────────────────────────────────────────
class _FullButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _FullButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

// ─── 소셜 로그인 버튼 ─────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool hasBorder;
  final String? iconPath;
  final Widget fallbackIcon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.fallbackIcon,
    required this.onPressed,
    this.hasBorder = false,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final Widget icon = iconPath != null
        ? Image.asset(
            iconPath!,
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => fallbackIcon,
          )
        : fallbackIcon;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: hasBorder
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: icon,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
