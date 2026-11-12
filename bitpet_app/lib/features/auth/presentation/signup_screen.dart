import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/upload/image_source_sheet.dart';
import '../../../core/upload/image_upload.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../../../core/widgets/user_avatar.dart';
import '../data/age_gate.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import 'widgets/terms_item.dart';
import 'widgets/under_age_notice.dart';
import '../../../core/theme/app_dimens.dart';

// ════════════════════════════════════════════════════════════════
// 11s · 회원가입 — 5단계 스텝 위저드
// 0) 생년월일  1) 프로필(사진·색·닉네임)  2) 로그인 정보  3) 약관  4) 확인
// ════════════════════════════════════════════════════════════════

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // ── 상태 ────────────────────────────────────────────────────────────────────
  String _colorKey = ProfilePalette.defaultKey; // sage/peach/sky/lilac/butter/coral

  /// 가입 중 고른 프로필 사진. 아직 **업로드되지 않은 바이트**다 —
  /// presign 이 인증을 요구하는데 이 시점엔 계정도 토큰도 없어서,
  /// 가입·자동로그인이 끝난 뒤 `AuthRepository.signup` 이 올린다.
  PickedImage? _profileImage;

  final _nickCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _pwCtrl     = TextEditingController();
  final _pw2Ctrl    = TextEditingController();

  bool _obscurePw  = true;
  bool _obscurePw2 = true;

  // 이메일 — 중복·도메인 확인 → 인증 코드 발송 → 코드 확인(토큰). 각 결과는 "어떤 주소에 대한
  // 것인가"를 같이 들고 있어서, 주소를 고치면 이전 확인·인증이 자동으로 무효가 된다.
  final _codeCtrl = TextEditingController();
  bool _emailChecking = false;
  bool? _emailAvailable;
  bool _emailDomainAllowed = true;
  String? _emailCheckedFor;
  String? _codeSentFor;
  bool _codeVerifying = false;
  String? _verifyToken;
  String? _verifiedFor;

  // 닉네임 중복확인. _nickCheckedFor 는 "어떤 값에 대한 결과인가"를 들고 있다 —
  // 확인 후 닉네임을 고치면 이전 결과가 그대로 남아 통과해버리는 걸 막는다.
  bool _nickChecking = false;
  bool? _nickAvailable;
  String? _nickCheckedFor;
  String? _nickReason;

  bool _agreeAll       = false;
  bool _agreeTos       = false; // 필수
  bool _agreePrivacy   = false; // 필수
  bool _agreeMarketing = false; // 선택

  bool get _reqAgreed => _agreeTos && _agreePrivacy;

  // 연령 확인 — 기준 나이는 화면에 쓰지 않는다 (AgeGate 주석).
  DateTime? _birthDate;

  /// 만 14세 미만으로 판정됐거나, 이 기기에서 전에 그렇게 판정된 적이 있다.
  /// true 면 가입 위저드 대신 보호자 안내만 보인다.
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    ref.read(ageGateStoreProvider).isBlocked().then((blocked) {
      if (blocked && mounted) setState(() => _blocked = true);
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: '생년월일',
    );
    if (picked == null || !mounted) return;
    if (AgeGate.isUnderConsentAge(picked)) {
      await ref.read(ageGateStoreProvider).block();
      if (mounted) setState(() => _blocked = true);
      return;
    }
    setState(() => _birthDate = picked);
  }

  String _fmtDate(DateTime d) => '${d.year}년 ${d.month}월 ${d.day}일';

  // ── 팔레트 ──────────────────────────────────────────────────────────────────
  // 목록은 ProfilePalette 한 곳에만 둔다 — 마이페이지와 각자 들고 있으면 반드시 어긋난다.
  static const _palette = ProfilePalette.entries;

  Color get _accentInk => ProfilePalette.inkOf(_colorKey);

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

  /// 중복확인 실패 토스트 문구.
  ///
  /// 그냥 "확인에 실패했습니다"로 뭉뚱그리면 **서버가 거절한 것**과 **서버에 닿지도 못한 것**이
  /// 같은 문장으로 보인다. 둘은 사용자가 할 일이 완전히 다르다(고치기 vs 기다리기).
  /// 실제로 이것 때문에 "닉네임이 거부된다"로 오해해 한참 엉뚱한 데를 팠다 —
  /// 원인은 `adb reverse` 가 안 걸려 요청이 서버까지 가지도 않은 것이었다.
  String _checkFailMessage(Object e, String what) {
    if (e is DioException &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout)) {
      return '서버에 연결할 수 없습니다. 네트워크를 확인해주세요';
    }
    return '$what 확인에 실패했습니다';
  }

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
      ToastMessage.show(context, _checkFailMessage(e, '닉네임'), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _nickChecking = false);
    }
  }

  String get _emailText => _emailCtrl.text.trim();

  bool get _emailVerified =>
      _verifyToken != null && _verifiedFor != null && _verifiedFor == _emailText;

  bool get _codeSentForCurrent => _codeSentFor != null && _codeSentFor == _emailText;

  /// 서버가 내려준 안내 문구(SIGNUP_*, AUTH_EMAIL_* 는 한국어로 온다). 못 닿았으면 연결 안내.
  String _serverMessage(Object e, String fallback) {
    if (e is DioException) {
      // AUTH_EMAIL_ALREADY_EXISTS 문구는 영어라 여기서 바꾼다
      if (e.response?.statusCode == 409) return '이미 가입된 이메일입니다';
      final data = e.response?.data;
      String? msg;
      if (data is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>?;
        msg = error?['message'] as String?;
      }
      return msg ?? _checkFailMessage(e, '이메일');
    }
    if (e is ApiException) return e.message;
    return fallback;
  }

  /// 인증요청 — 중복·도메인을 먼저 보고, 통과하면 코드를 보낸다.
  /// 확인을 따로 누르게 하면 버튼이 둘이 되고 순서를 헷갈린다.
  Future<void> _requestEmailCode() async {
    if (!_emailValid || _emailChecking || _emailVerified) return;
    final email = _emailText;
    setState(() {
      _emailChecking = true;
      _emailAvailable = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.checkEmailAvailable(email);
      if (!mounted) return;
      setState(() {
        _emailAvailable = result.available;
        _emailDomainAllowed = result.domainAllowed;
        _emailCheckedFor = email;
      });
      if (!result.available) return;

      await repo.sendSignupEmailCode(email);
      if (!mounted) return;
      setState(() {
        _codeSentFor = email;
        _codeCtrl.clear();
      });
      ToastMessage.show(context, '인증 코드를 보냈어요. 메일함을 확인해 주세요');
    } catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, _serverMessage(e, '인증 코드 발송에 실패했습니다'),
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _emailChecking = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6 || _codeVerifying || !_codeSentForCurrent) return;
    final email = _emailText;
    setState(() => _codeVerifying = true);
    try {
      final token =
          await ref.read(authRepositoryProvider).verifySignupEmailCode(email, code);
      if (!mounted) return;
      setState(() {
        _verifyToken = token;
        _verifiedFor = email;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, _serverMessage(e, '인증 코드 확인에 실패했습니다'),
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _codeVerifying = false);
    }
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  void _toggleOne(String k) {
    setState(() {
      if (k == 'tos')       _agreeTos       = !_agreeTos;
      if (k == 'privacy')   _agreePrivacy   = !_agreePrivacy;
      if (k == 'marketing') _agreeMarketing = !_agreeMarketing;
      _agreeAll = _agreeTos && _agreePrivacy && _agreeMarketing;
    });
  }

  void _toggleAll() {
    setState(() {
      _agreeAll = !_agreeAll;
      _agreeTos = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeMarketing = _agreeAll;
    });
  }

  /// 약관 전문 열기. 동의 체크는 건드리지 않는다 — 읽었다고 동의한 건 아니다.
  void _showTerms(String id) {
    final doc = findLegalDocument(id);
    if (doc == null) return;
    showLegalDocument(context, doc);
  }

  /// 프로필 사진 고르기. 여기서는 **고르기만** 한다 — 업로드는 가입 후다(위 _profileImage 주석).
  Future<void> _pickProfileImage() async {
    try {
      final picked = await pickImageWithSource(context, ref);
      if (picked == null || !mounted) return;
      setState(() => _profileImage = picked);
    } catch (_) {
      if (!mounted) return;
      ToastMessage.show(context, '사진을 불러오지 못했습니다', type: ToastType.error);
    }
  }

  Future<void> _submit() async {
    await ref.read(authStateProvider.notifier).signup(
      _emailCtrl.text.trim(),
      _pwCtrl.text,
      _nickCtrl.text.trim(),
      agreeTos: _agreeTos,
      agreePrivacy: _agreePrivacy,
      birthDate: _birthDate!,
      agreeMarketing: _agreeMarketing,
      emailVerificationToken: _verifyToken!,
      profileColor: _colorKey,
      profileImage: _profileImage,
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      error: (e, _) => ToastMessage.show(context, e.toString(), type: ToastType.error),
    );
  }

  // ── 스텝 빌드 ─────────────────────────────────────────────────────────────
  List<StepConfig> get _steps => [
    // ── Step 0: 생년월일 ────────────────────────────────────────────────────
    // '만 14세 이상인가요?'라고 물으면 답이 정해져 버린다. 기준은 말하지 않고 날짜만 받는다.
    StepConfig(
      title: '생년월일을 알려주세요',
      desc: '가입하시는 분의 생년월일이에요. 확인에만 쓰고 저장하지 않아요.',
      valid: () => _birthDate != null,
      render: (_) => GestureDetector(
        onTap: _pickBirthDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 20, color: AppColors.ink3),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _birthDate == null ? '생년월일 선택' : _fmtDate(_birthDate!),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _birthDate == null ? AppColors.ink3 : AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    ),

    // ── Step 1: 프로필 ──────────────────────────────────────────────────────
    StepConfig(
      title: '프로필을 만들어요',
      desc: '테일로그 안에서 보일 사진과 이름, 색이에요.',
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
                // 아바타 프리뷰 — 탭하면 사진 선택. 사진을 고르면 고른 색이 3px 테두리로 남는다
                Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: UserAvatar(
                        size: 92,
                        colorKey: _colorKey,
                        localBytes: _profileImage?.bytes,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _profileImage == null
                          ? _pickProfileImage
                          : () => setState(() => _profileImage = null),
                      child: Text(
                        _profileImage == null ? '사진 추가' : '사진 지우기',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROFILE COLOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink2,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
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
            const SizedBox(height: 20),
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
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: AppRadius.brLg,
                            border: Border.all(color: AppColors.line),
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
                                        ? AppColors.brandAction
                                        : AppColors.ink3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_nickCheckedFor != null &&
                      _nickCheckedFor == _nickText) ...[
                    const SizedBox(height: 8),
                    Text(
                      _nickAvailable == true
                          ? '✓ 사용 가능한 닉네임입니다'
                          : '✗ ${_nickReason ?? '사용할 수 없는 닉네임입니다'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _nickAvailable == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ] else if (_nickText.length >= 2) ...[
                    // 확인 전에는 왜 다음으로 못 넘어가는지 알려준다.
                    const SizedBox(height: 8),
                    const Text(
                      '중복확인을 눌러 주세요',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
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
      // 이메일은 인증 코드까지 확인해야 넘어간다 — 주소가 진짜인지 서버가 확인한 상태
      valid: () => _emailValid && _emailVerified && _pwValid && _pw2Match,
      render: (_) => ListenableBuilder(
        listenable: Listenable.merge([_emailCtrl, _codeCtrl, _pwCtrl, _pw2Ctrl]),
        builder: (_, __) {
          final st = _strength(_pwCtrl.text);
          final Color stColor = st == 0
              ? Colors.transparent
              : st == 1
                  ? AppColors.error
                  : st == 2
                      ? AppColors.warning
                      : AppColors.success;
          final stLabel = ['', '약함', '보통', '강함'][st];

          return Column(
            children: [
              SField(
                label: '이메일',
                hint: '네이버·카카오·다음(한메일)·네이트·지메일·iCloud·아웃룩 메일로 가입할 수 있어요',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PaleTextField(
                            controller: _emailCtrl,
                            placeholder: 'name@naver.com',
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SmallButton(
                          label: _emailVerified
                              ? '인증완료'
                              : _codeSentForCurrent
                                  ? '재전송'
                                  : '인증요청',
                          loading: _emailChecking,
                          enabled: _emailValid && !_emailVerified,
                          onTap: _requestEmailCode,
                        ),
                      ],
                    ),
                    if (_emailVerified) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '✓ 이메일 인증이 완료되었습니다',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ] else if (_emailCheckedFor != null &&
                        _emailCheckedFor == _emailText &&
                        _emailAvailable == false) ...[
                      const SizedBox(height: 8),
                      Text(
                        _emailDomainAllowed
                            ? '✗ 이미 가입된 이메일입니다'
                            : '✗ 지원하지 않는 메일이에요. 위 안내의 메일로 가입해 주세요',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ] else if (_codeSentForCurrent) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: PaleTextField(
                              controller: _codeCtrl,
                              placeholder: '인증 코드 6자리',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SmallButton(
                            label: '확인',
                            loading: _codeVerifying,
                            enabled: _codeCtrl.text.trim().length == 6,
                            onTap: _verifyEmailCode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '메일로 받은 6자리 코드를 입력해 주세요 (10분 안에). 안 보이면 스팸함도 확인해 주세요',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                      ),
                    ] else if (_emailValid) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '인증요청을 눌러 메일로 코드를 받아 주세요',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
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
                            color: AppColors.ink3,
                            size: 20,
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
                                backgroundColor: AppColors.line,
                                color: stColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stLabel,
                            style: TextStyle(
                              fontSize: 12,
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
                            color: AppColors.ink3,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_pw2Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pw2Match ? '✓ 일치합니다' : '✗ 비밀번호가 다릅니다',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _pw2Match
                              ? AppColors.success
                              : AppColors.error,
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
          color: AppColors.card,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            TermsItem(
              label: '전체 동의',
              checked: _agreeAll,
              isBold: true,
              hasBorder: true,
              onTap: () {
                _toggleAll();
                if (!_agreeAll && _reqAgreed) ctx.advance();
              },
            ),
            TermsItem(
              label: '서비스 이용약관',
              checked: _agreeTos,
              badge: '필수',
              onTap: () => _toggleOne('tos'),
              onView: () => _showTerms('tos'),
            ),
            TermsItem(
              label: '개인정보 처리방침',
              checked: _agreePrivacy,
              badge: '필수',
              onTap: () => _toggleOne('privacy'),
              onView: () => _showTerms('privacy'),
            ),
            TermsItem(
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
          StepSummaryGroup(label: '생년월일', step: 0, rows: [
            StepSummaryRow(
              k: '생년월일',
              v: _birthDate == null ? '' : _fmtDate(_birthDate!),
            ),
          ]),
          StepSummaryGroup(label: '프로필', step: 1, rows: [
            StepSummaryRow(k: '닉네임', v: _nickCtrl.text),
            StepSummaryRow(k: '색상', v: _colorKey),
            StepSummaryRow(k: '프로필 사진', v: _profileImage == null ? '없음' : '선택됨'),
          ]),
          StepSummaryGroup(label: '계정', step: 2, rows: [
            StepSummaryRow(k: '이메일', v: _emailCtrl.text),
            StepSummaryRow(
              k: '비밀번호',
              v: _pwCtrl.text.isNotEmpty ? '•' * _pwCtrl.text.length.clamp(0, 10) : '',
            ),
          ]),
          StepSummaryGroup(label: '약관', step: 3, rows: [
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
    if (_blocked) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: UnderAgeNotice(
            buttonLabel: '확인',
            onPressed: () => context.pop(),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
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

// ── 입력칸 옆 작은 버튼 (인증요청·확인) ────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !loading ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.line),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: enabled ? AppColors.brandAction : AppColors.ink3,
                ),
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
                color: sel ? ink : AppColors.line,
                width: sel ? 2 : 1,
              ),
            ),
            child: sel
                ? Icon(Icons.check, size: 16, color: ink)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

