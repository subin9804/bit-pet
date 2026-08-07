import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/tag_models.dart';
import '../data/tag_repository.dart';
import '../providers/tag_provider.dart';

/// 마이페이지 > 이름표 관리 — 연결된 태그 확인·기본 동작 변경·해제.
///
/// 개체 양도 시에는 여기서 해제한 뒤 새 주인이 스캔해 재연결한다.
class MyTagsScreen extends ConsumerWidget {
  const MyTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(myTagsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('이름표 관리')),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('태그 목록을 불러오지 못했어요')),
        data: (tags) {
          if (tags.isEmpty) {
            return const EmptyState(
              icon: Icons.sell_outlined,
              message: '연결된 이름표가 없어요',
              subMessage: '이름표를 휴대폰에 갖다 대면 개체와 연결할 수 있어요.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myTagsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tags.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.paleLine),
              itemBuilder: (_, i) => _TagRow(tag: tags[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TagRow extends ConsumerWidget {
  final MyTag tag;
  const _TagRow({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('yyyy.MM.dd');
    return InkWell(
      onTap: tag.petId == null ? null : () => context.push('/pets/${tag.petId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        color: AppColors.bg2,
                        child: Text(
                          tag.tagCd,
                          style: AppTextStyles.mono(11, FontWeight.w700,
                              color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tag.petNm ?? '연결 해제됨',
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (tag.status == TagStockStatus.revoked) '사용 중지됨',
                      if (tag.chipType != null) tag.chipType!,
                      if (tag.linkedAt != null) '연결 ${fmt.format(tag.linkedAt!)}',
                    ].join(' · '),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz,
                  size: 20, color: AppColors.textSecondary),
              onPressed: () => _showMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.link_off, size: 18, color: AppColors.error),
              title: Text('연결 해제',
                  style: AppTextStyles.body.copyWith(color: AppColors.error)),
              onTap: () => Navigator.of(context).pop('unlink'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    if (action != 'unlink') return;

    final repo = ref.read(tagRepositoryProvider);
    try {
      final ok = await ConfirmModal.show(
        context,
        title: '연결 해제',
        message: '${tag.tagCd} 이름표의 연결을 해제할까요?\n'
            '태그는 그대로 두고 다른 개체에 다시 연결할 수 있어요.',
        confirmLabel: '해제',
        isDangerous: true,
      );
      if (!ok) return;
      await repo.unlink(tag.tagCd);
      if (context.mounted) {
        showToast(context, '연결을 해제했어요.', type: ToastType.success);
      }
      ref.invalidate(myTagsProvider);
    } on ApiException catch (e) {
      if (context.mounted) showToast(context, e.message, type: ToastType.error);
    }
  }
}
