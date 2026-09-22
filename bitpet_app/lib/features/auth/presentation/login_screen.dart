import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_dimens.dart';

/// 소셜 로그인 노출 여부.
///
/// 첫 배포는 **이메일 로그인만** 내보낸다. 서버(`auth/oauth/`)와 아래 버튼들은
/// 다 살아 있지만 OAuth 클라이언트 키를 아직 발급받지 않아, 지금 내보내면
/// **눌러도 아무 일이 일어나지 않는 버튼**이 된다. 그건 기능이 없는 것보다 나쁘다.
///
/// 키가 나오고 `onPressed` 가 배선되면 이 값만 `true` 로 바꾼다.
/// (리다이렉트 URI 등록에 `tailog.me` 도메인이 필요해서 서버 배포 이후 순서다)
const bool kSocialLoginEnabled = false;

// ─── 상단 로고 ──────────────────────────────────────────────────────────────
//
// 예전엔 회색 네모 안에 Material 아이콘(`cruelty_free_outlined`)을 넣고 그 아래
// 'tailog' 를 픽셀 글꼴로 따로 찍었다. 자리를 채워두려고 만든 임시 조합인데,
// 그 사이 진짜 로고(`assets/branding/logo.svg` — 심볼과 워드마크가 한 벌)가
// 나왔다. 앱을 처음 여는 화면에서 로고가 아닌 걸 보여줄 이유가 없다.
//
// 로고는 `login_main.png` — 심볼 위, 워드마크 아래로 쌓인 **정사각** 구성이다.
// 가로로 긴 `logo.svg`(833×240)와 비율이 달라서, 같은 폭을 주면 훨씬 커 보인다.
// 그래서 폭을 208 → 180 으로 줄였다. 이 파일은 여백이 넉넉해 실제 로고는 더 작게 앉는다.
//
// 벡터가 아니라 PNG 인 이유는 이게 최종 납품물이기 때문이다. `logo.svg` 는 가로형이라
// 이 화면의 세로 구성에 맞지 않는다 (지우지는 않았다 — 가로 자리에 여전히 쓸 수 있다).
Widget get _logo => Image.asset(
      'assets/branding/login_main.png',
      width: 180,
      // 3072px 원본을 180 으로 줄이므로 축소 품질이 그대로 보인다.
      filterQuality: FilterQuality.medium,
      semanticLabel: 'tailog',
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
      keepLoggedIn: _keepLoggedIn,
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      error: (e, _) {
        final msg = (e is DioException && e.response?.statusCode == 401)
            ? '존재하지 않는 아이디/비밀번호 입니다.'
            : '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.';
        ToastMessage.show(context, msg, type: ToastType.error);
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 56),

                  // ── 로고 (심볼 + 워드마크) ───────────────────────────
                  _logo,

                  const SizedBox(height: 12),

                  // ── 슬로건 ──────────────────────────────────────────
                  Text(
                    '작은 친구들을 위한 사육 노트',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled),
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

                  const SizedBox(height: 8),

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

                  const SizedBox(height: 8),

                  // ── 로그인 상태 유지 + 비밀번호 찾기 ─────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _keepLoggedIn = !_keepLoggedIn),
                        child: Row(
                          children: [
                            _CheckBox(checked: _keepLoggedIn),
                            const SizedBox(width: 8),
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
                        onPressed: () => context.push('/password-reset/request'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '비밀번호를 잊으셨나요?',
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

                  const SizedBox(height: 20),

                  // ── 이메일로 로그인 버튼 ─────────────────────────────
                  _FullButton(
                    label: '이메일로 로그인',
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),

                  // ── 소셜 로그인 (kSocialLoginEnabled) ────────────────
                  // OR 구분선까지 통째로 감싼다 — 아래가 비어 있는 'OR'만 남으면
                  // 뭔가 빠진 화면으로 보인다
                  if (kSocialLoginEnabled) ...[
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.textDisabled),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── 카카오 ─────────────────────────────────────────
                    _SocialButton(
                      label: '카카오로 시작하기',
                      backgroundColor: AppColors.kakao,
                      textColor: AppColors.textPrimary,
                      // ✏️ 아이콘 교체: assets/icons/kakao.png 준비 후 주석 해제
                      // iconPath: 'assets/icons/kakao.png',
                      fallbackIcon: const Text('💛', style: TextStyle(fontSize: 18)),
                      onPressed: () {},
                    ),

                    const SizedBox(height: 8),

                    // ── 네이버 ─────────────────────────────────────────
                    _SocialButton(
                      label: '네이버로 시작하기',
                      backgroundColor: AppColors.naver,
                      textColor: Colors.white,
                      // ✏️ 아이콘 교체: assets/icons/naver.png 준비 후 주석 해제
                      // iconPath: 'assets/icons/naver.png',
                      fallbackIcon: Text(
                        'N',
                        style: AppTextStyles.subheading.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () {},
                    ),

                    const SizedBox(height: 8),

                    // ── Google ─────────────────────────────────────────
                    _SocialButton(
                      label: 'Google로 시작하기',
                      backgroundColor: Colors.white,
                      textColor: AppColors.textPrimary,
                      hasBorder: true,
                      // ✏️ 아이콘 교체: assets/icons/google.png 준비 후 주석 해제
                      // iconPath: 'assets/icons/google.png',
                      fallbackIcon: Text(
                        'G',
                        style: AppTextStyles.subheading.copyWith(
                          color: const Color(0xFF4285F4),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],

                  const SizedBox(height: 32),

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
                  // 양옆의 ▼ 는 픽셀 컨셉 시절의 장식이었다. 로고가 제대로 들어간
                  // 화면에서는 같은 자리에서 두 개의 다른 톤이 부딪힌다.
                  Text(
                    'tailog v0.2',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textDisabled),
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

// ─── 체크박스 ────────────────────────────────────────────────────────────
class _CheckBox extends StatelessWidget {
  final bool checked;
  const _CheckBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
        borderRadius: AppRadius.brSm,
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
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
          style: AppTextStyles.label
              .copyWith(color: AppColors.textDisabled, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
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
                const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textPrimary, width: 1.5),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
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
            borderRadius: AppRadius.brMd,
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
            borderRadius: AppRadius.brMd,
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
