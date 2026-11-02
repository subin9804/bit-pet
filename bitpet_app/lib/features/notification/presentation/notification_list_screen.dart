import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/notification_models.dart';
import '../data/notification_repository.dart';
import '../providers/notification_provider.dart';

/// 알림함.
///
/// ## 2026-11-02 정리
///
/// 전엔 라우터 파일 안의 `ListTile` 목록이었다 — 파란 벨·회색 글씨(하드코딩), 흰 AppBar,
/// 눌러도 읽음 처리만 되고 아무 데도 안 갔다. 사용자 지적: "디자인 가이드랑 안 맞고, 너무 알림만 한다".
///
/// - 다른 하위 화면과 같은 골격: 캔버스 헤더(`titleSpacing: 0`) · 흰 카드 · 토큰 색 · [EmptyState]
/// - 카드마다 **'바로가기'**(갈 곳이 있을 때만)와 **삭제(✕)**. 옆으로 밀어도 지워진다
/// - 카드를 눌러도 바로가기와 같다 — 버튼은 '눌러서 어디로 간다'는 걸 보여주는 역할
/// - ⋮ 메뉴: 모두 읽음 · 전체 삭제 · 알림 설정
///
/// 지우기·읽음은 **화면부터 바꾸고** 서버에 보낸다. 특히 밀어서 지우기는 [Dismissible] 이
/// 사라진 뒤에도 같은 키로 다시 그려지면 예외가 나서, 서버 응답을 기다릴 수 없다.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

