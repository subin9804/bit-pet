import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/auth_provider.dart';
import 'widgets/terms_item.dart';

/// 로그인한 뒤 약관 동의를 받는 화면.
///
/// 소셜 가입은 약관 화면 없이 계정이 생기고, 서버는 그 자리에서 동의를 기록하지
/// 않는다(본 적 없는 약관에 동의했다는 거짓 기록이 된다). 그래서 로그인 직후
/// [needsAgreementProvider] 가 true 면 라우터가 여기로 보낸다. 약관이 개정돼
/// 재동의를 받을 때도 같은 화면이다.
///
/// 항목은 회원가입 3단계와 같다 — 같은 약관이 두 화면에서 다르게 보이면 안 된다.
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
  bool _age = false;
  bool _marketing = false;
  bool _saving = false;

  bool get _required => _tos && _privacy && _age;
  bool get _all => _required && _marketing;

  void _toggleAll() {
    final next = !_all;
    setState(() => _tos = _privacy = _age = _marketing = next);
  }

  void _show(String id) {
    final doc = findLegalDocument(id);
    if (doc != null) showLegalDocument(context, doc);
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .acceptAgreements(agreeMarketing: _marketing);
      // 이동은 라우터가 한다 (needsAgreementProvider 가 false 가 되면서)
    } catch (_) {
      if (!mounted) return;
      ToastMessage.show(context, '동의를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        checked: _all,
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
                        label: '만 14세 이상입니다',
                        checked: _age,
                        badge: '필수',
                        onTap: () => setState(() => _age = !_age),
                        onView: () => _show('age'),
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
                  onPressed: _saving
                      ? null
                      : () => ref.read(authStateProvider.notifier).logout(),
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
