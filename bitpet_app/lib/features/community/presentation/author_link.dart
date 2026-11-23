import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

/// 작성자 닉네임·아바타를 누르면 그 사람 프로필(`/users/:id`)로 간다 (2026-11-23).
///
/// **내 닉네임은 눌리지 않는다** — 사용자 결정. 내 글·댓글은 마이페이지에서 본다.
/// 피드 카드처럼 바깥 전체가 눌리는 자리에서도 이 영역만 따로 잡히게 [HitTestBehavior.opaque].
class AuthorLink extends ConsumerWidget {
  final int userId;
  final Widget child;
  const AuthorLink({super.key, required this.userId, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    if (myId == userId) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/users/$userId'),
      child: child,
    );
  }
}
