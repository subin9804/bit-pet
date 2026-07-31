import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../record/presentation/fab_record_sheet.dart';
import '../../notification/providers/notification_provider.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;
  final String location;

  const HomeScreen({
    super.key,
    required this.child,
    required this.location,
  });

  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pets')) return 1;
    if (location.startsWith('/routines')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/my')) return 4;
    return 0;
  }

  // ── FAB 노출 규칙 ────────────────────────────────────────────
  // 뜨는 곳: 홈 / 내 개체 목록 / 개체 상세 / 루틴 목록 — 딱 이 넷.
  // 안 뜨는 곳: 그 외 전부. 특히 **모든 등록·수정 화면**은 아래 _isFormRoute로
  //             한 번 더 잠가서, 새 폼 라우트가 생겨도 실수로 뜨지 않게 한다.
  //             (커뮤니티는 자체 글쓰기 버튼, 기록 목록 화면은 자체 FAB이 있다)

  /// 개체 상세 `/pets/123` — 하위 경로(/edit, /records/..)는 제외
  static final _petDetailRe = RegExp(r'^/pets/(\d+)$');

  /// 등록·수정 계열 경로 — 어떤 경우에도 FAB 금지
  static bool _isFormRoute(String loc) =>
      loc.endsWith('/new') ||
      loc.endsWith('/edit') ||
      loc.endsWith('/bulk-new');

  int? get _detailPetId =>
      int.tryParse(_petDetailRe.firstMatch(location)?.group(1) ?? '');

  bool get _showFab {
    if (_isFormRoute(location)) return false;
    return location == '/home' ||
        location == '/pets' ||
        location == '/routines' ||
        _detailPetId != null;
  }

  void _onFabPressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // 개체 상세에서 열면 그 개체로 고정 — 종류만 고르면 바로 입력 폼
      builder: (_) => FabRecordSheet(initialPetId: _detailPetId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: child,
      floatingActionButton: _showFab
          ? SizedBox(
              width: 50,
              height: 50,
              child: FloatingActionButton(
                heroTag: 'fab-record',
                elevation: 0,
                tooltip: '기록 추가',
                onPressed: () => _onFabPressed(context),
                child: const Icon(Icons.add, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavBtn(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: '홈',
                  active: _currentIndex == 0,
                  badge: unreadCount > 0 && _currentIndex == 0 ? unreadCount : 0,
                  onTap: () => context.go('/home'),
                ),
                _NavBtn(
                  icon: Icons.pets,
                  activeIcon: Icons.pets,
                  label: '내 개체',
                  active: _currentIndex == 1,
                  onTap: () => context.go('/pets'),
                ),
                _NavBtn(
                  icon: Icons.schedule_outlined,
                  activeIcon: Icons.schedule,
                  label: '루틴',
                  active: _currentIndex == 2,
                  onTap: () => context.go('/routines'),
                ),
                _NavBtn(
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum,
                  label: '커뮤니티',
                  active: _currentIndex == 3,
                  onTap: () => context.go('/community'),
                ),
                _NavBtn(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: '마이',
                  active: _currentIndex == 4,
                  onTap: () => context.go('/my'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    active ? activeIcon : icon,
                    color: active ? AppColors.primary : AppColors.textDisabled,
                    size: 22,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: active ? AppColors.primary : AppColors.textDisabled,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
