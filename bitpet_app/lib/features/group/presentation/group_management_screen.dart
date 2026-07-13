import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/group_models.dart';
import '../providers/group_provider.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState
    extends ConsumerState<GroupManagementScreen> {

  Future<void> _editName(GroupInfo group) async {
    final ctrl = TextEditingController(text: group.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(),
        title: const Text('그룹 이름 수정',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(hintText: '그룹 이름'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('저장')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != group.name) {
      try {
        await ref.read(groupActionProvider.notifier).updateName(result);
        if (mounted) ToastMessage.show(context, '이름이 변경되었어요', type: ToastType.success);
      } catch (e) {
        if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    }
  }

  Future<void> _kickMember(GroupMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('멤버 강제 탈퇴'),
        content: Text('"${member.name}"을 그룹에서 내보낼까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('내보내기')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(groupActionProvider.notifier).kick(member.userId);
        if (mounted) ToastMessage.show(context, '멤버를 내보냈어요', type: ToastType.success);
      } catch (e) {
        if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    }
  }

  Future<void> _leaveOrDisband(GroupInfo group) async {
    final isOwner = group.isOwner;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isOwner ? '그룹 해산' : '그룹 탈퇴'),
        content: Text(isOwner
            ? '"${group.name}"을 해산하면 모든 멤버가 탈퇴하고 되돌릴 수 없어요.'
            : '"${group.name}"에서 탈퇴할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(isOwner ? '해산' : '탈퇴')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(groupActionProvider.notifier).leaveOrDisband();
        if (mounted) context.go('/groups/setup');
      } catch (e) {
        if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupActionProvider);

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      appBar: AppBar(
        backgroundColor: AppColors.paleBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('그룹 관리',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18,
                color: AppColors.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (group) {
          if (group == null) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.go('/groups/setup'));
            return const SizedBox.shrink();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── 그룹 정보 카드 ─────────────────────────────────
              _InfoCard(group: group, onEditName: () => _editName(group)),

              const SizedBox(height: 16),

              // ── 초대코드 카드 ──────────────────────────────────
              _InviteCodeCard(group: group),

              const SizedBox(height: 16),

              // ── 멤버 목록 ──────────────────────────────────────
              _MembersCard(
                group: group,
                onKick: group.isOwner ? _kickMember : null,
              ),

              const SizedBox(height: 32),

              // ── 탈퇴/해산 버튼 ─────────────────────────────────
              GestureDetector(
                onTap: () => _leaveOrDisband(group),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    group.isOwner ? '그룹 해산' : '그룹 탈퇴',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 그룹 정보 카드 ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final GroupInfo group;
  final VoidCallback onEditName;

  const _InfoCard({required this.group, required this.onEditName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('그룹 정보',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.paleInk3, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.paleBgAlt,
                ),
                child: const Icon(Icons.group_outlined,
                    size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary,
                        )),
                    Text('${group.members.length}명 · ${group.myRole.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.paleInk2,
                        )),
                  ],
                ),
              ),
              if (group.isOwner)
                GestureDetector(
                  onTap: onEditName,
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.paleInk2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 초대코드 카드 ──────────────────────────────────────────────────
// OWNER가 누를 때마다 5분간 유효한 임시 코드를 발급한다 (DB 미저장, Redis TTL).

class _InviteCodeCard extends ConsumerStatefulWidget {
  final GroupInfo group;

  const _InviteCodeCard({required this.group});

  @override
  ConsumerState<_InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends ConsumerState<_InviteCodeCard> {
  String? _code;
  int? _remainingSeconds;
  Timer? _timer;
  bool _loading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _issue() async {
    setState(() => _loading = true);
    try {
      final result =
          await ref.read(groupActionProvider.notifier).issueInviteCode();
      _timer?.cancel();
      setState(() {
        _code = result.code;
        _remainingSeconds = result.expiresInSeconds;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        final remaining = (_remainingSeconds ?? 0) - 1;
        if (remaining <= 0) {
          t.cancel();
          setState(() {
            _code = null;
            _remainingSeconds = null;
          });
        } else {
          setState(() => _remainingSeconds = remaining);
        }
      });
    } catch (e) {
      if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _mmss {
    final s = _remainingSeconds ?? 0;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.group.isOwner;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('초대코드',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.paleInk3, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          if (!isOwner)
            const Text('그룹장만 초대코드를 발급할 수 있어요.',
                style: TextStyle(fontSize: 12.5, color: AppColors.paleInk2))
          else if (_code == null)
            GestureDetector(
              onTap: _loading ? null : _issue,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('초대코드 발급 (5분간 유효)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        )),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _code!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 6,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _code!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('초대코드가 복사되었어요')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.paleBgAlt,
                          border: Border.all(color: AppColors.paleLine),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_outlined,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 5),
                            Text('복사',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('남은 시간 $_mmss · 만료되면 자동으로 사라져요',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.paleInk3)),
              ],
            ),
          const SizedBox(height: 6),
          const Text('발급된 코드를 직접 전달하면 5분 안에 그룹에 참여할 수 있어요.',
              style: TextStyle(fontSize: 11.5, color: AppColors.paleInk3)),
        ],
      ),
    );
  }
}

// ── 멤버 목록 카드 ─────────────────────────────────────────────────

class _MembersCard extends StatelessWidget {
  final GroupInfo group;
  final void Function(GroupMember)? onKick;

  const _MembersCard({required this.group, this.onKick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text('멤버',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.paleInk3, letterSpacing: 0.3)),
                const SizedBox(width: 6),
                Text('${group.members.length}명',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paleInk3,
                    )),
              ],
            ),
          ),
          ...group.members.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isLast = i == group.members.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(
                        top: BorderSide(color: AppColors.paleLineSoft))
                    : const Border(
                        top: BorderSide(color: AppColors.paleLineSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // 아바타
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.paleBgAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                )),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.isOwner
                                    ? AppColors.primary
                                    : AppColors.paleBgAlt,
                              ),
                              child: Text(
                                m.role.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: m.isOwner
                                      ? AppColors.paleBg
                                      : AppColors.paleInk2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 강제탈퇴 (OWNER만, 자신 제외)
                  if (onKick != null && !m.isOwner)
                    GestureDetector(
                      onTap: () => onKick!(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                        ),
                        child: const Text('내보내기',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            )),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
