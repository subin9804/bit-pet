import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/toast_message.dart';
import '../data/models/share_models.dart';
import '../data/share_repository.dart';

/// 여러 개체를 한 번에 공유(SHARE)·입분양(TRANSFER)하는 바텀시트.
/// 성공 시 true 를 반환한다.
Future<bool?> showBulkShareSheet(
  BuildContext context, {
  required List<int> petIds,
  required ShareInviteType inviteType,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _BulkShareSheet(petIds: petIds, inviteType: inviteType),
    ),
  );
}

class _BulkShareSheet extends ConsumerStatefulWidget {
  final List<int> petIds;
  final ShareInviteType inviteType;
  const _BulkShareSheet({required this.petIds, required this.inviteType});

  @override
  ConsumerState<_BulkShareSheet> createState() => _BulkShareSheetState();
}

class _BulkShareSheetState extends ConsumerState<_BulkShareSheet> {
  final _codeController = TextEditingController();
  bool _busy = false;

  bool get _isTransfer => widget.inviteType == ShareInviteType.transfer;
  int get _count => widget.petIds.length;

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
    setState(() => _busy = true);
    try {
      await ref.read(shareRepositoryProvider).inviteBulk(
            shareCode: code,
            inviteType: widget.inviteType,
            petIds: widget.petIds,
          );
      if (!mounted) return;
      ToastMessage.show(context, '$_count마리 초대를 보냈어요');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ToastMessage.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTransfer ? '분양 보내기' : '함께 키우기';
    final accent = _isTransfer ? AppColors.error : AppColors.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.paleLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(_isTransfer ? Icons.swap_horiz : Icons.group_add,
                    color: accent, size: 22),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.h2),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_count마리',
                      style: AppTextStyles.label.copyWith(
                          color: accent, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isTransfer
                  ? '선택한 $_count마리의 소유권이 상대방에게 넘어갑니다. 나는 사육자로 남아 기록은 계속 볼 수 있어요.'
                  : '선택한 $_count마리를 상대방과 함께 관리합니다. 상대방이 사육자로 추가돼요.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '상대방 공유코드',
                hintText: '예: A1B2C3D4',
                counterText: '',
              ),
            ),
            const SizedBox(height: 4),
            Text('마이페이지에서 각자 공유코드를 확인할 수 있어요.',
                style: AppTextStyles.label),
            if (_isTransfer) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('입분양은 소유권 이전이에요. 신중히 진행해주세요.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _send,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text(_busy
                    ? '전송 중...'
                    : (_isTransfer ? '$_count마리 분양 보내기' : '$_count마리 함께 키우기')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