enum _MenuAction { readAll, deleteAll, settings }

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  /// 서버 응답 전에 화면에서 먼저 뺀 알림.
  final _hidden = <int>{};

  /// 서버 응답 전에 먼저 읽음으로 보이는 알림.
  final _read = <int>{};

  bool _allRead = false;

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  /// 서버 반영 후 목록·배지를 다시 받는다. 낙관 상태는 새 목록이 오면 필요 없다.
  Future<void> _refresh() async {
    ref.invalidate(notificationListProvider);
    await ref.read(notificationListProvider.future).catchError((_) => <NotificationLog>[]);
    if (!mounted) return;
    setState(() {
      _hidden.clear();
      _read.clear();
      _allRead = false;
    });
  }

  Future<void> _delete(NotificationLog n) async {
    setState(() => _hidden.add(n.id));
    try {
      await _repo.delete(n.id);
      ref.invalidate(notificationListProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hidden.remove(n.id));
      showToast(context, '알림을 지우지 못했어요', type: ToastType.error);
    }
  }

  void _markRead(NotificationLog n) {
    if (n.isRead || _read.contains(n.id) || _allRead) return;
    setState(() => _read.add(n.id));
    // 읽음은 실패해도 알릴 일이 아니다 — 다음 새로고침에서 다시 안 읽음으로 보일 뿐이다
    _repo
        .markRead(n.id)
        .then((_) => ref.invalidate(notificationListProvider))
        .catchError((_) {});
  }

  void _open(NotificationLog n) {
    _markRead(n);
    final path = _targetPath(n);
    if (path != null) context.push(path);
  }

  Future<void> _onMenu(_MenuAction action, List<NotificationLog> visible) async {
    switch (action) {
      case _MenuAction.readAll:
        setState(() => _allRead = true);
        try {
          await _repo.markAllRead();
          ref.invalidate(notificationListProvider);
        } catch (_) {
          if (!mounted) return;
          setState(() => _allRead = false);
          showToast(context, '읽음 처리하지 못했어요', type: ToastType.error);
        }
      case _MenuAction.deleteAll:
        final ok = await ConfirmModal.show(
          context,
          title: '알림 전체 삭제',
          message: '알림 ${visible.length}개를 모두 지울까요?\n지운 알림은 되돌릴 수 없어요.',
          confirmLabel: '삭제',
          isDangerous: true,
        );
        if (!ok || !mounted) return;
        final ids = visible.map((n) => n.id).toList();
        setState(() => _hidden.addAll(ids));
        try {
          await _repo.deleteAll();
          ref.invalidate(notificationListProvider);
        } catch (_) {
          if (!mounted) return;
          setState(() => _hidden.removeAll(ids));
          showToast(context, '알림을 지우지 못했어요', type: ToastType.error);
        }
      case _MenuAction.settings:
        context.push('/my/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationListProvider);
    final visible = async.valueOrNull
            ?.where((n) => !_hidden.contains(n.id))
            .map((n) => (_allRead || _read.contains(n.id)) && !n.isRead
                ? n.copyAsRead()
                : n)
            .toList() ??
        const <NotificationLog>[];
    final hasUnread = visible.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 0,
        title: const Text('알림'),
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.ink2),
            onSelected: (a) => _onMenu(a, visible),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.readAll,
                enabled: hasUnread,
                child: const Text('모두 읽음'),
              ),
              PopupMenuItem(
                value: _MenuAction.deleteAll,
                enabled: visible.isNotEmpty,
                child: const Text('전체 삭제',
                    style: TextStyle(color: AppColors.error)),
              ),
              const PopupMenuItem(
                value: _MenuAction.settings,
                child: Text('알림 설정'),
              ),
            ],
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          tone: EmptyTone.neutral,
          message: '알림을 불러오지 못했어요',
          subMessage: '잠시 후 다시 시도해 주세요.',
          actionLabel: '다시 시도',
          onAction: _refresh,
        ),
        data: (_) {
          if (visible.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              message: '새 알림이 없어요',
              subMessage: '루틴 시간이 되거나 내 글에 댓글·좋아요가 달리면 여기에 모여요.',
            );
          }
          return RefreshIndicator(
            color: AppColors.brandAction,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                  AppSpacing.lg, AppSpacing.x40),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final n = visible[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(n),
                  background: const _DeleteBackground(),
                  child: _NotificationCard(
                    item: n,
                    hasTarget: _targetPath(n) != null,
                    onTap: () => _open(n),
                    onDelete: () => _delete(n),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 알림이 가리키는 화면. 없으면 null — 바로가기 버튼을 숨긴다.
///
/// 푸시를 눌렀을 때의 이동([PushService])과 같은 곳으로 보낸다. 댓글은 푸시엔 글 id 가
/// 없어 알림함으로 오지만, 알림함 목록은 서버가 `postId` 를 풀어 줘서 글로 갈 수 있다.
String? _targetPath(NotificationLog n) {
  switch (n.notificationType) {
    case NotificationType.ROUTINE_ALARM:
      return '/routines';
    case NotificationType.COMMUNITY_COMMENT:
    case NotificationType.COMMUNITY_LIKE:
      return n.postId != null ? '/community/${n.postId}' : null;
    case NotificationType.AI_CONSULTING:
      return n.petId != null ? '/pets/${n.petId}' : null;
    case NotificationType.SYSTEM:
      return null;
  }
}

/// 종류별 아이콘·색. 카테고리 색은 기록·커뮤니티에서 쓰는 토큰을 그대로 빌린다.
({IconData icon, Color bg, Color ink, String label}) _style(
    NotificationType type) {
  switch (type) {
    case NotificationType.ROUTINE_ALARM:
      return (
        icon: Icons.alarm,
        bg: AppColors.brandTint,
        ink: AppColors.brandTintInk,
        label: '루틴',
      );
    case NotificationType.COMMUNITY_COMMENT:
      return (
        icon: Icons.mode_comment_outlined,
        bg: AppColors.commQnaBg,
        ink: AppColors.commQnaInk,
        label: '댓글',
      );
    case NotificationType.COMMUNITY_LIKE:
      return (
        icon: Icons.favorite_border,
        bg: AppColors.commLikeBg,
        ink: AppColors.commLikeInk,
        label: '좋아요',
      );
    case NotificationType.AI_CONSULTING:
      return (
        icon: Icons.auto_awesome_outlined,
        bg: AppColors.petLilac,
        ink: AppColors.petLilacInk,
        label: '컨설팅',
      );
    case NotificationType.SYSTEM:
      return (
        icon: Icons.campaign_outlined,
        bg: AppColors.bgAlt,
        ink: AppColors.ink2,
        label: '공지',
      );
  }
}

String _ago(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays < 7) return '${d.inDays}일 전';
  final local = dt.toLocal();
  return '${local.month}월 ${local.day}일';
}

class _NotificationCard extends StatelessWidget {
  final NotificationLog item;
  final bool hasTarget;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
    required this.hasTarget,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = _style(item.notificationType);
    final unread = !item.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Ink(
          // 안 읽은 알림만 옅은 브랜드 바탕 — 점 하나로는 목록을 훑을 때 잘 안 걸린다
          decoration: AppDecor.cardRaised.copyWith(
            color: unread ? AppColors.brandTintSoft : AppColors.card,
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
                child: Icon(s.icon, size: 20, color: s.ink),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 종류 · 시간 · 안 읽음 점
                    Row(
                      children: [
                        Text(s.label,
                            style: AppTextStyles.label.copyWith(color: s.ink)),
                        Text(' · ${_ago(item.sentAt)}',
                            style: AppTextStyles.label),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.commNotifDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.title,
                      style: unread ? AppTextStyles.bodyBold : AppTextStyles.body,
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        style: AppTextStyles.caption,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasTarget) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ShortcutButton(onTap: onTap),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18, color: AppColors.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// '바로가기 >' — 브랜드색 글자 버튼. 채운 버튼으로 하면 카드마다 큰 버튼이 생겨 목록이 무거워진다.
class _ShortcutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShortcutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandAction,
        backgroundColor: AppColors.bg,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brPill,
          side: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('바로가기',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandAction,
                fontWeight: FontWeight.w600,
              )),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.brLg,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 20),
          SizedBox(width: AppSpacing.xs),
          Text('삭제',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
