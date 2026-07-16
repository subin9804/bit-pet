import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/confirm_modal.dart';
import '../../../../core/widgets/toast_message.dart';
import '../data/models/share_models.dart';
import '../data/share_repository.dart';
import '../providers/share_provider.dart';

/// 개체별 공유 관리 (소유자 전용).
/// - 공유코드로 사육자 초대 / 입분양
/// - 대기중 초대 취소
/// - 현재 사육자 목록 / 공유 해제
class PetShareScreen extends ConsumerWidget {
  final int petId;
  const PetShareScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keepersAsync = ref.watch(petKeepersProvider(petId));
    final sentAsync = ref.watch(petSentInvitationsProvider(petId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('공유 관리')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(petKeepersProvider(petId));
          ref.invalidate(petSentInvitationsProvider(petId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InviteBox(petId: petId),
            const SizedBox(height: 28),

            // 현재 사육자
            Text('현재 사육자', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            keepersAsync.when(
              loading: () => const _LoadingRow(),
              error: (_, __) => Text('사육자 목록을 불러올 수 없어요',
                  style: AppTextStyles.caption),
              data: (keepers) => Column(
                children: keepers
                    .map((k) => _KeeperRow(petId: petId, keeper: k))
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),

            // 대기중 초대
            Text('대기중 초대', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            sentAsync.when(
              loading: () => const _LoadingRow(),
              error: (_, __) =>
                  Text('초대 목록을 불러올 수 없어요', style: AppTextStyles.caption),
              data: (sent) => sent.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('대기중인 초대가 없어요',
                          style: AppTextStyles.caption),
                    )
                  : Column(
                      children: sent
                          .map((inv) =>
                              _SentInvitationRow(petId: petId, invitation: inv))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 초대 입력 박스 ──────────────────────────────────────────────

class _InviteBox extends ConsumerStatefulWidget {
  final int petId;
  const _InviteBox({required this.petId});

  @override
  ConsumerState<_InviteBox> createState() => _InviteBoxState();
}

class _InviteBoxState extends ConsumerState<_InviteBox> {
  final _codeController = TextEditingController();
  ShareInviteType _type = ShareInviteType.share;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ToastMessage.show(context, '상대방의 공유코드를 입력해주세요');
      return;
    }
    if (_type == ShareInviteType.transfer) {
      final ok = await ConfirmModal.show(
        context,
        title: '입분양 확인',
        message: '입분양하면 소유권이 상대방에게 넘어가고, 나는 사육자로 남습니다. 계속할까요?',
        confirmLabel: '입분양',
        isDangerous: true,
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(shareRepositoryProvider).invite(
            widget.petId,
            shareCode: code,
            inviteType: _type,
          );
      if (!mounted) return;
      _codeController.clear();
      ToastMessage.show(context, '초대를 보냈어요');
      ref.invalidate(petSentInvitationsProvider(widget.petId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('사육자 초대', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('상대방의 공유코드를 입력하세요. 마이페이지에서 각자 코드를 확인할 수 있어요.',
              style: AppTextStyles.caption),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: const InputDecoration(
              hintText: '공유코드 (예: A1B2C3D4)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TypeChoice(
                  label: '공유',
                  desc: '함께 관리',
                  selected: _type == ShareInviteType.share,
                  onTap: () => setState(() => _type = ShareInviteType.share),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChoice(
                  label: '입분양',
                  desc: '소유권 이전',
                  selected: _type == ShareInviteType.transfer,
                  onTap: () => setState(() => _type = ShareInviteType.transfer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _send,
              child: Text(_busy ? '전송 중...' : '초대 보내기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChoice extends StatelessWidget {
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChoice({
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.bg,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.paleLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text(desc, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

// ── 사육자 행 ──────────────────────────────────────────────────

class _KeeperRow extends ConsumerWidget {
  final int petId;
  final Keeper keeper;
  const _KeeperRow({required this.petId, required this.keeper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.bg2,
            child: Icon(Icons.person, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(keeper.name, style: AppTextStyles.body),
                Text(keeper.role.label,
                    style: AppTextStyles.label.copyWith(
                      color: keeper.role.isOwner
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          if (!keeper.role.isOwner)
            TextButton(
              onPressed: () async {
                final ok = await ConfirmModal.show(
                  context,
                  title: '공유 해제',
                  message: '${keeper.name}님을 이 개체 사육자에서 내보낼까요?',
                  confirmLabel: '내보내기',
                  isDangerous: true,
                );
                if (ok != true) return;
                try {
                  await ref
                      .read(shareRepositoryProvider)
                      .revokeKeeper(petId, keeper.userId);
                  ref.invalidate(petKeepersProvider(petId));
                  if (context.mounted) ToastMessage.show(context, '공유를 해제했어요');
                } on ApiException catch (e) {
                  if (context.mounted) ToastMessage.show(context, e.message);
                }
              },
              child: const Text('내보내기',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}

// ── 보낸(대기중) 초대 행 ────────────────────────────────────────

class _SentInvitationRow extends ConsumerWidget {
  final int petId;
  final ShareInvitation invitation;
  const _SentInvitationRow({required this.petId, required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.inviteeName, style: AppTextStyles.body),
                Text(
                  '${invitation.inviteType.label} · ${invitation.status.label}',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(shareRepositoryProvider)
                    .cancel(invitation.id);
                ref.invalidate(petSentInvitationsProvider(petId));
                if (context.mounted) ToastMessage.show(context, '초대를 취소했어요');
              } on ApiException catch (e) {
                if (context.mounted) ToastMessage.show(context, e.message);
              }
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
