import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pet/share/providers/share_provider.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('MY'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('프로필 로드 실패')),
        data: (user) => ListView(
          children: [
            // 프로필 영역 — 카드 없이 플랫 레이아웃
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    color: AppColors.bg2,
                    child: const Icon(Icons.person,
                        color: AppColors.textSecondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '사용자',
                          style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        color: AppColors.bg2,
                        child: Text(
                          user?.userType == 'BREEDER' ? 'BREEDER' : 'GENERAL',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.textSecondary,
                                  letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 내 공유코드 — 다른 사육자가 이 코드로 나를 개체 공유/입분양 대상으로 지정
            const _ShareCodeCard(),
            const SizedBox(height: 24),

            // 메뉴 그룹 1
            _MenuItem(
              icon: Icons.mail_outline,
              label: '받은 공유 초대',
              onTap: () => context.push('/share/inbox'),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: '알림 설정',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.article_outlined,
              label: '내 게시글',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: '앱 정보',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // 메뉴 그룹 2 — 계정
            _MenuItem(
              icon: Icons.logout,
              label: '로그아웃',
              onTap: () async {
                final ok = await ConfirmModal.show(
                  context,
                  title: '로그아웃',
                  message: '로그아웃 하시겠어요?',
                  confirmLabel: '로그아웃',
                );
                if (ok && context.mounted) {
                  await ref.read(authStateProvider.notifier).logout();
                }
              },
            ),
            _MenuItem(
              icon: Icons.person_remove_outlined,
              label: '회원 탈퇴',
              labelColor: AppColors.error,
              onTap: () async {
                final ok = await ConfirmModal.show(
                  context,
                  title: '회원 탈퇴',
                  message: '탈퇴 시 30일 이후 모든 데이터가 삭제됩니다. 정말 탈퇴하시겠어요?',
                  confirmLabel: '탈퇴',
                  isDangerous: true,
                );
                if (ok && context.mounted) {
                  ToastMessage.show(context, '탈퇴 처리 중...');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 내 공유코드 카드 — 조회 시 서버가 없으면 발급. 복사 지원.
class _ShareCodeCard extends ConsumerWidget {
  const _ShareCodeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(myShareCodeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내 공유코드', style: AppTextStyles.label),
              const SizedBox(height: 4),
              codeAsync.when(
                loading: () => Text('발급 중...', style: AppTextStyles.h3),
                error: (_, __) =>
                    Text('불러오기 실패', style: AppTextStyles.caption),
                data: (code) => Text(
                  code,
                  style: AppTextStyles.h3.copyWith(
                    letterSpacing: 2.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          codeAsync.maybeWhen(
            data: (code) => IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: AppColors.textSecondary,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ToastMessage.show(context, '공유코드를 복사했어요');
                }
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: labelColor ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.body.copyWith(color: labelColor)),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
