import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/age_gate.dart';
import '../providers/auth_provider.dart';
import 'widgets/terms_item.dart';
import 'widgets/under_age_notice.dart';

/// 로그인한 뒤 약관 동의를 받는 화면.
///
/// 소셜 가입은 약관 화면 없이 계정이 생기고, 서버는 그 자리에서 동의를 기록하지
/// 않는다(본 적 없는 약관에 동의했다는 거짓 기록이 된다). 그래서 로그인 직후
/// [needsAgreementProvider] 가 true 면 라우터가 여기로 보낸다. 약관이 개정돼
/// 재동의를 받을 때도 같은 화면이다.
///
/// 항목은 회원가입과 같다 — 같은 약관이 두 화면에서 다르게 보이면 안 된다.
/// 연령 확인(생년월일)은 소셜로 막 가입한 계정에만 묻는다([ageCheckNeededProvider]).
/// 재동의는 이미 확인을 마친 계정이다.
/// 나가는 길은 '다른 계정으로 로그인'(로그아웃) 하나뿐이다. 동의 없이 앱 안으로
/// 들여보낼 수는 없다.
class AgreementScreen extends ConsumerStatefulWidget {
  const AgreementScreen({super.key});

  @override
  ConsumerState<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends ConsumerState<AgreementScreen> {
  bool _tos = false;
  bool _privacy = false;
  bool _marketing = false;
  bool _saving = false;

  DateTime? _birthDate;
  bool _blocked = false;

  bool get _askAge => ref.watch(ageCheckNeededProvider);
  bool get _required => _tos && _privacy && (!_askAge || _birthDate != null);
  bool get _allChecked => _tos && _privacy && _marketing;

  @override
  void initState() {
    super.initState();
    if (!ref.read(ageCheckNeededProvider)) return;
    ref.read(ageGateStoreProvider).isBlocked().then((blocked) {
      if (blocked && mounted) setState(() => _blocked = true);
    });
  }

  void _toggleAll() {
    final next = !_allChecked;
    setState(() => _tos = _privacy = _marketing = next);
  }

  void _show(String id) {
    final doc = findLegalDocument(id);
    if (doc != null) showLegalDocument(context, doc);
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

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).acceptAgreements(
            agreeMarketing: _marketing,
            birthDate: _askAge ? _birthDate : null,
          );
      // 이동은 라우터가 한다 (needsAgreementProvider 가 false 가 되면서)
    } catch (_) {
      if (!mounted) return;
      ToastMessage.show(context, '동의를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _logout() => ref.read(authStateProvider.notifier).logout();

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: UnderAgeNotice(buttonLabel: '확인', onPressed: _logout),
          ),
        ),
      );
    }

    final birth = _birthDate;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.x40),
                Text('약관에 동의해 주세요', style: AppTextStyles.display),
                const SizedBox(height: AppSpacing.sm),
                Text('필수 항목에 모두 동의하면 tailog 를 시작할 수 있어요.',
                    style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxl),
                if (_askAge) ...[
                  // 기준 나이는 쓰지 않는다 — 회원가입 0단계와 같은 이유 (AgeGate)
                  Text('생년월일', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined,
                              size: 20, color: AppColors.ink3),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              birth == null
                                  ? '생년월일 선택'
                                  : '${birth.year}년 ${birth.month}월 ${birth.day}일',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: birth == null
                                    ? AppColors.ink3
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.ink3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('확인에만 쓰고 저장하지 않아요.',
                      style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      TermsItem(
                        label: '전체 동의',
                        checked: _allChecked,
                        isBold: true,
                        hasBorder: true,
                        onTap: _toggleAll,
                      ),
                      TermsItem(
                        label: '서비스 이용약관',
                        checked: _tos,
                        badge: '필수',
                        onTap: () => setState(() => _tos = !_tos),
                        onView: () => _show('tos'),
                      ),
                      TermsItem(
                        label: '개인정보 처리방침',
                        checked: _privacy,
                        badge: '필수',
                        onTap: () => setState(() => _privacy = !_privacy),
                        onView: () => _show('privacy'),
                      ),
                      TermsItem(
                        label: '마케팅 정보 수신',
                        checked: _marketing,
                        badge: '선택',
                        isLast: true,
                        onTap: () => setState(() => _marketing = !_marketing),
                        onView: () => _show('marketing'),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  '동의하고 시작하기',
                  onPressed: _required && !_saving ? _accept : null,
                  loading: _saving,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _saving ? null : _logout,
                  child: Text('다른 계정으로 로그인',
                      style: AppTextStyles.caption),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
