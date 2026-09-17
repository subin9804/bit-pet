// 차단 목록 — 내가 차단한 사람만 보인다.
//
// ⛔ "나를 차단한 사람" 은 보여주지 않는다. 차단 사실이 드러나면 차단이 보복의 방아쇠가 된다.
// 신고로 함께 생긴 차단도 여기서 푼다 — 다만 신고 자체는 이력이라 남는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/report_models.dart';
import '../data/post_repository.dart';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  return ref.watch(postRepositoryProvider).getBlockedUsers();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(
      BuildContext context, WidgetRef ref, BlockedUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('차단 해제'),
        content: Text('${user.nickname} 님의 차단을 해제할까요?\n'
            '다시 서로의 글과 댓글이 보이게 됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('해제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(postRepositoryProvider).unblockUser(user.userId);
      ref.invalidate(blockedUsersProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단 해제에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      appBar: AppBar(
        backgroundColor: AppColors.paleBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('차단 목록',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
        centerTitle: true,
      ),
      body: blockedAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Text('목록을 불러오지 못했어요',
              style: AppTextStyles.body.copyWith(color: AppColors.paleInk3)),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '차단한 사용자가 없어요.\n게시글이나 댓글의 ⋯ 메뉴에서 차단할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.paleInk3, height: 1.6),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.paleLine),
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                      color: AppColors.petSage, shape: BoxShape.circle),
                  child: u.profileImageUrl != null
                      ? Image.network(u.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets_rounded,
                              size: 16,
                              color: AppColors.paleInk2))
                      : const Icon(Icons.pets_rounded,
                          size: 16, color: AppColors.paleInk2),
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
                          fontSize: 12, color: AppColors.primary)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
