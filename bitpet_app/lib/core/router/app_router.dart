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
import '../../features/routine/presentation/routine_screen.dart';
import '../../features/community/presentation/community_feed_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/my/presentation/my_screen.dart';

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
          GoRoute(path: '/records', builder: (_, __) => const RoutineScreen()),
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
