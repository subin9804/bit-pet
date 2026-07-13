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
    if (location.startsWith('/routines')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/my')) return 3;
    return 0;
  }

  void _openFabSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FabRecordSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: child,
      // FAB는 BottomAppBar 안에 인라인으로 임베드 (디자인 기준: marginTop -20)
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 8,
        padding: EdgeInsets.zero,
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
                  icon: Icons.schedule_outlined,
                  activeIcon: Icons.schedule,
                  label: '루틴',
                  active: _currentIndex == 1,
                  onTap: () => context.go('/routines'),
                ),
                // 중앙 FAB — nav bar 안에 임베드, 14px 위로 돌출
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -14),
                      child: GestureDetector(
                        onTap: () => _openFabSheet(context),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2E3A332B),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _NavBtn(
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum,
                  label: '커뮤니티',
                  active: _currentIndex == 2,
                  onTap: () => context.go('/community'),
                ),
                _NavBtn(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: '마이',
                  active: _currentIndex == 3,
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
        borderRadius: BorderRadius.circular(8),
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
