import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
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

  /// 탭 활성 판정. 중앙 ＋ 는 화면이 아니라 **동작**이라 번호를 갖지 않는다 —
  /// 그래서 2번이 비어 있고 루틴이 3, 커뮤니티가 4다.
  ///
  /// `/my` 는 더 이상 탭이 아니다 (홈 우상단 아바타로 들어간다). 설정 화면에
  /// 있을 때 어떤 탭도 켜지지 않는 건 의도한 것이다 — 없는 탭을 억지로
  /// 활성시키면 "마이가 홈인가?" 하게 된다.
  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pets')) return 1;
    if (location.startsWith('/routines')) return 3;
    if (location.startsWith('/community')) return 4;
    return -1;
  }

  // ── 떠 있는 FAB 을 없애고 내비 중앙으로 내렸다 ─────────────────
  //
  // 예전엔 홈과 개체 상세에만 FAB 이 떴다. 그래서 **다른 화면에서 기록을 남기려면
  // 일단 홈으로 나가야 했고**, 반대로 FAB 을 다른 화면까지 넓히면 그 화면의 ＋ 와
  // 뜻이 겹쳤다 (목록의 ＋ 는 '개체 추가'로 읽힌다 — 2026-09-15 피드백).
  //
  // 내비 중앙은 그 둘을 다 피한다. 항상 같은 자리에 있고, 각 화면의 생성 버튼은
  // 상단 우측에 따로 있어서 뜻이 섞이지 않는다.
  //
  // ⛔ **중앙 ＋ 는 기록 전용이다.** 개체 추가·루틴 추가·글쓰기를 여기에 끼워
  //    넣지 말 것. 하나 끼우는 순간 "뭘 하는지 눌러봐야 아는" 버튼이 된다.

  /// 개체 상세 `/pets/123` — 하위 경로(/edit, /records/..)는 제외
  static final _petDetailRe = RegExp(r'^/pets/(\d+)$');

  /// 개체 상세에서 눌렀으면 그 개체로 미리 채운다. 다른 화면이면 null 이고
  /// 시트가 개체 선택부터 띄운다.
  int? get _detailPetId =>
      int.tryParse(_petDetailRe.firstMatch(location)?.group(1) ?? '');

  void _onRecordPressed(BuildContext context) {
    showAppSheet<void>(
      context: context,
      enableDrag: false, // 개별 입력은 한꺼번에 저장 — 시트가 확인을 받는다
      // 개체 상세에서 열면 그 개체로 고정 — 종류만 고르면 바로 입력 폼
      builder: (_) => FabRecordSheet(initialPetId: _detailPetId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: child,
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
                _NavRecordBtn(onTap: () => _onRecordPressed(context)),
                _NavBtn(
                  icon: AppIcons.routineLine,
                  activeIcon: AppIcons.routineFill,
                  label: '루틴',
                  active: _currentIndex == 3,
                  onTap: () => context.go('/routines'),
                ),
                _NavBtn(
                  icon: AppIcons.communityLine,
                  activeIcon: AppIcons.communityFill,
                  label: '커뮤니티',
                  active: _currentIndex == 4,
                  onTap: () => context.go('/community'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 내비 중앙의 기록 버튼.
///
/// 다른 칸과 달리 **라벨이 없다.** 58px 바에 44px 타일을 넣으면 글자가 들어갈
/// 자리가 없고, 글자를 넣겠다고 타일을 줄이면 앱에서 제일 많이 눌리는 버튼이
/// 제일 작아진다. 대신 **앱에서 유일하게 면이 채워진 칸**이라 글자 없이도 구분된다.
///
/// 색은 [AppColors.brandAction] 하나로 고정이다. ⛔ 기록 종류(급여·체중)에 따라
/// 색을 바꾸지 말 것 — 누르기 전에는 어떤 기록이 될지 모르는 버튼이다.
class _NavRecordBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _NavRecordBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: '기록 추가',
          child: Material(
            color: AppColors.brandAction,
            borderRadius: AppRadius.brMd,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brMd,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add, size: 26, color: AppColors.bg),
              ),
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
                  fontSize: 12,
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
