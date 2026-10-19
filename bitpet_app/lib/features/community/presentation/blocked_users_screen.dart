// 차단 목록 — 내가 차단한 사람만 보인다.
//
// ⛔ "나를 차단한 사람" 은 보여주지 않는다. 차단 사실이 드러나면 차단이 보복의 방아쇠가 된다.
// 신고로 함께 생긴 차단도 여기서 푼다 — 다만 신고 자체는 이력이라 남는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/report_models.dart';
import '../data/post_repository.dart';
import '../../../core/widgets/app_network_image.dart';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  return ref.watch(postRepositoryProvider).getBlockedUsers();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(
      BuildContext context, WidgetRef ref, BlockedUser user) async {
    final ok = await ConfirmModal.show(
      context,
      title: '차단 해제',
      message: '${user.nickname} 님의 차단을 해제할까요?\n'
          '다시 서로의 글과 댓글이 보이게 됩니다.',
      confirmLabel: '해제',
    );
    if (!ok) return;
    try {
      await ref.read(postRepositoryProvider).unblockUser(user.userId);
      ref.invalidate(blockedUsersProvider);
    } catch (_) {
      if (!context.mounted) return;
      showToast(context, '차단 해제에 실패했어요. 잠시 후 다시 시도해주세요.',
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // 흰 AppBar + 가운데 15px 제목이었다 — 연회색 본문 위에 머리만 흰 띠로 떴다.
      // 다른 하위 화면과 같은 테마 기본(왼쪽 정렬 제목, 본문과 같은 바탕)으로.
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('차단 목록'),
        titleSpacing: 0,
      ),
      body: blockedAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 다시 시도해주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral,
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(blockedUsersProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            // 차단 목록이 빈 것은 정상이고 '만들 것'도 아니다 → 무채색.
            return const EmptyState(
              message: '차단한 사용자가 없어요',
              subMessage: '게시글이나 댓글의 ⋯ 메뉴에서 차단할 수 있어요.',
              icon: Icons.block,
              tone: EmptyTone.neutral,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.line),
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                      color: AppColors.bgAlt, shape: BoxShape.circle),
                  child: u.profileImageUrl != null
                      ? AppNetworkImage(u.profileImageUrl,
                          fit: BoxFit.cover,
                          memWidth: 100,
                          placeholder: const Icon(
                              Icons.person,
                              size: 16,
                              color: AppColors.ink2))
                      : const Icon(Icons.person,
                          size: 16, color: AppColors.ink2),
                ),
                title: Text(u.nickname,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                subtitle: Text(
                  '${u.blockedAt.toLocal().year}.'
                  '${u.blockedAt.toLocal().month.toString().padLeft(2, '0')}.'
                  '${u.blockedAt.toLocal().day.toString().padLeft(2, '0')} 차단',
                  style: AppTextStyles.monoXs,
                ),
                trailing: TextButton(
                  onPressed: () => _unblock(context, ref, u),
                  child: Text('해제',
                      style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 12, color: AppColors.brandAction)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
