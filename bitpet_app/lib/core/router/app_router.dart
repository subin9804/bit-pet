import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/password_reset/password_reset_request_screen.dart';
import '../../features/auth/presentation/password_reset/password_reset_verify_screen.dart';
import '../../features/auth/presentation/password_reset/password_reset_confirm_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/dashboard_tab.dart';
import '../../features/pet/presentation/pet_list_screen.dart';
import '../../features/pet/presentation/pet_detail_screen.dart';
import '../../features/pet/presentation/pet_form_screen.dart';
import '../../features/pet/presentation/pet_bulk_form_screen.dart';
import '../../features/pet/presentation/public_pet_screen.dart';
import '../../features/pet/presentation/user_profile_screen.dart';
import '../../features/record/presentation/record_screen.dart';
import '../../features/record/presentation/record_detail_screen.dart';
import '../../features/community/presentation/community_feed_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/community/presentation/post_compose_screen.dart';
import '../../features/routine/presentation/routines_page.dart';
import '../../features/routine/presentation/routine_form_screen.dart';
import '../../features/pet/share/presentation/pet_share_screen.dart';
import '../../features/pet/share/presentation/share_inbox_screen.dart';
import '../../features/pet/share/presentation/share_hub_screen.dart';
import '../../features/my/presentation/my_screen.dart';
import '../../features/notification/data/notification_repository.dart';
import '../../features/notification/data/models/notification_models.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../../features/record/presentation/weight_screen.dart';
import '../../features/record/presentation/feed_detail_screen.dart';
import '../../features/nfc/presentation/tag_resolver_screen.dart';
import '../../features/nfc/presentation/my_tags_screen.dart';
import '../../features/nfc/providers/tag_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.whenOrNull(data: (u) => u != null) ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/signup' ||
          loc.startsWith('/password-reset');

      // NFC 태그를 찍었는데 로그아웃 상태면, 로그인 후 그 태그로 돌아갈 수 있게 기억해 둔다
      if (!isLoggedIn && loc.startsWith('/t/')) {
        PendingTagLink.remember(state.uri.toString());
        return '/login';
      }
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return PendingTagLink.take() ?? '/home';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      // NFC 태그 이름표 딥링크 — https://tailog.me/t/{tagCd}
      // 앱은 NFC를 직접 읽지 않는다. OS가 URL을 열어주고 이 경유 화면이 서버에 물어본 뒤
      // status에 따라 개체 상세 / 연결 모달 / 안내로 분기한다.
      GoRoute(
        path: '/t/:tagCd',
        builder: (_, state) =>
            TagResolverScreen(tagCd: state.pathParameters['tagCd']!),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/password-reset/request',
        builder: (_, __) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: '/password-reset/verify',
        builder: (_, __) => const PasswordResetVerifyScreen(),
      ),
      GoRoute(
        path: '/password-reset/confirm',
        builder: (_, __) => const PasswordResetConfirmScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(
          child: child,
          // ⚠️ matchedLocation 을 쓰면 안 된다. ShellRoute 안에서 context.push 를 하면
          //    ShellRouteMatch 는 copyWith 로 재사용되면서 **처음 매칭된 위치를 그대로 유지**한다.
          //    (/pets 에서 /pets/12 로 push 해도 matchedLocation 은 계속 '/pets')
          //    uri 는 push 된 위치로 갱신되므로 uri.path 를 봐야 실제 현재 화면을 알 수 있다.
          location: state.uri.path,
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardTab()),
          GoRoute(path: '/pets', builder: (_, __) => const PetListScreen()),
          GoRoute(path: '/pets/new', builder: (_, __) => const PetFormScreen()),
          GoRoute(path: '/pets/bulk-new', builder: (_, __) => const PetBulkFormScreen()),
          GoRoute(
            path: '/pets/:id',
            // ?openRecord=feed|scale — NFC 태그 스캔 시 기록 바텀시트를 자동으로 연다
            builder: (_, state) => PetDetailScreen(
              petId: int.parse(state.pathParameters['id']!),
              openRecordType: state.uri.queryParameters['openRecord'],
            ),
          ),
          // 남의 공개 개체 / 공개 프로필 — 가계도 부모 카드에서만 들어온다.
          // 사육 기록이 없는 화면이라 /pets/:id 와 별도 라우트로 둔다.
          GoRoute(
            path: '/pets/:id/public',
            builder: (_, state) =>
                PublicPetScreen(petId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/users/:userId',
            builder: (_, state) => UserProfileScreen(
                userId: int.parse(state.pathParameters['userId']!)),
          ),
          GoRoute(
            path: '/pets/:id/edit',
            builder: (_, state) => PetFormScreen(
                petId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/pets/:id/records/:type',
            builder: (_, state) {
              final petId = int.parse(state.pathParameters['id']!);
              final type = state.pathParameters['type']!;
              return switch (type) {
                'cleaning' || 'memo' || 'mating' || 'laying' =>
                    RecordDetailScreen(petId: petId, recordType: type),
                _ => RecordScreen(petId: petId, recordType: type),
              };
            },
          ),
          // 05 몸무게 추이 화면
          GoRoute(
            path: '/pets/:id/weight',
            builder: (_, state) => WeightScreen(
              petId: int.parse(state.pathParameters['id']!),
            ),
          ),
          // 05b 급여 기록 상세 화면
          GoRoute(
            path: '/pets/:id/feeding',
            builder: (_, state) => FeedDetailScreen(
              petId: int.parse(state.pathParameters['id']!),
            ),
          ),
          // /records → /pets로 리다이렉트 (루틴은 내 개체 관리 탭에서 관리)
          GoRoute(
            path: '/records',
            redirect: (_, __) => '/pets',
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const _NotificationScreen(),
          ),
          GoRoute(path: '/routines', builder: (_, __) => const RoutinesPage()),
          GoRoute(path: '/routines/new', builder: (_, __) => const RoutineFormScreen()),
          GoRoute(
              path: '/community',
              builder: (_, __) => const CommunityFeedScreen()),
          GoRoute(
              path: '/community/new',
              builder: (_, __) => const PostComposeScreen()),
          GoRoute(
            path: '/community/:id',
            builder: (_, state) => PostDetailScreen(
                postId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/community/:id/edit',
            builder: (_, state) => PostComposeScreen(
                postId: int.tryParse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/my', builder: (_, __) => const MyScreen()),
          // 마이페이지 > 이름표 관리
          GoRoute(path: '/my/tags', builder: (_, __) => const MyTagsScreen()),
          // 공유 허브 (공유코드·받은 초대·시작 안내)
          GoRoute(path: '/share', builder: (_, __) => const ShareHubScreen()),
          // 받은 공유·입분양 초대함
          GoRoute(path: '/share/inbox', builder: (_, __) => const ShareInboxScreen()),
          // 개체별 공유 관리 (소유자)
          GoRoute(
            path: '/pets/:id/share',
            builder: (_, state) =>
                PetShareScreen(petId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
});

// GoRouter refresh — authState 변경 시 redirect 재실행
class _AuthListenable implements Listenable {
  final List<VoidCallback> _listeners = [];

  _AuthListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => _notify());
  }

  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}


// 알림 목록 화면
class _NotificationScreen extends ConsumerWidget {
  const _NotificationScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('알림을 불러올 수 없어요')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('알림이 없어요'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                leading: Icon(
                  n.isRead ? Icons.notifications_none : Icons.notifications,
                  color: n.isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: Text(
                  _ago(n.sentAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onTap: () {
                  ref.read(notificationRepositoryProvider).markRead(n.id);
                  ref.invalidate(notificationListProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }
}
