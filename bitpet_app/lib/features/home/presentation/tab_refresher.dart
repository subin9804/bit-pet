import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../community/providers/post_provider.dart';
import '../../home/data/home_banner_repository.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../routine/providers/routine_provider.dart';

/// 하단 탭 번호. 중앙 ＋ 는 화면이 아니라 동작이라 2번이 비어 있다. 탭이 아니면 -1.
int tabIndexOf(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/pets')) return 1;
  if (location.startsWith('/routines')) return 3;
  if (location.startsWith('/community')) return 4;
  return -1;
}

const _tabRoots = {'/home': 0, '/pets': 1, '/routines': 3, '/community': 4};

/// 탭을 옮기거나 앱이 돌아오면 그 탭의 목록을 **뒤에서 조용히** 다시 받는다 (2026-11-26).
///
/// 목록 provider 들은 한 번 받은 값을 앱이 꺼질 때까지 들고 있어서, 다른 화면에서 바뀐 것
/// (차단·해제, 공유받은 개체, 남이 단 댓글 알림 …)이 당겨서 새로고침하기 전엔 안 보였다.
///
/// - 보던 값은 그대로 두고 응답이 오면 갈아끼운다 — 스켈레톤이 깜빡이지 않는다.
///   ⛔ 여기서 `load()` 처럼 상태를 loading 으로 비우는 걸 부르지 말 것
/// - **탭 루트(/home·/pets·/routines·/community)에 다른 탭에서 들어왔을 때만** 돈다.
///   글 상세에서 목록으로 돌아올 때 돌면 피드가 첫 20개로 줄어 보던 자리를 잃는다
/// - 앱 복귀 때는 지금 탭 루트에 있을 때만 그 탭을, 알림은 항상 갱신한다
class TabRefresher extends ConsumerStatefulWidget {
  final String location;
  final Widget child;

  const TabRefresher({super.key, required this.location, required this.child});

  @override
  ConsumerState<TabRefresher> createState() => _TabRefresherState();
}

class _TabRefresherState extends ConsumerState<TabRefresher> {
  late final AppLifecycleListener _lifecycle;

  /// 마지막으로 머문 탭 루트. 처음 열린 탭은 방금 받았으니 다시 받지 않는다.
  int? _lastRoot;

  @override
  void initState() {
    super.initState();
    _lastRoot = _tabRoots[widget.location];
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TabRefresher old) {
    super.didUpdateWidget(old);
    final root = _tabRoots[widget.location];
    if (root == null || root == _lastRoot) return;
    _lastRoot = root;
    // 빌드 중이라 provider 를 바로 건드리지 않는다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshTab(root);
    });
  }

  void _onResume() {
    ref.invalidate(notificationListProvider);
    final root = _tabRoots[widget.location];
    if (root != null) _refreshTab(root);
  }

  void _refreshTab(int tab) {
    switch (tab) {
      case 0:
        ref.read(todayRoutinesProvider.notifier).refresh();
        ref.invalidate(homeBannersProvider);
        ref.invalidate(homeCalendarProvider);
        ref.invalidate(homeDayRecordsProvider);
        ref.invalidate(notificationListProvider);
        ref.read(petListProvider.notifier).refresh();
      case 1:
        ref.read(petListProvider.notifier).refresh();
        ref.invalidate(myLayingsProvider);
      case 3:
        ref.read(routineListProvider.notifier).refresh();
        ref.invalidate(routineTodayStatusProvider);
      case 4:
        // 커뮤니티가 잠긴 자녀 계정이면 피드를 만들지 않는다 — 만들면 403 요청이 나간다
        final allowed =
            ref.read(authStateProvider).valueOrNull?.communityAllowed ?? true;
        if (allowed) ref.read(feedProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
