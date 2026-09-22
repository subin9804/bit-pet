// 홈 대시보드 — 모던 미니멀 (Toss/당근 스타일)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../record/data/models/record_models.dart';
import '../../record/data/food_catalog.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/bulk_confirm_sheet.dart';
import '../../routine/presentation/per_pet_confirm_sheet.dart';
import '../../routine/presentation/routine_postpone_sheet.dart';
import '../../../core/widgets/app_network_image.dart';

// ignore_for_file: prefer_const_constructors_in_immutables


class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with WidgetsBindingObserver {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // 백그라운드에서 복귀 시 날짜가 바뀌었으면 오늘 루틴 재로드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayRoutinesProvider.notifier).reloadIfStale();
    }
  }


  @override
  Widget build(BuildContext context) {
    final authAsync    = ref.watch(authStateProvider);
    final userName     = authAsync.valueOrNull?.name ?? '사용자';

    final todayAsync   = ref.watch(todayRoutinesProvider);
    final recentAsync  = ref.watch(recentRecordsProvider);
    final unread       = ref.watch(unreadNotificationCountProvider);
    final petsAsync    = ref.watch(petListProvider);

    final allRoutines  = todayAsync.valueOrNull ?? [];
    final remaining    = allRoutines.where((r) => !r.isAllCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── 헤더 (고정) ────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: _Header(
              userName: userName,
              remainingCount: remaining,
              hasUnread: unread > 0,
              onBellTap: () => context.push('/notifications'),
            ),
          ),

          // ── 본문 (스크롤) ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(todayRoutinesProvider);
                ref.invalidate(recentRecordsProvider);
                // 당겨서 새로고침인데 캘린더만 옛 값으로 남아 있으면 새로고침이
                // 안 먹은 것처럼 보인다
                ref.invalidate(homeCalendarProvider);
                ref.invalidate(homeDayRecordsProvider);
                ref.read(petListProvider.notifier).load();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── TODAY 섹션 ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Text('TODAY',
                              style: AppTextStyles.mono(11, FontWeight.w700,
                                  color: AppColors.textDisabled)),
                          const Spacer(),
                          todayAsync.whenOrNull(data: (r) => Text(
                            '${r.length - remaining} / ${r.length}',
                            style: AppTextStyles.mono(11, FontWeight.w700,
                                color: AppColors.textDisabled),
                          )) ?? const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    _TodayDeck(
                      todayAsync: todayAsync,
                      currentPage: _currentPage,
                      pageController: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                    ),

                    // ── 내 개체 섹션 ──────────────────────────────
                    _SectionHeader(
                      title: '내 개체',
                      trailing: '전체보기',
                      onTap: () => context.go('/pets'),
                    ),
                    SizedBox(
                      height: 96,
                      child: petsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) =>
                            const Center(child: Text('개체 로드 실패')),
                        data: (pets) => ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          children: [
                            _AddPetButton(onTap: () => context.push('/pets/new')),
                            ...pets.map((p) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: _PetAvatarItem(
                                    pet: p,
                                    onTap: () => context.push('/pets/${p.id}'),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                    // ── 기록 캘린더 섹션 ─────────────────────────
                    _SectionHeader(title: '기록 캘린더'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _HomeCalendar(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  final int remainingCount;
  final bool hasUnread;
  final VoidCallback onBellTap;

  const _Header({
    required this.userName,
    required this.remainingCount,
    required this.hasUnread,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tailog',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: '안녕, $userName님\n'),
                      TextSpan(
                        text: '오늘의 루틴 $remainingCount개',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 알림 버튼 — 직각 컨테이너
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  color: AppColors.bg2,
                  child: const Icon(Icons.notifications_none_outlined,
                      size: 20, color: AppColors.textPrimary),
                ),
                if (hasUnread)
                  Positioned(
                    right: 7, top: 7,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE05C3A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TODAY 덱 ──────────────────────────────────────────────────

/// 루틴 카드 기준 높이. PageView 는 자식 높이를 스스로 못 정하므로 고정값이 필요하다.
const _kCardHeight = 200.0;

/// 카드 높이. 기본은 [_kCardHeight] 이고, **넘칠 때만** 그만큼 키운다.
///
/// 카드 전체를 배율만큼 곱하면 안 된다 — 아이콘 40px·패딩·간격은 배율과
/// 무관해서, 늘어난 몫이 전부 아래쪽 빈 공간으로 남는다. 그래서 고정 요소와
/// 배율을 타는 요소를 나눠 더한다.
///
/// 실측(배율 1.0 기준): 고정 92(세로 패딩 32 + 간격 32 + 버튼 패딩·테두리 18
/// + 아이콘이 텍스트보다 큰 몫 10) + 배율을 타는 텍스트 84 = 176.
///
/// ℹ️ 이 카드의 오버플로는 **세로가 아니라 가로**였다. 아래 액션 버튼 두 개의
/// 라벨이 `Flexible` 없이 놓여 있어서, 좁은 화면이나 큰 글자에서 flex 칸을
/// 넘겼다. 높이 추정은 멀쩡했으므로 여기선 여유만 조금 더 준다.
double _cardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  final content = 92 + 84 * scale.clamp(1.0, 2.5);
  return content <= _kCardHeight ? _kCardHeight : content + 12;
}

class _TodayDeck extends StatelessWidget {
  final AsyncValue<List<TodayRoutine>> todayAsync;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _TodayDeck({
    required this.todayAsync,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = _cardHeight(context);
    return todayAsync.when(
      loading: () => SizedBox(
        height: cardHeight,
        child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => SizedBox(
        height: cardHeight,
        child: const Center(child: Text('루틴을 불러올 수 없어요')),
      ),
      data: (allRoutines) {
        final routines = [...allRoutines]..sort((a, b) {
          if (a.isAllCompleted == b.isAllCompleted) return 0;
          return a.isAllCompleted ? 1 : -1;
        });
        if (routines.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            // 카드가 있을 자리를 대신하는 상자다. 카드는 둥근데 빈 자리만
            // 각지면 '아직 안 그려진 것'처럼 보인다.
            decoration: const BoxDecoration(
              color: AppColors.bg2,
              borderRadius: AppRadius.brLg,
            ),
            child: const Center(
              child: Text('오늘 예정된 루틴이 없어요',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: routines.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                      left: i == 0 ? 20 : 0,
                      right: 8),
                  child: _TodayRoutineCard(
                    routine: routines[i],
                    index: i,
                    total: routines.length,
                  ),
                ),
              ),
            ),
            if (routines.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(routines.length, (i) {
                    final active = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 18 : 5,
                      height: 4,
                      // 4px 짜리 점이라 알약이 곧 형태다. 각지면 눈금으로 읽힌다.
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.divider,
                        borderRadius: AppRadius.brPill,
                      ),
                    );
                  }),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── TODAY 루틴 카드 ───────────────────────────────────────────
class _TodayRoutineCard extends StatelessWidget {
  final TodayRoutine routine;
  final int index;
  final int total;

  const _TodayRoutineCard({
    required this.routine,
    required this.index,
    required this.total,
  });

  Color get _bg => switch (routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  String get _typeLabel => switch (routine.routineType) {
        RoutineType.FEEDING  => 'FEEDING',
        RoutineType.CLEANING => 'CLEANING',
        RoutineType.WEIGHT   => 'WEIGHT',
        RoutineType.CUSTOM   => 'CUSTOM',
      };

  void _openBulk(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => BulkConfirmSheet(routine: routine),
    );
  }

  void _openPerPet(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => PerPetConfirmSheet(routine: routine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone   = routine.isAllCompleted;
    final done      = routine.completedPetCount;
    final totalPets = routine.totalPetCount;

    return Opacity(
      opacity: allDone ? 0.60 : 1.0,
      child: Container(
        // 홈에서 가로로 넘겨 보는 카드다. 한 장씩 떠 있다는 게 형태로
        // 읽혀야 넘길 수 있는 물건인 줄 안다 — 라운드와 옅은 그림자가 그 역할이다.
        // 바탕색이 루틴 종류마다 달라서 AppDecor.cardRaised 를 그대로 못 쓴다.
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: AppRadius.brLg,
          boxShadow: AppShadows.elev1,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시각 + 인덱스
            Row(
              children: [
                Text(
                  routine.alarmTime ?? '--:--',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(
                    '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                    style: AppTextStyles.mono(10, FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 아이콘 + 제목 + 마리수
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: RecordTypeIcon(routine.routineType.name,
                      size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel,
                          style: AppTextStyles.mono(9, FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 1),
                      Text(
                        routine.title,
                        style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, letterSpacing: -0.4,
                          decoration: allDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.textSecondary,
                        ),
                        // maxLines 없이 ellipsis만 주면 줄바꿈은 그대로 일어난다.
                        // 카드 높이가 고정(_kCardHeight)이라 긴 제목이 두 줄이 되는 순간
                        // 바닥이 넘쳤다 — 한 줄로 못박는다.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.textPrimary),
                      const SizedBox(width: 4),
                      Text('$totalPets마리',
                          style: AppTextStyles.mono(10, FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 진행도
            Row(
              children: [
                const Spacer(),
                Text('$done / $totalPets 완료',
                    style: AppTextStyles.mono(11, FontWeight.w700,
                        color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),

            // 액션 버튼 — border-radius 0
            //
            // 미루기는 원래 카드 맨 위 오른쪽에 10sp 알약으로 있었다. 바로 옆 '01/02'
            // 인덱스 배지와 크기·색·서체가 똑같아서 **버튼이 아니라 표시로 읽혔고**,
            // 기능이 있는 줄 모른 채 지나쳤다. 실제 동작이니 실제 버튼 자리로 내린다.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: allDone ? null : () => _openBulk(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.brMd,
                        color: allDone ? Colors.transparent : AppColors.primary,
                        // 완료 상태에만 테두리를 주면 그 카드만 2px 더 높아져
                        // 완료된 카드부터 바닥이 넘친다. 두께는 항상 1px로 두고 색만 바꾼다.
                        border: Border.all(
                          color: allDone
                              ? AppColors.textSecondary
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!allDone) ...[
                            const Icon(Icons.check,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          // 두 버튼이 한 줄을 flex 3:3 으로 나눠 쓰는 자리다.
                          // Flexible 없이 두면 좁은 화면이나 큰 글자에서 라벨이
                          // 칸을 넘어 카드가 가로로 터진다 — 이게 '루틴 카드
                          // overflowed' 의 실제 원인이었다.
                          Flexible(
                            child: Text(
                              allDone ? '완료됨' : '일괄 완료',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: allDone
                                    ? AppColors.textSecondary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _openPerPet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.brMd,
                        color: Colors.white.withValues(alpha: 0.65),
                        // 왼쪽 버튼과 높이를 맞추기 위한 투명 테두리
                        border: Border.all(color: Colors.transparent, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_list_outlined,
                              size: 16, color: AppColors.textPrimary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('개별 완료',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 미루기 — 루틴 단위라 연결된 개체 전부가 밀린다 (시트에서 고지).
                // 완료된 카드에는 미룰 게 없어 자리 자체를 없앤다.
                if (!allDone) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => showRoutinePostponeSheet(context, routine),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.brMd,
                          color: Colors.white.withValues(alpha: 0.65),
                          // 나머지 두 버튼과 높이를 맞추기 위한 투명 테두리
                          border: Border.all(color: Colors.transparent, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.snooze,
                                size: 16, color: AppColors.textPrimary),
                            const SizedBox(width: 4),
                            const Text('미루기',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ── 섹션 헤더 ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.3)),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: Text(trailing!,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDisabled)),
            ),
        ],
      ),
    );
  }
}

// ── 내 개체 아바타 ─────────────────────────────────────────────
class _PetAvatarItem extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetAvatarItem({required this.pet, required this.onTap});

  Widget get _placeholderIcon => AppIcon(
        AppIcons.species(pet.speciesSubcategory),
        size: 24,
        color: AppColors.primary.withValues(alpha: 0.4),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: AppColors.bgAlt,
                borderRadius: AppRadius.brLg,
              ),
              // 사진이 없는 개체의 자리지킴 아이콘이다. 먹색(textPrimary)이면
              // 사진 있는 개체보다 오히려 더 튀어서 목록이 얼룩덜룩해진다.
              // '내 개체' 탭 아바타와 같은 옅기로 맞춘다.
              child: pet.profileImageUrl != null
                  ? AppNetworkImage(
                      pet.profileImageUrl,
                      fit: BoxFit.cover,
                      memWidth: 220,
                      placeholder: _placeholderIcon,
                    )
                  : _placeholderIcon,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 개체 추가 버튼 ──────────────────────────────────────────────
class _AddPetButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 24, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '추가',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 홈 기록 캘린더 ──────────────────────────────────────────────
class _HomeCalendar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends ConsumerState<_HomeCalendar> {
  late DateTime _month;
  String? _selDate;

  static const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _selDate = todayStr;
  }

  String get _yearMonth =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  void _prev() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _selDate = null;
      });

  void _next() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        _month = next;
        _selDate = null;
      });
    }
  }

  Future<void> _pickYearMonth() async {
    final now = DateTime.now();
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _YearMonthPicker(current: _month, maxDate: DateTime(now.year, now.month)),
    );
    if (result != null) {
      setState(() {
        _month = result;
        _selDate = null;
      });
    }
  }

  void _selectDate(String date) {
    if (_selDate == date) {
      setState(() => _selDate = null);
      return;
    }
    setState(() => _selDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(homeCalendarProvider(_yearMonth));
    // ⚠️ 여기는 예전에 위젯 안의 Map 캐시였다. 기록·루틴을 저장해도 그 Map 에는
    // 아무도 손을 못 대서, 탭을 떠났다 돌아와(=State 가 새로 만들어져야) 값이 바뀌었다.
    // provider 를 watch 하면 invalidatePetRecords 의 무효화가 그대로 화면에 온다.
    final dayAsync =
        _selDate != null ? ref.watch(homeDayRecordsProvider(_selDate!)) : null;
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 캘린더 컨테이너 — 테두리 없이 구분선으로만
        Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: AppColors.divider),
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              // 월 네비게이션
              Row(children: [
                GestureDetector(
                  onTap: _prev,
                  child: const Icon(Icons.chevron_left,
                      size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickYearMonth,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_month.year}년 ${_month.month}월',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, size: 16, color: AppColors.textDisabled),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: isCurrentMonth ? null : _next,
                  child: AppIcon(AppIcons.chevronRight,
                      size: 20,
                      color: isCurrentMonth
                          ? AppColors.divider
                          : AppColors.textSecondary),
                ),
              ]),
              const SizedBox(height: 8),
              // 요일 헤더
              Row(
                children: _weekKo
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: d == '일'
                                      ? AppColors.error.withValues(alpha: 0.5)
                                      : AppColors.textDisabled,
                                )),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              _CalendarGrid(
                month: _month,
                days: calAsync.valueOrNull ?? const [],
                today: now,
                selDate: _selDate,
                onSelect: _selectDate,
              ),
            ],
          ),
        ),

        // 선택일 기록
        if (_selDate != null) ...[
          const SizedBox(height: 12),
          _DayRecordSection(
            dateStr: _selDate!,
            weekKo: _weekKo,
            recordsAsync: dayAsync ?? const AsyncLoading(),
          ),
        ],
      ],
    );
  }
}

// ── 날짜별 기록 섹션 ────────────────────────────────────────────
class _DayRecordSection extends StatelessWidget {
  final String dateStr;
  final List<String> weekKo;
  final AsyncValue<List<RecentRecord>> recordsAsync;

  const _DayRecordSection({
    required this.dateStr,
    required this.weekKo,
    required this.recordsAsync,
  });

  static const _catOrder = ['FEEDING', 'WEIGHT', 'CLEANING', 'MEMO', 'MATING', 'LAYING'];
  static const _catLabel = {
    'FEEDING': '급여', 'WEIGHT': '몸무게', 'CLEANING': '청소',
    'MEMO': '메모', 'MATING': '메이팅', 'LAYING': '산란',
  };

  void _openDetail(BuildContext ctx, String type, List<RecentRecord> recs) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryDetailSheet(
        type: type,
        label: _catLabel[type] ?? type,
        records: recs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(dateStr);
    final header = '${dt.month}.${dt.day} (${weekKo[dt.weekday % 7]})';
    final totalCount = recordsAsync.valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(header,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, letterSpacing: -0.2)),
              if (recordsAsync.hasValue)
                Text('$totalCount건',
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        recordsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (records) {
            if (records.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.bg2,
                child: const Center(
                  child: Text('이 날의 기록이 없어요',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColors.textDisabled)),
                ),
              );
            }

            final grouped = <String, List<RecentRecord>>{};
            for (final r in records) {
              grouped.putIfAbsent(r.recordType, () => []).add(r);
            }
            final categories = _catOrder.where((c) => grouped.containsKey(c)).toList();

            // 리스트 아이템 + 구분선 구조
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                children: categories.map((type) {
                  final recs = grouped[type]!;
                  return _CategoryRow(
                    type: type,
                    label: _catLabel[type] ?? type,
                    records: recs,
                    onTap: () => _openDetail(context, type, recs),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── 카테고리 행 ──────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String type;
  final String label;
  final List<RecentRecord> records;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.type,
    required this.label,
    required this.records,
    required this.onTap,
  });

  static Color _catBg(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeed,
    'WEIGHT'   => AppColors.catWeight,
    'CLEANING' => AppColors.catClean,
    'MEMO'     => AppColors.catMemo,
    'MATING'   => AppColors.catMating,
    'LAYING'   => AppColors.catLaying,
    _ => AppColors.bg2,
  };

  static Color _catIconInk(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeedInk,
    'WEIGHT'   => AppColors.catWeightInk,
    'CLEANING' => AppColors.catCleanInk,
    'MEMO'     => AppColors.catMemoInk,
    'MATING'   => AppColors.catMatingInk,
    'LAYING'   => AppColors.catLayingInk,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final names = records.map((r) => r.petName).toList();
    const showMax = 2;
    final overflow = names.length > showMax ? names.length - showMax : 0;
    final visible = names.take(showMax).toList();
    final chipBg = _catBg(type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          // 카테고리 아이콘 — 직각 컨테이너
          Container(
            width: 28, height: 28,
            color: chipBg,
            child: RecordTypeIcon(type,
                size: 13,
                color: _catIconInk(type),
                fallback: Icons.circle_outlined),
          ),
          const SizedBox(width: 8),
          // '몸무게'·'메이팅' 3글자가 줄바꿈되지 않을 만큼 확보.
          // 시스템 글자 크기를 키운 기기에서도 넘치지 않도록 배율을 반영한다.
          SizedBox(
            width: (48 * MediaQuery.textScalerOf(context).scale(1.0))
                .clamp(48.0, 76.0),
            child: Text(label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
          const Spacer(),
          // 개체 칩들 — 직각
          ...visible.map((n) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: chipBg,
              child: Text(n,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _catIconInk(type)),
                  overflow: TextOverflow.ellipsis),
            ),
          )),
          if (overflow > 0) Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.bg2,
              child: Text('+$overflow',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 4),
          const AppIcon(AppIcons.chevronRight, size: 16, color: AppColors.textDisabled),
        ]),
      ),
    );
  }
}

// ── 카테고리 상세 바텀시트 ─────────────────────────────────────
// 바텀시트는 border-radius 유지
class _CategoryDetailSheet extends StatelessWidget {
  final String type;
  final String label;
  final List<RecentRecord> records;

  const _CategoryDetailSheet({
    required this.type,
    required this.label,
    required this.records,
  });

  static String _translateFeedingSummary(String raw) {
    if (raw.isEmpty) return raw;
    final parts = raw.split(' ');
    parts[0] = FoodType.labelForCode(parts[0]);
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<RecentRecord>> petGroups = {};
    for (final r in records) {
      final key = r.petId?.toString() ?? r.petName;
      petGroups.putIfAbsent(key, () => []).add(r);
    }
    final petKeys = petGroups.keys.toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.divider,
            ),
          ),
          Text(label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: petKeys.length,
              itemBuilder: (_, i) {
                final key      = petKeys[i];
                final petRecs  = petGroups[key]!;
                final first    = petRecs.first;
                final petId    = int.tryParse(key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            // 개체색이던 점. 이 시트는 한 카테고리의 기록만 모아
                            // 보여주므로, 점이 나를 수 있는 정보는 '무슨 기록이냐'다.
                            color: _CategoryRow._catIconInk(type),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: petId == null ? null : () {
                                Navigator.of(context).pop();
                                context.push('/pets/$petId');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(first.petName,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  if (petId != null) ...[
                                    const SizedBox(width: 4),
                                    const AppIcon(AppIcons.chevronRight,
                                        size: 16, color: AppColors.textDisabled),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...petRecs.map((r) {
                              final hasMemo = r.memo != null && r.memo!.isNotEmpty;
                              final rawSummary = r.recordType == 'FEEDING'
                                  ? _translateFeedingSummary(r.summary)
                                  : r.summary;
                              final display = [
                                if (rawSummary.isNotEmpty) rawSummary,
                                if (hasMemo) r.memo!,
                              ].join('  ·  ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  display,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarDay> days;
  final DateTime today;
  final String? selDate;
  final ValueChanged<String> onSelect;

  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.today,
    required this.selDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final recordMap = {for (final d in days) d.date: d.categories};

    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final ym = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final cells = <Widget>[
      for (int i = 0; i < startOffset; i++) const SizedBox(),
      for (int d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          dateStr: '$ym-${d.toString().padLeft(2, '0')}',
          categories: recordMap[
                  '$ym-${d.toString().padLeft(2, '0')}'] ??
              const [],
          isToday: d == today.day &&
              month.year == today.year &&
              month.month == today.month,
          isSelected: selDate ==
              '$ym-${d.toString().padLeft(2, '0')}',
          onTap: onSelect,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.88,
      mainAxisSpacing: 2,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String dateStr;
  final List<String> categories;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _DayCell({
    required this.day,
    required this.dateStr,
    required this.categories,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  static Color _catColor(String cat) => switch (cat) {
        'FEEDING'  => AppColors.catFeedInk,
        'WEIGHT'   => AppColors.catWeightInk,
        'CLEANING' => AppColors.catCleanInk,
        'MEMO'     => AppColors.catMemoInk,
        'MATING'   => AppColors.catMatingInk,
        'LAYING'   => AppColors.catLayingInk,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(dateStr),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            color: isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.bg2
                    : Colors.transparent,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (categories.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.take(3).map((c) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _catColor(c),
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 년/월 피커 바텀시트 (바텀시트 — border-radius 유지) ──────────
class _YearMonthPicker extends StatefulWidget {
  final DateTime current;
  final DateTime maxDate;

  const _YearMonthPicker({required this.current, required this.maxDate});

  @override
  State<_YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<_YearMonthPicker> {
  late int _year;
  late int _month;

  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _month = widget.current.month;
  }

  bool _isDisabled(int m) =>
      _year > widget.maxDate.year ||
      (_year == widget.maxDate.year && m > widget.maxDate.month);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.divider,
            ),
          ),
          // 연도 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _year--),
                child: const Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 32),
              Text('$_year년',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _year < widget.maxDate.year ? () => setState(() => _year++) : null,
                child: AppIcon(AppIcons.chevronRight,
                    size: 24,
                    color: _year < widget.maxDate.year ? AppColors.textSecondary : AppColors.divider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 월 그리드 (4x3) — 직각 버튼
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: List.generate(12, (i) {
              final m = i + 1;
              final disabled = _isDisabled(m);
              final selected = m == _month && _year == widget.current.year;
              return GestureDetector(
                onTap: disabled ? null : () => Navigator.of(context).pop(DateTime(_year, m)),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brMd,
                    color: selected ? AppColors.primary : AppColors.bg2,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _monthNames[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? AppColors.textDisabled
                          : selected
                              ? Colors.white
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
