import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/push/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
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
/// - 카드를 누르면 **읽음 처리만** 한다. 카드마다 **삭제(✕)**, 옆으로 밀어도 지워진다
/// - ⋮ 메뉴: 모두 읽음 · 전체 삭제(확인 모달 없음) · 알림 설정
///
/// 2026-11-03: '바로가기' 버튼·카드 탭 이동은 뺐다(사용자: "그냥 읽음처리나 삭제처리만").
/// 서버 응답의 `postId` 는 남아 있다 — 다시 이동을 붙일 때 쓴다.
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

  /// ✕ 로 지워서 접히는 중인 알림. 다 접히면 [_hidden] 으로 옮긴다.
  final _collapsing = <int>{};

  /// 서버 응답 전에 먼저 읽음으로 보이는 알림.
  final _read = <int>{};

  bool _allRead = false;

  @override
  void initState() {
    super.initState();
    // 알림함을 열었으면 폰 알림창의 푸시도 확인한 것 — 런처 아이콘 숫자가 남지 않게 걷는다
    ref.read(pushServiceProvider).clearTray();
  }

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

  /// [animate] — ✕ 버튼은 카드가 접히며 사라진다. 밀어서 지우기는 [Dismissible] 이
  /// 이미 접어 줬으므로 바로 뺀다 (2026-11-19: ✕ 는 툭 사라지고 아래가 튀어 올라 어색했다).
  Future<void> _delete(NotificationLog n, {bool animate = false}) async {
    setState(() => animate ? _collapsing.add(n.id) : _hidden.add(n.id));
    try {
      await _repo.delete(n.id);
      ref.invalidate(notificationListProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _collapsing.remove(n.id);
        _hidden.remove(n.id);
      });
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
        // 확인 모달 없이 바로 지운다 — 알림은 지워도 아쉬울 게 없다(2026-11-03 사용자 요청)
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
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                  AppSpacing.lg, AppSpacing.x40),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final n = visible[i];
                final collapsing = _collapsing.contains(n.id);
                // 카드 사이 간격은 칸 안에 넣는다 — 바깥 구분자로 두면 카드가 접힌 뒤
                // 간격 8 이 한 번 더 툭 줄어든다.
                return _Collapse(
                  key: ValueKey(n.id),
                  collapsing: collapsing,
                  // 접힘이 끝나는 프레임에 삭제 실패가 겹치면 위젯 쪽 값은 아직 '접는 중'이다 —
                  // 화면 상태(_collapsing)로 다시 확인해야 되살린 카드를 또 숨기지 않는다
                  onCollapsed: () {
                    if (!_collapsing.contains(n.id)) return;
                    setState(() {
                      _collapsing.remove(n.id);
                      _hidden.add(n.id);
                    });
                  },
                  child: Dismissible(
                    key: ValueKey('d${n.id}'),
                    direction: collapsing
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    onDismissed: (_) => _delete(n),
                    background: const _DeleteBackground(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _NotificationCard(
                        item: n,
                        onTap: () => _markRead(n),
                        onDelete: collapsing
                            ? () {}
                            : () => _delete(n, animate: true),
                      ),
                    ),
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
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

/// ✕ 로 지운 카드를 접으며 흐리게 — 밀어서 지울 때와 같은 '접히는' 움직임.
class _Collapse extends StatefulWidget {
  final bool collapsing;
  final VoidCallback onCollapsed;
  final Widget child;
  const _Collapse({
    super.key,
    required this.collapsing,
    required this.onCollapsed,
    required this.child,
  });

  @override
  State<_Collapse> createState() => _CollapseState();
}

class _CollapseState extends State<_Collapse>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void didUpdateWidget(_Collapse old) {
    super.didUpdateWidget(old);
    if (widget.collapsing && !old.collapsing) {
      _c.reverse().whenCompleteOrCancel(() {
        if (mounted && widget.collapsing) widget.onCollapsed();
      });
    } else if (!widget.collapsing && old.collapsing) {
      _c.forward(); // 삭제 실패 — 다시 펼친다
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: _curve,
        child: FadeTransition(opacity: _curve, child: widget.child),
      );
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
