import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/dashboard_tab.dart';
import '../../features/pet/presentation/pet_list_screen.dart';
import '../../features/pet/presentation/pet_detail_screen.dart';
import '../../features/pet/presentation/pet_form_screen.dart';
import '../../features/record/presentation/record_screen.dart';
import '../../features/community/presentation/community_feed_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/my/presentation/my_screen.dart';
import '../../features/notification/data/notification_repository.dart';
import '../../features/notification/data/models/notification_models.dart';
import '../../features/notification/providers/notification_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.whenOrNull(data: (u) => u != null) ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(
          child: child,
          location: state.matchedLocation,
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardTab()),
          GoRoute(path: '/pets', builder: (_, __) => const PetListScreen()),
          GoRoute(path: '/pets/new', builder: (_, __) => const PetFormScreen()),
          GoRoute(
            path: '/pets/:id',
            builder: (_, state) =>
                PetDetailScreen(petId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/pets/:id/edit',
            builder: (_, state) => PetFormScreen(
                petId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/pets/:id/records/:type',
            builder: (_, state) => RecordScreen(
              petId: int.parse(state.pathParameters['id']!),
              recordType: state.pathParameters['type']!,
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
          GoRoute(
              path: '/community',
              builder: (_, __) => const CommunityFeedScreen()),
          GoRoute(
              path: '/community/new',
              builder: (_, __) => const _PostFormPlaceholder()),
          GoRoute(
            path: '/community/:id',
            builder: (_, state) => PostDetailScreen(
                postId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/my', builder: (_, __) => const MyScreen()),
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

class _PostFormPlaceholder extends StatelessWidget {
  const _PostFormPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글 작성')),
      body: const Center(child: Text('게시글 작성 화면 (STEP 9에서 구현)')),
    );
  }
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
