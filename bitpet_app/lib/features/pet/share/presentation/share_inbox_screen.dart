import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/toast_message.dart';
import '../data/models/share_models.dart';
import '../data/share_repository.dart';
import '../providers/share_provider.dart';

/// 받은 공유·입분양 초대함.
/// 여러 개체를 한 번에 받은 경우 배치 카드로 묶어 "○○님이 N마리 초대"로 표시,
/// 한 번에 수락/거절한다.
class ShareInboxScreen extends ConsumerWidget {
  const ShareInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(receivedBatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('받은 공유 초대')),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('초대를 불러올 수 없어요')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyInbox();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receivedBatchesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BatchCard(batch: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('받은 초대가 없어요', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _BatchCard extends ConsumerStatefulWidget {
  final ShareInvitationBatch batch;
  const _BatchCard({required this.batch});

  @override
  ConsumerState<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends ConsumerState<_BatchCard> {
  bool _busy = false;
  bool _expanded = false;

  Future<void> _respond({required bool accept}) async {
    setState(() => _busy = true);
    final repo = ref.read(shareRepositoryProvider);
    final batchId = widget.batch.batchId;
    try {
      if (accept) {
        await repo.acceptBatch(batchId);
      } else {
        await repo.rejectBatch(batchId);
      }
      if (!mounted) return;
      ToastMessage.show(context, accept ? '초대를 수락했어요' : '초대를 거절했어요');
      ref.invalidate(receivedBatchesProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, e.message);
      ref.invalidate(receivedBatchesProvider); // 만료 등 실패해도 갱신
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    final isTransfer = b.inviteType == ShareInviteType.transfer;
    final count = b.petCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(isTransfer: isTransfer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${b.inviterName}님',
                  style: AppTextStyles.h3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTransfer
                ? '${b.inviterName}님이 $count마리를 입분양하려 해요. 수락하면 내가 소유자가 됩니다.'
                : '${b.inviterName}님이 $count마리를 함께 관리하자고 초대했어요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 10),

          // 개체 목록 (기본 접힘, 3마리 이하는 전체 표시)
          _PetChips(
            pets: b.pets,
            expanded: _expanded || count <= 3,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),

          if (b.expiresAt != null) ...[
            const SizedBox(height: 8),
            Text('만료: ${_fmtDate(b.expiresAt!)}',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textDisabled)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _respond(accept: false),
                  child: Text(count > 1 ? '전체 거절' : '거절'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _respond(accept: true),
                  child: Text(_busy
                      ? '처리 중...'
                      : (count > 1 ? '전체 수락' : '수락')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 배치에 포함된 개체 이름 칩 목록
class _PetChips extends StatelessWidget {
  final List<BatchPetItem> pets;
  final bool expanded;
  final VoidCallback onToggle;

  const _PetChips({
    required this.pets,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? pets : pets.take(3).toList();
    final hidden = pets.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(p.petName, style: AppTextStyles.label),
            )),
        if (pets.length > 3)
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                expanded ? '접기' : '+$hidden마리',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isTransfer;
  const _TypeBadge({required this.isTransfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      color: isTransfer ? AppColors.primary : AppColors.bg2,
      child: Text(
        isTransfer ? '입분양' : '공유',
        style: AppTextStyles.label.copyWith(
          color: isTransfer ? Colors.white : AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

String _fmtDate(DateTime dt) {
  final d = dt.toLocal();
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
