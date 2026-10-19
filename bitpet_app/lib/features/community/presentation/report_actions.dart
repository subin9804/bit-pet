// 신고 / 차단 공통 액션 — 게시글·댓글 어디서든 같은 흐름으로 쓴다.
//
// 사용자에게는 두 개의 선택지로 보인다.
//   신고하기 → 사유를 고르면 접수 + 작성자 차단이 함께 생긴다 (서버가 같이 처리)
//   차단하기 → 차단만. 운영자에게 아무것도 올라가지 않는다
//
// ⛔ "차단했다"는 사실을 상대에게 알리는 화면은 만들지 말 것 — 알리는 순간
//    차단이 보복의 방아쇠가 된다. 차단 목록은 내가 차단한 사람만 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/report_models.dart';
import '../data/post_repository.dart';

/// 커뮤니티 메뉴/선택 시트. 껍데기는 [AppSheet] 한 곳에 있다 —
/// 핸들 크기·모서리 반경을 여기서 따로 정하던 동안은 같은 앱의 시트인데
/// 손잡이만 36px 로 혼자 작았다.
///
/// 제목이 있는 이유: 이 시트는 **무엇에 대한 메뉴인지**가 안 보이면
/// '신고하기'가 글을 신고하는 건지 댓글을 신고하는 건지 알 수 없다.
Future<T?> showBitpetSheet<T>(
  BuildContext context,
  Widget child, {
  required String title,
  String? subtitle,
}) {
  return showAppSheet<T>(
    context: context,
    // 본문은 전부 ListTile 목록이라 **흰 카드** 한 겹을 여기서 씌운다.
    // 호출부마다 감싸게 두면 메뉴 시트 중 하나만 카드 없이 나오는 날이 온다.
    builder: (_) => AppSheet(
      title: title,
      subtitle: subtitle,
      child: SheetCard.list(child: child),
    ),
  );
}

void _toast(BuildContext context, String message) {
  if (!context.mounted) return;
  showToast(context, message);
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
      contentPadding: EdgeInsets.zero,
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
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.block, color: AppColors.ink),
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
    // 제목·보조 줄을 AppSheet 로 올렸다. 본문 안에서 직접 그리던 동안은
    // 같은 시트인데도 제목의 크기·여백이 다른 시트들과 어긋났다.
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...reasons.map(
          (r) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(r.label, style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.ink3),
            onTap: () => Navigator.pop(context, r),
          ),
        ),
      ],
    ),
    title: '신고 사유를 선택해주세요',
    subtitle: '신고하면 작성자가 함께 차단됩니다. 신고는 취소할 수 없어요.',
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
  final ok = await ConfirmModal.show(
    context,
    title: '사용자 차단',
    message: '$nickname 님을 차단할까요?\n'
        '서로의 글과 댓글이 보이지 않게 됩니다. 차단은 마이페이지에서 해제할 수 있어요.',
    confirmLabel: '차단',
  );
  if (!ok || !context.mounted) return;

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
///
/// 구현은 `core/api/api_response.dart` 한 곳에 있다 — 화면마다 복사해두면
/// 응답 포맷이 바뀔 때 한 군데만 고쳐지고 나머지는 조용히 fallback 문구로 떨어진다.
String? _messageOf(Object e) => serverMessageOf(e);
