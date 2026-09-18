// 자녀 계정 만들기.
//
// 보호자가 로그인한 상태에서만 열린다. 동의를 받는 사람과 누르는 사람이 같은 자리에
// 있어야 '법정대리인 동의'가 실제 동의가 되기 때문이다 — 아이에게 부모 이메일을
// 적게 하는 방식은 아무 주소나 적어도 통과해서 동의한 척한 기록만 남는다.
//
// 성공하면 `Navigator.pop(context, true)` 로 목록에 알린다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/guardian_repository.dart';
import '../../../core/theme/app_dimens.dart';

class ChildCreateScreen extends ConsumerStatefulWidget {
  const ChildCreateScreen({super.key});

  @override
  ConsumerState<ChildCreateScreen> createState() => _ChildCreateScreenState();
}

class _ChildCreateScreenState extends ConsumerState<ChildCreateScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();

  bool _obscurePw = true;
  DateTime? _birthDate;
  bool _agreeGuardian = false;
  bool _agreeMarketing = false;
  bool _submitting = false;

  /// 만 14세 미만만 자녀 계정이 된다. 서버도 같은 기준으로 다시 본다
  /// (여기 계산은 날짜 선택 범위를 좁혀 헛걸음을 줄이는 용도다).
  static const _consentAge = 14;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(_emailCtrl.text.trim());

  bool get _pwValid =>
      _pwCtrl.text.length >= 10 &&
      [
        RegExp(r'[a-zA-Z]').hasMatch(_pwCtrl.text),
        RegExp(r'[0-9]').hasMatch(_pwCtrl.text),
        RegExp(r'[^A-Za-z0-9]').hasMatch(_pwCtrl.text),
      ].where((e) => e).length >= 2;

  bool get _canSubmit =>
      !_submitting &&
      _emailValid &&
      _pwValid &&
      _nickCtrl.text.trim().length >= 2 &&
      _birthDate != null &&
      _agreeGuardian;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    // 만 14세가 되는 생일의 다음 날부터는 자녀 계정 대상이 아니다.
    final first = DateTime(now.year - _consentAge, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: first,
      lastDate: now,
      helpText: '자녀의 생년월일',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await ref.read(guardianRepositoryProvider).createChild(
            email: _emailCtrl.text.trim(),
            password: _pwCtrl.text,
            nickname: _nickCtrl.text.trim(),
            birthDate: _birthDate!,
            agreeMarketing: _agreeMarketing,
          );
      if (!mounted) return;
      showToast(context, '자녀 계정을 만들었어요', type: ToastType.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showToast(
        context,
        e is ApiException ? e.message : '자녀 계정을 만들지 못했습니다',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final birth = _birthDate;

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      appBar: AppBar(
        backgroundColor: AppColors.paleBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('자녀 계정 만들기',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              '자녀가 쓸 계정 정보를 보호자가 입력합니다.\n'
              '자녀는 이 이메일과 비밀번호로 직접 로그인해요.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.paleInk3),
            ),
            const SizedBox(height: 20),

            SField(
              label: '이메일',
              hint: '자녀가 로그인할 주소',
              child: PaleTextField(
                controller: _emailCtrl,
                placeholder: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SField(
              label: '비밀번호',
              hint: '10자 이상, 2종류 이상 조합',
              child: PaleTextField(
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
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            SField(
              label: '닉네임',
              hint: '2~20자',
              child: PaleTextField(
                controller: _nickCtrl,
                placeholder: '커뮤니티에서 쓸 이름',
                onChanged: (_) => setState(() {}),
              ),
            ),
            SField(
              label: '생년월일',
              hint: '만 14세 미만만 가능',
              child: GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brLg,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.paleLine),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          birth == null
                              ? '생년월일 선택'
                              : '${birth.year}년 ${birth.month}월 ${birth.day}일',
                          style: TextStyle(
                            fontSize: 14,
                            color: birth == null
                                ? AppColors.paleInk3
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.paleInk3),
                    ],
                  ),
                ),
              ),
            ),

            // ── 동의 ─────────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.brLg,
                color: AppColors.surface,
                border: Border.all(color: AppColors.paleLine),
              ),
              child: Column(
                children: [
                  _ConsentRow(
                    label: '법정대리인 동의',
                    badge: '필수',
                    checked: _agreeGuardian,
                    onTap: () =>
                        setState(() => _agreeGuardian = !_agreeGuardian),
                    onView: () =>
                        showLegalDocument(context, guardianConsentDocument),
                  ),
                  _ConsentRow(
                    label: '마케팅 정보 수신',
                    badge: '선택',
                    isLast: true,
                    checked: _agreeMarketing,
                    onTap: () =>
                        setState(() => _agreeMarketing = !_agreeMarketing),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '자녀 계정은 어린이 게시판에서만 글·댓글을 남길 수 있어요.\n'
              '다른 게시판의 글은 읽을 수 있습니다.',
              style: TextStyle(
                  fontSize: 11.5, height: 1.6, color: AppColors.paleInk3),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _canSubmit ? _submit : null,
                style: TextButton.styleFrom(
                  backgroundColor:
                      _canSubmit ? AppColors.primary : AppColors.paleLine,
                  foregroundColor: AppColors.paleBg,
                  disabledBackgroundColor: AppColors.paleLine,
                  disabledForegroundColor: AppColors.paleInk3,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brMd),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('자녀 계정 만들기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 동의 한 줄 ────────────────────────────────────────────────────────────────

class _ConsentRow extends StatelessWidget {
  final String label;
  final String badge;
  final bool checked;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onView;

  const _ConsentRow({
    required this.label,
    required this.badge,
    required this.checked,
    required this.onTap,
    this.onView,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
              ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brLg,
                color: checked ? AppColors.primary : AppColors.surface,
                border: Border.all(
                    color: checked ? AppColors.primary : AppColors.paleLine),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: AppColors.paleBg)
                  : null,
            ),
            const SizedBox(width: 8),
            Text('[$badge] ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badge == '필수'
                      ? AppColors.primary
                      : AppColors.paleInk3,
                )),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ),
            if (onView != null)
              GestureDetector(
                onTap: onView,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('보기',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.paleInk2,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.paleInk3,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
