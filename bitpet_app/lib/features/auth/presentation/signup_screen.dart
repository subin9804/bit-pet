import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

// ════════════════════════════════════════════════════════════════
// 11s · 회원가입 — 4단계 스텝 위저드
// 1) 프로필(색·닉네임)  2) 로그인 정보  3) 약관  4) 확인
// ════════════════════════════════════════════════════════════════

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // ── 상태 ────────────────────────────────────────────────────────────────────
  String _colorKey = 'peach'; // sage/peach/sky/lilac/butter/coral
  final _nickCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _pwCtrl     = TextEditingController();
  final _pw2Ctrl    = TextEditingController();

  bool _obscurePw  = true;
  bool _obscurePw2 = true;

  bool _emailChecking = false;
  bool? _emailAvailable;
  String? _emailCheckedFor;

  // 닉네임 중복확인. _nickCheckedFor 는 "어떤 값에 대한 결과인가"를 들고 있다 —
  // 확인 후 닉네임을 고치면 이전 결과가 그대로 남아 통과해버리는 걸 막는다.
  bool _nickChecking = false;
  bool? _nickAvailable;
  String? _nickCheckedFor;
  String? _nickReason;

  bool _agreeAll       = false;
  bool _agreeTos       = false; // 필수
  bool _agreePrivacy   = false; // 필수
  bool _agreeAge       = false; // 필수
  bool _agreeMarketing = false; // 선택

  bool get _reqAgreed => _agreeTos && _agreePrivacy && _agreeAge;

  // ── 팔레트 ──────────────────────────────────────────────────────────────────
  static const _palette = <(String, Color, Color)>[
    ('sage',   AppColors.petSage,   AppColors.petSageInk),
    ('peach',  AppColors.petPeach,  AppColors.petPeachInk),
    ('sky',    AppColors.petSky,    AppColors.petSkyInk),
    ('lilac',  AppColors.petLilac,  AppColors.petLilacInk),
    ('butter', AppColors.petButter, AppColors.petButterInk),
    ('coral',  AppColors.petCoral,  AppColors.petCoralInk),
  ];

  Color get _accentInk {
    for (final (key, _, ink) in _palette) {
      if (key == _colorKey) return ink;
    }
    return AppColors.petPeachInk;
  }

  Color get _selectedBg {
    for (final (key, bg, _) in _palette) {
      if (key == _colorKey) return bg;
    }
    return AppColors.petPeach;
  }

  // ── 비밀번호 강도 ────────────────────────────────────────────────────────────
  int _strength(String pw) {
    if (pw.isEmpty) return 0;
    int s = 0;
    if (pw.length >= 10) s++;
    if (RegExp(r'[0-9]').hasMatch(pw)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) s++;
    return s;
  }

  bool get _emailValid =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(_emailCtrl.text);
  bool get _pwValid =>
      _pwCtrl.text.length >= 10 &&
      [
        RegExp(r'[a-zA-Z]').hasMatch(_pwCtrl.text),
        RegExp(r'[0-9]').hasMatch(_pwCtrl.text),
        RegExp(r'[^A-Za-z0-9]').hasMatch(_pwCtrl.text),
      ].where((e) => e).length >= 2;
  bool get _pw2Match => _pwCtrl.text.isNotEmpty && _pwCtrl.text == _pw2Ctrl.text;

  String get _nickText => _nickCtrl.text.trim();

  /// 지금 입력된 닉네임이 "확인 완료 + 사용 가능" 상태인가.
  /// 다음 단계로 넘어갈 수 있는지의 유일한 기준이다.
  bool get _nickConfirmed =>
      _nickCheckedFor != null && _nickCheckedFor == _nickText && _nickAvailable == true;

  /// 확인 버튼을 누를 수 있는 최소 조건. 서버 왕복을 아끼려는 것뿐이고
  /// 실제 규칙 판정(길이·문자·예약어·중복)은 전부 서버가 한다.
  bool get _nickCheckable => _nickText.length >= 2 && !_nickChecking;

  Future<void> _checkNickname() async {
    if (!_nickCheckable) return;
    final nickname = _nickText;
    setState(() {
      _nickChecking = true;
      _nickAvailable = null;
      _nickReason = null;
    });
    try {
      final result =
          await ref.read(authRepositoryProvider).checkNicknameAvailable(nickname);
      if (!mounted) return;
      setState(() {
        _nickAvailable = result.available;
        _nickReason = result.reason;
        _nickCheckedFor = nickname;
      });
    } catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, '닉네임 확인에 실패했습니다', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _nickChecking = false);
    }
  }

  Future<void> _checkEmail() async {
    if (!_emailValid || _emailChecking) return;
    final email = _emailCtrl.text.trim();
    setState(() {
      _emailChecking = true;
      _emailAvailable = null;
    });
    try {
      final available =
          await ref.read(authRepositoryProvider).checkEmailAvailable(email);
      if (!mounted) return;
      setState(() {
        _emailAvailable = available;
        _emailCheckedFor = email;
      });
    } catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, '이메일 확인에 실패했습니다', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _emailChecking = false);
    }
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  void _toggleOne(String k) {
    setState(() {
      if (k == 'tos')       _agreeTos       = !_agreeTos;
      if (k == 'privacy')   _agreePrivacy   = !_agreePrivacy;
      if (k == 'age')       _agreeAge       = !_agreeAge;
      if (k == 'marketing') _agreeMarketing = !_agreeMarketing;
      _agreeAll = _agreeTos && _agreePrivacy && _agreeAge && _agreeMarketing;
    });
  }

  void _toggleAll() {
    setState(() {
      _agreeAll = !_agreeAll;
      _agreeTos = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeAge = _agreeAll;
      _agreeMarketing = _agreeAll;
    });
  }

  /// 약관 전문 열기. 동의 체크는 건드리지 않는다 — 읽었다고 동의한 건 아니다.
  void _showTerms(String id) {
    final doc = findLegalDocument(id);
    if (doc == null) return;
    showLegalDocument(context, doc);
  }

  Future<void> _submit() async {
    await ref.read(authStateProvider.notifier).signup(
      _emailCtrl.text.trim(),
      _pwCtrl.text,
      _nickCtrl.text.trim(),
      agreeTos: _agreeTos,
      agreePrivacy: _agreePrivacy,
      agreeAge: _agreeAge,
      agreeMarketing: _agreeMarketing,
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      error: (e, _) => ToastMessage.show(context, e.toString(), type: ToastType.error),
    );
  }

  // ── 스텝 빌드 ─────────────────────────────────────────────────────────────
  List<StepConfig> get _steps => [
    // ── Step 1: 프로필 ──────────────────────────────────────────────────────
    StepConfig(
      title: '프로필을 만들어요',
      desc: '테일로그 안에서 보일 이름과 색이에요.',
      // 중복확인을 통과해야만 다음 단계로 넘어간다.
      valid: () => _nickConfirmed,
      render: (ctx) => ListenableBuilder(
        listenable: _nickCtrl,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아바타 + 팔레트
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 아바타 프리뷰
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: _selectedBg,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Center(
                    child: Text('🦎', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROFILE COLOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.paleInk2,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PalettePicker(
                        value: _colorKey,
                        palette: _palette,
                        onChanged: (k) {
                          setState(() => _colorKey = k);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // 닉네임
            SField(
              label: '닉네임',
              hint: '2~20자 · 한글, 영문, 숫자, 밑줄(_)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PaleTextField(
                          controller: _nickCtrl,
                          placeholder: '테일로그 안에서 보일 이름',
                          // 닉네임을 고치면 직전 확인 결과를 즉시 버린다. 남겨두면
                          // 'A' 로 확인받고 'B' 로 바꾼 채 다음 단계로 넘어갈 수 있다.
                          onChanged: (_) => setState(() {
                            if (_nickCheckedFor != _nickText) {
                              _nickAvailable = null;
                              _nickReason = null;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _nickCheckable ? _checkNickname : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppColors.paleLine),
                          ),
                          child: _nickChecking
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  '중복확인',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: _nickCheckable
                                        ? AppColors.primary
                                        : AppColors.paleInk3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_nickCheckedFor != null &&
                      _nickCheckedFor == _nickText) ...[
                    const SizedBox(height: 6),
                    Text(
                      _nickAvailable == true
                          ? '✓ 사용 가능한 닉네임입니다'
                          : '✗ ${_nickReason ?? '사용할 수 없는 닉네임입니다'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _nickAvailable == true
                            ? const Color(0xFF3A8854)
                            : const Color(0xFFCC4422),
                      ),
                    ),
                  ] else if (_nickText.length >= 2) ...[
                    // 확인 전에는 왜 다음으로 못 넘어가는지 알려준다.
                    const SizedBox(height: 6),
                    const Text(
                      '중복확인을 눌러 주세요',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.paleInk3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),

    // ── Step 2: 로그인 정보 ──────────────────────────────────────────────────
    StepConfig(
      title: '로그인 정보',
      desc: '이메일과 비밀번호를 입력하세요.',
      valid: () =>
          _emailValid &&
          _emailCheckedFor == _emailCtrl.text.trim() &&
          _emailAvailable == true &&
          _pwValid &&
          _pw2Match,
      render: (_) => ListenableBuilder(
        listenable: Listenable.merge([_emailCtrl, _pwCtrl, _pw2Ctrl]),
        builder: (_, __) {
          final st = _strength(_pwCtrl.text);
          final Color stColor = st == 0
              ? Colors.transparent
              : st == 1
                  ? const Color(0xFFCC4422)
                  : st == 2
                      ? const Color(0xFFCC8800)
                      : const Color(0xFF3A8854);
          final stLabel = ['', '약함', '보통', '강함'][st];

          return Column(
            children: [
              SField(
                label: '이메일',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PaleTextField(
                            controller: _emailCtrl,
                            placeholder: 'name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _emailValid ? _checkEmail : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.paleLine),
                            ),
                            child: _emailChecking
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    '중복확인',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: _emailValid
                                          ? AppColors.primary
                                          : AppColors.paleInk3,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (_emailCheckedFor != null &&
                        _emailCheckedFor == _emailCtrl.text.trim()) ...[
                      const SizedBox(height: 6),
                      Text(
                        _emailAvailable == true
                            ? '✓ 사용 가능한 이메일입니다'
                            : '✗ 이미 가입된 이메일입니다',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _emailAvailable == true
                              ? const Color(0xFF3A8854)
                              : const Color(0xFFCC4422),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SField(
                label: '비밀번호',
                hint: '10자 이상, 2종류 이상 조합',
                child: Column(
                  children: [
                    PaleTextField(
                      controller: _pwCtrl,
                      placeholder: '비밀번호',
                      obscureText: _obscurePw,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePw = !_obscurePw),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            _obscurePw
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.paleInk3,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (_pwCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: st / 3,
                                minHeight: 4,
                                backgroundColor: AppColors.paleLine,
                                color: stColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: stColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SField(
                label: '비밀번호 확인',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PaleTextField(
                      controller: _pw2Ctrl,
                      placeholder: '비밀번호 다시 입력',
                      obscureText: _obscurePw2,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePw2 = !_obscurePw2),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            _obscurePw2
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.paleInk3,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (_pw2Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _pw2Match ? '✓ 일치합니다' : '✗ 비밀번호가 다릅니다',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _pw2Match
                              ? const Color(0xFF3A8854)
                              : const Color(0xFFCC4422),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),

    // ── Step 3: 약관 ─────────────────────────────────────────────────────────
    StepConfig(
      title: '약관에 동의해 주세요',
      desc: '필수 항목에 모두 동의하면 가입할 수 있어요.',
      valid: () => _reqAgreed,
      render: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.paleLine),
        ),
        child: Column(
          children: [
            _TermsItem(
              label: '전체 동의',
              checked: _agreeAll,
              isBold: true,
              hasBorder: true,
              onTap: () {
                _toggleAll();
                if (!_agreeAll && _reqAgreed) ctx.advance();
              },
            ),
            _TermsItem(
              label: '서비스 이용약관',
              checked: _agreeTos,
              badge: '필수',
              onTap: () => _toggleOne('tos'),
              onView: () => _showTerms('tos'),
            ),
            _TermsItem(
              label: '개인정보 처리방침',
              checked: _agreePrivacy,
              badge: '필수',
              onTap: () => _toggleOne('privacy'),
              onView: () => _showTerms('privacy'),
            ),
            _TermsItem(
              label: '만 14세 이상입니다',
              checked: _agreeAge,
              badge: '필수',
              onTap: () => _toggleOne('age'),
              onView: () => _showTerms('age'),
            ),
            _TermsItem(
              label: '마케팅 정보 수신',
              checked: _agreeMarketing,
              badge: '선택',
              isLast: true,
              onTap: () => _toggleOne('marketing'),
              onView: () => _showTerms('marketing'),
            ),
          ],
        ),
      ),
    ),

    // ── Step 4: 확인 ─────────────────────────────────────────────────────────
    StepConfig(
      title: '입력한 내용을 확인하세요',
      desc: '"수정"을 눌러 각 단계를 다시 고칠 수 있어요.',
      render: (ctx) => StepSummary(
        goEdit: ctx.goEdit,
        groups: [
          StepSummaryGroup(label: '프로필', step: 0, rows: [
            StepSummaryRow(k: '닉네임', v: _nickCtrl.text),
            StepSummaryRow(k: '색상', v: _colorKey),
          ]),
          StepSummaryGroup(label: '계정', step: 1, rows: [
            StepSummaryRow(k: '이메일', v: _emailCtrl.text),
            StepSummaryRow(
              k: '비밀번호',
              v: _pwCtrl.text.isNotEmpty ? '•' * _pwCtrl.text.length.clamp(0, 10) : '',
            ),
          ]),
          StepSummaryGroup(label: '약관', step: 2, rows: [
            StepSummaryRow(
              k: '필수 약관',
              v: _reqAgreed ? '모두 동의' : '미동의',
              muted: !_reqAgreed,
            ),
            StepSummaryRow(
              k: '마케팅 수신',
              v: _agreeMarketing ? '동의' : '미동의',
              muted: !_agreeMarketing,
            ),
          ]),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: StepShell(
          headerTitle: '회원가입',
          accentInk: _accentInk,
          steps: _steps,
          doneLabel: '가입 완료하고 시작',
          onDone: _submit,
          onCancel: () => context.pop(),
        ),
      ),
    );
  }
}

// ── 팔레트 피커 ────────────────────────────────────────────────────────────────

class _PalettePicker extends StatelessWidget {
  final String value;
  final List<(String, Color, Color)> palette;
  final void Function(String) onChanged;

  const _PalettePicker({
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.map((entry) {
        final (key, bg, ink) = entry;
        final sel = value == key;
        return GestureDetector(
          onTap: () => onChanged(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? ink : AppColors.paleLine,
                width: sel ? 2 : 1,
              ),
            ),
            child: sel
                ? Icon(Icons.check, size: 14, color: ink)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── 약관 항목 행 ────────────────────────────────────────────────────────────────

class _TermsItem extends StatelessWidget {
  final String label;
  final bool checked;
  final String? badge;
  final bool isBold;
  final bool hasBorder;
  final bool isLast;
  final VoidCallback onTap;

  /// 전문 보기. null 이면 화살표를 아예 그리지 않는다 ('전체 동의'가 그렇다).
  final VoidCallback? onView;

  const _TermsItem({
    required this.label,
    required this.checked,
    required this.onTap,
    this.onView,
    this.badge,
    this.isBold = false,
    this.hasBorder = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: hasBorder
              ? const Border(bottom: BorderSide(color: AppColors.paleLineSoft))
              : isLast
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
        ),
        child: Row(
          children: [
            _PaleCheckbox(checked: checked, large: isBold),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  if (badge != null) ...[
                    Text(
                      '[$badge]',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: badge == '필수'
                            ? const Color(0xFFCC4422)
                            : AppColors.paleInk3,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 화살표는 행과 별개의 탭 타겟이다 — 여기를 누르면 체크가 아니라 전문이 열린다.
            // 손가락으로 닿을 만한 크기를 주려고 아이콘 주변에 패딩을 깐다.
            if (onView != null)
              InkWell(
                onTap: onView,
                borderRadius: BorderRadius.zero,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.paleInk3,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppColors.paleInk3),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaleCheckbox extends StatelessWidget {
  final bool checked;
  final bool large;
  const _PaleCheckbox({required this.checked, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 22.0 : 18.0;
    final radius = large ? 6.0 : 9.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.paleLine,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: size * 0.65, color: AppColors.paleBg)
          : null,
    );
  }
}
