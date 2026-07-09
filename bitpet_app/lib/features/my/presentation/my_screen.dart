import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../../auth/providers/auth_provider.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('MY'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('프로필 로드 실패')),
        data: (user) => ListView(
          children: [
            // 프로필 영역 — 카드 없이 플랫 레이아웃
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
            const Divider(height: 1, thickness: 1, color: AppColors.divider),

            const SizedBox(height: 24),

            // 메뉴 그룹 1
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _MenuItem(
              icon: Icons.group_outlined,
              label: '그룹 관리',
              onTap: () => context.push('/groups/management'),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: '알림 설정',
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _MenuItem(
              icon: Icons.article_outlined,
              label: '내 게시글',
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _MenuItem(
              icon: Icons.info_outline,
              label: '앱 정보',
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),

            const SizedBox(height: 24),

            // 메뉴 그룹 2 — 계정
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
          ],
        ),
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
