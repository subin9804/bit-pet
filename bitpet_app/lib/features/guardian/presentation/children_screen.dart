// 마이페이지 > 자녀 계정.
//
// 만 14세 미만은 직접 가입할 수 없고, 보호자가 여기서 계정을 만들어 준다.
// 동의 주체가 화면 앞에 실재해야 하기 때문이다 — 보호자 이메일로 링크를 보내는 방식은
// 아이가 아무 주소나 적어도 통과해서, 동의를 받은 척하는 기록만 쌓인다.
//
// ⛔ '자녀 계정으로 로그인' 같은 대리 진입을 붙이지 말 것. 아이 계정으로 쓴 글의
//    작성자가 누구인지 아무도 답할 수 없게 된다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/guardian_repository.dart';
import 'child_create_screen.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, ChildAccount child) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('자녀 계정 삭제'),
        content: Text('${child.nickname} 님의 계정을 삭제할까요?\n'
            '등록한 개체와 사육 기록도 함께 삭제되며, 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(guardianRepositoryProvider).deleteChild(child.id);
      ref.invalidate(childrenProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제하지 못했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

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
        title: Text('자녀 계정',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
        centerTitle: true,
      ),
      body: childrenAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Text('목록을 불러오지 못했어요',
              style: AppTextStyles.body.copyWith(color: AppColors.paleInk3)),
        ),
        data: (children) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                '만 14세 미만 자녀는 보호자가 계정을 만들어 주셔야 해요.\n'
                '자녀 계정은 어린이 게시판에서만 글과 댓글을 남길 수 있어요.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.paleInk3, height: 1.6),
              ),
            ),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('아직 만든 자녀 계정이 없어요.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.paleInk3)),
              ),
            for (final c in children)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                      color: AppColors.petSage, shape: BoxShape.circle),
                  child: c.profileImageUrl != null
                      ? Image.network(c.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.child_care_rounded,
                              size: 20,
                              color: AppColors.paleInk2))
                      : const Icon(Icons.child_care_rounded,
                          size: 20, color: AppColors.paleInk2),
                ),
                title: Text(c.nickname,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                subtitle: Text(
                  // 만 14세가 지나면 어린이 게시판 제한이 풀린다 — 보호자가 알아야 할 변화다.
                  c.isChild ? c.email : '${c.email} · 만 14세가 되어 일반 회원이에요',
                  style: AppTextStyles.monoXs,
                ),
                trailing: TextButton(
                  onPressed: () => _delete(context, ref, c),
                  child: Text('삭제',
                      style: AppTextStyles.bodyBold
                          .copyWith(fontSize: 12, color: AppColors.paleInk3)),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => const ChildCreateScreen()),
                  );
                  if (created == true) ref.invalidate(childrenProvider);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('자녀 계정 만들기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
