import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
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
  // 뜨는 곳: 홈 / 개체 상세 — 딱 이 둘.
  // 내 개체 목록·루틴 목록은 뺐다: 그 화면의 + 는 '개체/루틴 추가'로 읽혀서
  //   기록 시트가 열리면 헷갈린다 (2026-09-15 실사용 피드백).
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
    return location == '/home' || _detailPetId != null;
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
                // elevation 은 테마(6)를 그대로 받는다. FAB 는 앱에서 유일하게
                // 내용 위에 상시로 떠 있는 것이라 그림자가 곧 '누를 수 있음'의 신호다.
                tooltip: '기록 추가',
                onPressed: () => _onFabPressed(context),
                child: const Icon(Icons.add, size: 24),
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
            // 58 = 세로 패딩 12 + 아이콘 20 + 간격 2 + 라벨 한 줄(약 12).
            // 56 이던 시절엔 내용물 합이 55 라 여유가 1px 뿐이었고, 시스템 글자
            // 크기를 한 단계만 올려도 바가 터졌다. 배율 상한은 아래 _NavBtn 에서 건다.
            height: 58,
            child: Row(
              children: [
                _NavBtn(
                  icon: AppIcons.homeLine,
                  activeIcon: AppIcons.homeFill,
                  label: '홈',
                  active: _currentIndex == 0,
                  badge: unreadCount > 0 && _currentIndex == 0 ? unreadCount : 0,
                  onTap: () => context.go('/home'),
                ),
                _NavBtn(
                  icon: AppIcons.petLine,
                  activeIcon: AppIcons.petFill,
                  label: '내 개체',
                  active: _currentIndex == 1,
                  onTap: () => context.go('/pets'),
                ),
                _NavBtn(
                  icon: AppIcons.routineLine,
                  activeIcon: AppIcons.routineFill,
                  label: '루틴',
                  active: _currentIndex == 2,
                  onTap: () => context.go('/routines'),
                ),
                _NavBtn(
                  icon: AppIcons.communityLine,
                  activeIcon: AppIcons.communityFill,
                  label: '커뮤니티',
                  active: _currentIndex == 3,
                  onTap: () => context.go('/community'),
                ),
                _NavBtn(
                  icon: AppIcons.myLine,
                  activeIcon: AppIcons.myFill,
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
  /// 비활성 상태의 선 아이콘 (`AppIcons` 의 SVG 경로)
  final String icon;
  /// 활성 상태의 채움 아이콘
  final String activeIcon;
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
                  AppIcon(
                    active ? activeIcon : icon,
                    color: active ? AppColors.primary : AppColors.textDisabled,
                    size: 20,
                    semanticLabel: label,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // 탭 바는 높이가 고정된 자리라 시스템 글자 배율을 그대로 받으면
                // 무조건 넘친다. 라벨은 아이콘의 보조 설명이므로 여기서만 상한을
                // 건다 — 본문은 접근성 설정을 그대로 따른다.
                textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.15),
                ),
                style: AppTextStyles.label.copyWith(
                  color: active ? AppColors.primary : AppColors.textDisabled,
                  fontSize: 11,
                  height: 1.1,
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
