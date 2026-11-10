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

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../../my/presentation/widgets/menu_group.dart';
import '../data/guardian_repository.dart';
import 'child_create_screen.dart';
import '../../../core/widgets/app_network_image.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, ChildAccount child) async {
    // 되돌릴 수 없는 삭제라 **닉네임을 직접 입력**해야 확인이 열린다.
    // 아이 계정과 그 아이의 기록이 버튼 한 번으로 사라지면 안 된다.
    final ok = await ConfirmModal.show(
      context,
      title: '자녀 계정 삭제',
      message: '${child.nickname} 님의 계정을 삭제할까요?\n'
          '등록한 개체와 사육 기록도 함께 삭제되며, 되돌릴 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
      requireTextConfirmation: child.nickname,
    );
    if (!ok) return;
    try {
      await ref.read(guardianRepositoryProvider).deleteChild(child.id);
      ref.invalidate(childrenProvider);
    } catch (_) {
      if (!context.mounted) return;
      showToast(context, '삭제하지 못했어요. 잠시 후 다시 시도해주세요.',
          type: ToastType.error);
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChildCreateScreen()),
    );
    if (created == true) ref.invalidate(childrenProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    const intro = Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: _Intro(),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 0,
        title: const Text('자녀 계정'),
      ),
      body: childrenAsync.when(
        loading: () => const SkeletonCardList(count: 2),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          tone: EmptyTone.neutral,
          message: '목록을 불러오지 못했어요',
          subMessage: '잠시 후 다시 시도해 주세요.',
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(childrenProvider),
        ),
        data: (children) {
          if (children.isEmpty) {
            return Column(
              children: [
                intro,
                Expanded(
                  child: EmptyState(
                    icon: Icons.child_care_outlined,
                    message: '아직 만든 자녀 계정이 없어요',
                    subMessage: '보호자가 직접 만들어 주면 바로 쓸 수 있어요.',
                    actionLabel: '자녀 계정 만들기',
                    onAction: () => _create(context, ref),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 40),
            children: [
              intro,
              MenuCard(children: [
                for (final c in children) ...[
                  _ChildRow(child: c, onDelete: () => _delete(context, ref, c)),
                  // 만 14세가 지난 계정엔 스위치가 의미 없다 (서버가 성인으로 본다)
                  if (c.isChild) _CommunityToggle(child: c),
                ],
              ]),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppActionButton(
                  '자녀 계정 만들기',
                  icon: Icons.add_rounded,
                  tone: AppButtonTone.neutral,
                  onPressed: () => _create(context, ref),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => Text(
        '만 14세 미만 자녀는 보호자가 계정을 만들어 주셔야 해요.\n'
        '자녀 계정은 어린이 게시판에서만 글과 댓글을 남길 수 있어요.\n'
        '커뮤니티는 보호자가 허용해야 쓸 수 있어요.',
        style: AppTextStyles.caption.copyWith(height: 1.6),
      );
}

/// 자녀 한 명. 아바타 40 + 닉네임/이메일 + 삭제. 구분선 들여쓰기(52)는
/// [MenuCard] 기본값이 아이콘 20 기준이라 아바타 폭과는 다르지만, 줄 높이가 커서
/// 카드 왼쪽 끝까지 긋지 않는 정도면 충분하다.
class _ChildRow extends StatelessWidget {
  final ChildAccount child;
  final VoidCallback onDelete;
  const _ChildRow({required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = child;
    const fallback =
        Icon(Icons.child_care_rounded, size: 20, color: AppColors.brandTintInk);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
                color: AppColors.brandTint, shape: BoxShape.circle),
            child: c.profileImageUrl != null
                ? AppNetworkImage(c.profileImageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    memWidth: 120,
                    placeholder: fallback)
                : fallback,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nickname,
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  // 만 14세가 지나면 어린이 게시판 제한이 풀린다 — 보호자가 알아야 할 변화다.
                  c.isChild ? c.email : '${c.email} · 만 14세가 되어 일반 회원이에요',
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// 자녀의 커뮤니티 허용 스위치 (2026-11-10, Play 가족 정책).
/// 낙관적으로 바꾸고 실패하면 되돌린다. 끄면 자녀의 다음 요청부터 서버가 막는다.
class _CommunityToggle extends ConsumerStatefulWidget {
  final ChildAccount child;
  const _CommunityToggle({required this.child});

  @override
  ConsumerState<_CommunityToggle> createState() => _CommunityToggleState();
}

class _CommunityToggleState extends ConsumerState<_CommunityToggle> {
  late bool _value = widget.child.communityEnabled;
  bool _saving = false;

  Future<void> _toggle(bool v) async {
    setState(() {
      _value = v;
      _saving = true;
    });
    try {
      await ref.read(guardianRepositoryProvider).setCommunity(widget.child.id, v);
    } catch (_) {
      if (!mounted) return;
      setState(() => _value = !v);
      showToast(context, '설정을 바꾸지 못했어요. 잠시 후 다시 시도해주세요.',
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg + 40 + AppSpacing.md, 0, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('커뮤니티 사용 허용', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  _value ? '어린이 게시판에서 글을 읽고 쓸 수 있어요' : '커뮤니티를 볼 수 없어요',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(value: _value, onChanged: _saving ? null : _toggle),
        ],
      ),
    );
  }
}
