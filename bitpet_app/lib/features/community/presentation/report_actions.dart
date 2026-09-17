// 신고 / 차단 공통 액션 — 게시글·댓글 어디서든 같은 흐름으로 쓴다.
//
// 사용자에게는 두 개의 선택지로 보인다.
//   신고하기 → 사유를 고르면 접수 + 작성자 차단이 함께 생긴다 (서버가 같이 처리)
//   차단하기 → 차단만. 운영자에게 아무것도 올라가지 않는다
//
// ⛔ "차단했다"는 사실을 상대에게 알리는 화면은 만들지 말 것 — 알리는 순간
//    차단이 보복의 방아쇠가 된다. 차단 목록은 내가 차단한 사람만 보여준다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/report_models.dart';
import '../data/post_repository.dart';

/// 바텀시트 공통 껍데기 (손잡이 + 라운드 상단)
Future<T?> showBitpetSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.paleLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _toast(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

/// 남의 글/댓글 메뉴에 붙는 두 줄. 신고·차단이 **따로** 보이는 것이 핵심이다.
List<Widget> reportBlockTiles({
  required BuildContext context,
  required WidgetRef ref,
  required ReportTargetType targetType,
  required int targetId,
  required int authorUserId,
  required String authorName,
  /// 신고·차단이 성공해 목록/상세를 다시 불러와야 할 때
  required VoidCallback onDone,
}) {
  final what = targetType == ReportTargetType.comment ? '댓글' : '게시글';
  return [
    ListTile(
      leading: const Icon(Icons.flag_outlined, color: AppColors.commHot),
      title: Text('$what 신고하기',
          style: TextStyle(color: AppColors.commHot)),
      subtitle: Text('운영자에게 접수되고 $authorName 님이 차단됩니다',
          style: AppTextStyles.monoXs),
      onTap: () async {
        Navigator.pop(context);
        await showReportSheet(
          context: context,
          ref: ref,
          targetType: targetType,
          targetId: targetId,
          onDone: onDone,
        );
      },
    ),
    ListTile(
      leading: const Icon(Icons.block, color: AppColors.primary),
      title: const Text('차단하기'),
      subtitle: Text('$authorName 님의 글과 댓글이 보이지 않습니다',
          style: AppTextStyles.monoXs),
      onTap: () async {
        Navigator.pop(context);
        await confirmBlock(
          context: context,
          ref: ref,
          userId: authorUserId,
          nickname: authorName,
          onDone: onDone,
        );
      },
    ),
  ];
}

/// 신고 사유 선택 시트. 사유 목록은 서버에서 받는다(앱에 박아두지 않는다).
Future<void> showReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ReportTargetType targetType,
  required int targetId,
  required VoidCallback onDone,
}) async {
  final repo = ref.read(postRepositoryProvider);
  List<ReportReason> reasons;
  try {
    reasons = await repo.getReportReasons();
  } catch (_) {
    _toast(context, '신고 사유를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
    return;
  }
  if (!context.mounted) return;

  final reason = await showBitpetSheet<ReportReason>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text('신고 사유를 선택해주세요',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('신고하면 작성자가 함께 차단됩니다. 신고는 취소할 수 없어요.',
              style: AppTextStyles.monoXs),
        ),
        ...reasons.map(
          (r) => ListTile(
            title: Text(r.label, style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.paleInk3),
            onTap: () => Navigator.pop(context, r),
          ),
        ),
      ],
    ),
  );
  if (reason == null || !context.mounted) return;

  try {
    await repo.report(
        targetType: targetType, targetId: targetId, reasonCd: reason.code);
    _toast(context, '신고가 접수되었어요. 작성자도 차단했습니다.');
    onDone();
  } catch (e) {
    // 중복 신고(409) 같은 서버 메시지를 그대로 보여주는 편이 친절하다
    _toast(context, _messageOf(e) ?? '신고에 실패했어요. 잠시 후 다시 시도해주세요.');
  }
}

/// 차단 확인 다이얼로그 → 차단
Future<void> confirmBlock({
  required BuildContext context,
  required WidgetRef ref,
  required int userId,
  required String nickname,
  required VoidCallback onDone,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('사용자 차단'),
      content: Text('$nickname 님을 차단할까요?\n'
          '서로의 글과 댓글이 보이지 않게 됩니다. 차단은 마이페이지에서 해제할 수 있어요.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('차단')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await ref.read(postRepositoryProvider).blockUser(userId);
    _toast(context, '$nickname 님을 차단했어요.');
    onDone();
  } catch (e) {
    _toast(context, _messageOf(e) ?? '차단에 실패했어요. 잠시 후 다시 시도해주세요.');
  }
}

/// 서버가 내려준 사람 읽을 문구를 꺼낸다.
/// 중복 신고(409)·자기 글 신고(400) 같은 건 서버 메시지가 그대로 가장 정확하다.
String? _messageOf(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) return error['message'] as String?;
    }
  }
  return null;
}
