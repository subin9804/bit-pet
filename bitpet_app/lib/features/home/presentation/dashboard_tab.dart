// 홈 대시보드 — 모던 미니멀 (Toss/당근 스타일)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/species/breeding_terms.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/data/anniversary.dart';
import '../../pet/presentation/widgets/anniversary_view.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../record/data/models/record_models.dart';
import '../../record/data/food_catalog.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/bulk_confirm_sheet.dart';
import '../../routine/presentation/per_pet_confirm_sheet.dart';
import '../../routine/presentation/routine_postpone_sheet.dart';
import '../../../core/widgets/user_avatar.dart';
import 'widgets/home_banner.dart';

// ignore_for_file: prefer_const_constructors_in_immutables


class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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

    final todayAsync   = ref.watch(todayRoutinesProvider);
    final unread       = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          // ── 헤더 (고정) ────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: _Header(
              hasUnread: unread > 0,
              onBellTap: () => context.push('/notifications'),
              onProfileTap: () => context.push('/my'),
              profileImageUrl: authAsync.valueOrNull?.profileImageUrl,
              profileColor: authAsync.valueOrNull?.profileColor,
            ),
          ),

          // ── 본문 (스크롤) ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(todayRoutinesProvider);
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
                    const SizedBox(height: 8),

                    // ── 배너 (공지·이벤트·홍보) ──────────────────
                    // ⚠️ 내용은 아직 하드코딩이다 (`home_banner.dart`).
                    // 히어로 **위**에 두되 높이는 화면의 1/7~1/8 로 묶어,
                    // 홈을 열었을 때 '오늘 할 일'이 접히지 않게 한다.
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.lg),
                      child: HomeBanner(),
                    ),

                    // ── 오늘 할 일 ──────────────────────────────
                    //
                    // '내 개체' 가로 아바타 줄은 여기 있었는데 없앴다. 하단 탭에
                    // '내 개체'가 따로 있어서 같은 목록을 두 곳에서 보여주고 있었고,
                    // 홈의 줄은 폭이 모자라 이름이 잘려 오히려 못 알아봤다.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _TodayHero(todayAsync: todayAsync),
                    ),

                    // ── 기록 캘린더 섹션 ─────────────────────────
                    const SizedBox(height: AppSpacing.x32),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: SectionHeader(title: '기록 캘린더'),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
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
  final bool hasUnread;
  final VoidCallback onBellTap;

  /// 우상단 프로필 아바타. 하단 탭에서 '마이'를 빼고 중앙 ＋ 를 넣었으므로
  /// 설정으로 가는 유일한 입구가 여기다.
  final String? profileImageUrl;
  final String? profileColor;
  final VoidCallback onProfileTap;

  const _Header({
    required this.hasUnread,
    required this.onBellTap,
    required this.onProfileTap,
    this.profileImageUrl,
    this.profileColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.lg),
      child: Row(
        children: [
          // 'tailog'(Courier 12px) + '안녕, OO님 / 오늘의 루틴 N개' 2단이었다.
          // 인사말은 **읽을 때마다 같은 말**이라 두 번째부터는 자리만 차지하고,
          // 남은 개수는 바로 아래 히어로가 `done/total` 로 이미 말한다.
          // 헤더는 "여기가 어디냐"만 답하면 된다 — 로고 하나.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/branding/inapp_logo.png',
                // 원본 2499×720(≈3.47:1). 높이만 주고 비율은 맡긴다.
                height: 26,
                fit: BoxFit.contain,
                // 워드마크가 안 뜨면 헤더가 통째로 비어 어디인지 알 수 없게
                // 된다 — 글자로라도 남긴다.
                errorBuilder: (_, _, _) => Text('tailog',
                    style: AppTextStyles.screenTitle),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 알림 — 각진 36×36 블록이었다. 옆의 원형 아바타와 나란히 서는
          // 자리라 둘의 모양이 다르면 한 쌍으로 안 읽힌다.
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.bgAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_outlined,
                      size: AppIconSize.md, color: AppColors.ink),
                ),
                if (hasUnread)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.commNotifDot,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.canvas, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onProfileTap,
            child: UserAvatar(
              imageUrl: profileImageUrl,
              colorKey: profileColor,
              size: 36,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 오늘 할 일 히어로 ─────────────────────────────────────────
//
// 예전엔 가로로 넘기는 카드 덱(PageView)이었다. 루틴이 5개면 5번 넘겨야 전부
// 보이는데, **몇 개가 남았는지는 넘겨 보기 전엔 알 수 없었다.** 홈에서 알고 싶은
// 건 "오늘 뭐가 남았나" 하나라서, 넘기지 않고 한눈에 들어오는 세로 목록으로 바꿨다.
//
// ⛔ **시간을 표기하지 않는다.** 루틴의 날짜는 '알림이 갈 날짜'일 뿐이고 수행 시각이
// 아니다. 남은 시간·다음 루틴 시각을 띄우면 **안 지켰을 때 늦은 것처럼 보이는데**,
// 루틴은 그 날 안에 했냐 안 했냐가 전부다.
//
// 행 조작은 4개다. 현행 카드의 세 버튼(일괄 완료·개별 완료·미루기)을 하나도 없애지
// 않고 행 안으로 접어 넣은 것이다 — 버튼을 지우면 "홈에서 내용까지 적는" 쓰임이
// 사라져서 개체 상세까지 다시 들어가야 한다.
//
// | 조작 | 결과 |
// |---|---|
// | 본문 탭 | 개별 완료 시트 (개체마다 먹이·체중·메모를 적는다) |
// | '모두 완료' 알약 | 연결된 개체 전원 완료 |
// | **완료된 행 탭** | 같은 시트가 **적어둔 내용이 복원된 채** 열린다 = 수정 |
// | 길게 누르기 | 미루기 |
class _TodayHero extends StatelessWidget {
  final AsyncValue<List<TodayRoutine>> todayAsync;

  const _TodayHero({required this.todayAsync});

  /// 홈에 펼쳐 두는 행 수. 넘치는 만큼은 '더 보기'로 넘긴다.
  static const _maxRows = 3;

  @override
  Widget build(BuildContext context) {
    return todayAsync.when(
      loading: () => const _HeroShell(
        child: SizedBox(
          height: 96,
          child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandAction)),
        ),
      ),
      error: (_, __) => const _HeroShell(
        child: SizedBox(
          height: 96,
          child: Center(child: Text('루틴을 불러올 수 없어요')),
        ),
      ),
      data: (all) {
        if (all.isEmpty) return const _HeroEmpty();

        // 미완료를 위로. 끝난 일이 위에 쌓여 있으면 남은 일을 찾아 읽어야 한다.
        final routines = [...all]..sort((a, b) {
            if (a.isAllCompleted == b.isAllCompleted) return 0;
            return a.isAllCompleted ? 1 : -1;
          });

        final done = routines.where((r) => r.isAllCompleted).length;
        final total = routines.length;
        final shown = routines.take(_maxRows).toList();
        final hidden = total - shown.length;

        return _HeroShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('오늘 할 일', style: AppTextStyles.subheading),
                  const Spacer(),
                  Text('$done',
                      style: AppTextStyles.mono(15, FontWeight.w700,
                          color: AppColors.brandAction)),
                  Text(' / $total',
                      style: AppTextStyles.mono(15, FontWeight.w700,
                          color: AppColors.ink3)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 진행 바 — 의미를 전달하는 비텍스트 요소라 brandIcon(3.58:1).
              ClipRRect(
                borderRadius: AppRadius.brPill,
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandIcon),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ...shown.map((r) => _RoutineRow(routine: r)),

              if (hidden > 0)
                InkWell(
                  onTap: () => context.go('/routines'),
                  borderRadius: AppRadius.brSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$hidden개 더 보기',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandAction,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.keyboard_arrow_down,
                            size: AppIconSize.sm, color: AppColors.brandAction),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 히어로 바깥 상자. 로딩·오류·내용이 같은 모양이어야 화면이 덜컥이지 않는다.
class _HeroShell extends StatelessWidget {
  final Widget child;
  const _HeroShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.cardRaised,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
  }
}

/// 빈 상태 — 그림 1 + 한 줄 + 버튼 1개. ⛔ 버튼을 둘 두지 말 것.
class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty();

  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandTintSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt,
                size: AppIconSize.lg, color: AppColors.brandIcon),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('오늘 예정된 루틴이 없어요', style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => context.push('/routines/new'),
            child: const Text('루틴 만들기'),
          ),
        ],
      ),
    );
  }
}

// ── 루틴 행 ───────────────────────────────────────────────────
class _RoutineRow extends StatelessWidget {
  final TodayRoutine routine;

  const _RoutineRow({required this.routine});

  Color get _tint => switch (routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petClay,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  /// 본문 탭 — 개체마다 내용을 적는 시트. 완료된 행도 같은 곳으로 간다.
  /// 시트가 저장된 로그를 복원하므로 그대로 고치면 된다 (`_loadSavedLogs`).
  void _openPerPet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => PerPetConfirmSheet(routine: routine),
    );
  }

  void _openBulk(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => BulkConfirmSheet(routine: routine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone = routine.isAllCompleted;

    // 조작은 그대로 4개지만 **셋이 숨어 있었다** — 본문을 눌러야 개체별 완료가
    // 열리고, 미루기는 길게 눌러야 나왔다. 길게 누르기는 눌러 보기 전엔 있는지
    // 알 수 없는 조작이라, 쓰는 사람에겐 사실상 없는 기능이다.
    // 그래서 둘을 **보조 줄의 글자 버튼**으로 꺼냈다. 알약(모두 완료)은 그대로
    // 오른쪽에 두고, 본문 탭·길게 누르기도 아는 사람을 위해 남겼다.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openPerPet(context),
            onLongPress:
                allDone ? null : () => showRoutinePostponeSheet(context, routine),
            borderRadius: AppRadius.brMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tint,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: RecordTypeIcon(routine.routineType.name,
                        size: AppIconSize.md, color: AppColors.ink),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: allDone ? AppColors.ink3 : AppColors.ink,
                            decoration: allDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${routine.completedPetCount} / ${routine.totalPetCount}마리',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // 알약 — 전원 완료. 끝난 행에서는 누를 게 없어 표시로만 남는다.
                  if (allDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: const Icon(Icons.check,
                          size: AppIconSize.sm, color: AppColors.brandTintInk),
                    )
                  else
                    Material(
                      color: AppColors.brandAction,
                      borderRadius: AppRadius.brPill,
                      child: InkWell(
                        onTap: () => _openBulk(context),
                        borderRadius: AppRadius.brPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: Text('모두 완료',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.bg,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 보조 줄 — 아이콘 타일 폭(36+12)만큼 들여써서 제목 줄에 맞춘다.
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Row(
              children: [
                _RowAction(
                  icon: Icons.checklist_rtl,
                  // 완료된 행에서 같은 시트는 '적어둔 내용 고치기'로 열린다
                  // (`_loadSavedLogs` 가 저장된 로그를 되살린다).
                  label: allDone ? '기록 수정' : '개체별 완료',
                  onTap: () => _openPerPet(context),
                ),
                if (!allDone) ...[
                  const SizedBox(width: AppSpacing.md),
                  _RowAction(
                    icon: Icons.snooze,
                    label: '미루기',
                    onTap: () => showRoutinePostponeSheet(context, routine),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 루틴 행의 보조 동작 한 개. 아이콘 + 글자 — 아이콘만 두면 뜻이 읽히지 않는다.
class _RowAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RowAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Padding(
        // 글자만 보면 터치 영역이 12px 높이밖에 안 된다 — 세로 패딩으로
        // 손가락이 닿는 높이(약 32px)를 확보한다.
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.sm, color: AppColors.brandAction),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandAction,
                    fontWeight: FontWeight.w600)),
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
    final result = await showAppSheet<DateTime>(
      context: context,
      builder: (_) => _YearMonthPicker(
          current: _month, maxDate: DateTime(now.year, now.month)),
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

    // 기념일은 서버 캘린더 집계에 없다(그 달에 쌓인 행을 세는 것이라 매년
    // 돌아오는 날을 담을 자리가 없다). 개체 목록에 해칭일·입양일이 이미
    // 실려 오므로 여기서 월/일만 맞춰 얹는다.
    final pets = ref.watch(petListProvider).valueOrNull ?? const <Pet>[];
    final anniversaries = anniversariesInMonth(pets, _month);

    // 산란/출산 라벨 판정용. 여기는 여러 개체의 기록이 한 날에 섞이는 자리라
    // 화면에서 용어를 하나로 정할 수 없다 — 묶음에 든 개체를 보고 고른다.
    final mammalPetIds = pets
        .where((p) => p.terms.isMammal)
        .map((p) => p.id)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 바탕이 연회색([AppColors.canvas])이므로 캘린더는 **흰 카드 한 장**이다.
        // 위아래 선만 긋던 띠 모양은 바탕이 흰색이던 시절의 것으로, 지금은
        // 섹션 경계가 안 보인다.
        Container(
          decoration: AppDecor.cardRaised,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // 월 네비게이션
              Row(children: [
                IconButton(
                  tooltip: '지난 달',
                  onPressed: _prev,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left,
                      size: AppIconSize.md, color: AppColors.ink2),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickYearMonth,
                    borderRadius: AppRadius.brSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${_month.year}년 ${_month.month}월',
                              style: AppTextStyles.subheading),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.expand_more,
                              size: AppIconSize.sm, color: AppColors.ink3),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  // 다음 달은 아직 오지 않았다 — 빈 달을 열어 두면 기록이
                  // 사라진 것처럼 보인다.
                  onPressed: isCurrentMonth ? null : _next,
                  visualDensity: VisualDensity.compact,
                  icon: AppIcon(AppIcons.chevronRight,
                      size: AppIconSize.md,
                      color: isCurrentMonth ? AppColors.line : AppColors.ink2),
                ),
              ]),
              const SizedBox(height: 8),
              // 요일 헤더
              Row(
                children: _weekKo
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: d == '일'
                                      ? AppColors.error
                                      : AppColors.ink3,
                                )),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              _CalendarGrid(
                month: _month,
                days: calAsync.valueOrNull ?? const [],
                anniversaries: anniversaries,
                today: now,
                selDate: _selDate,
                onSelect: _selectDate,
              ),
            ],
          ),
        ),

        // 선택일 기록
        if (_selDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DayRecordSection(
            dateStr: _selDate!,
            weekKo: _weekKo,
            recordsAsync: dayAsync ?? const AsyncLoading(),
            anniversaries: anniversaries[_selDate!] ?? const [],
            mammalPetIds: mammalPetIds,
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
  final List<Anniversary> anniversaries;

  /// 포유류 개체의 id. 산란/출산 라벨을 고르는 데만 쓴다.
  final Set<int> mammalPetIds;

  const _DayRecordSection({
    required this.dateStr,
    required this.weekKo,
    required this.recordsAsync,
    required this.anniversaries,
    required this.mammalPetIds,
  });

  static const _catOrder = ['FEEDING', 'WEIGHT', 'CLEANING', 'MEMO', 'MATING', 'LAYING'];
  static const _catLabel = {
    'FEEDING': '급여', 'WEIGHT': '몸무게', 'CLEANING': '청소',
    'MEMO': '메모', 'MATING': '메이팅', 'LAYING': '산란',
  };

  /// 카테고리 묶음의 이름. LAYING 만 종에 따라 갈리는데, 이 줄은 **여러 개체의
  /// 기록을 묶은 것**이라 섞여 있을 수 있다 — 그럴 때는 둘을 같이 적는다.
  /// 한쪽만 적으면 묶음에 든 나머지 기록이 다른 종류로 읽힌다.
  String _label(String type, List<RecentRecord> recs) {
    if (type != 'LAYING') return _catLabel[type] ?? type;
    final mammals = recs.where((r) => mammalPetIds.contains(r.petId)).length;
    if (mammals == recs.length) return BreedingTerms.viviparous.laying;
    if (mammals == 0) return BreedingTerms.oviparous.laying;
    return '산란 · 출산';
  }

  void _openDetail(BuildContext ctx, String type, List<RecentRecord> recs) {
    showAppSheet<void>(
      context: ctx,
      builder: (_) => _CategoryDetailSheet(
        type: type,
        label: _label(type, recs),
        records: recs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(dateStr);
    final header = '${dt.month}.${dt.day} (${weekKo[dt.weekday % 7]})';
    final totalCount = recordsAsync.valueOrNull?.length ?? 0;

    // 캘린더와 같은 흰 카드 한 장 — 날짜 머리줄, 기념일, 기록이 한 상자 안에
    // 들어가야 "고른 날의 묶음"으로 읽힌다. 예전엔 셋이 각각 떠 있었다.
    return Container(
      decoration: AppDecor.cardRaised,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(header, style: AppTextStyles.subheading),
              if (recordsAsync.hasValue)
                Text('$totalCount건',
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.ink2)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 기념일 — 기록보다 위. 건수(N건)에는 세지 않는다, 기록이 아니니까.
          if (anniversaries.isNotEmpty) ...[
            for (final a in anniversaries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                // 캘린더에 뜬 기념일은 결국 '그 개체의 날'이라, 누르면 개체로
                // 간다. 여기서 끊기면 이름을 보고 다시 목록에서 찾아야 한다.
                child: AnniversaryRow(
                  anniversary: a,
                  onTap: () => context.push('/pets/${a.petId}'),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],

          recordsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (records) {
              // 기념일 줄이 이미 있으면 '기록이 없어요'를 붙이지 않는다 — 모순으로 읽힌다
              if (records.isEmpty && anniversaries.isNotEmpty) {
                return const SizedBox.shrink();
              }
              if (records.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  decoration: const BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Center(
                      child: Text('이 날의 기록이 없어요',
                          style: AppTextStyles.caption)),
                );
              }

              final grouped = <String, List<RecentRecord>>{};
              for (final r in records) {
                grouped.putIfAbsent(r.recordType, () => []).add(r);
              }
              final categories =
                  _catOrder.where((c) => grouped.containsKey(c)).toList();

              return Column(
                children: categories.map((type) {
                  final recs = grouped[type]!;
                  return _CategoryRow(
                    type: type,
                    label: _label(type, recs),
                    records: recs,
                    onTap: () => _openDetail(context, type, recs),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
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
    _ => AppColors.bgAlt,
  };

  static Color _catIconInk(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeedInk,
    'WEIGHT'   => AppColors.catWeightInk,
    'CLEANING' => AppColors.catCleanInk,
    'MEMO'     => AppColors.catMemoInk,
    'MATING'   => AppColors.catMatingInk,
    'LAYING'   => AppColors.catLayingInk,
    _ => AppColors.ink2,
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(children: [
          // 직각 타일이었다 — 카드·시트·알약이 전부 둥근 화면에서 여기만
          // 각이 서 있어 옛 테마의 잔재로 보였다. 루틴 행의 타입 타일과 같은
          // 둥글기를 쓴다.
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: AppRadius.brSm,
            ),
            child: RecordTypeIcon(type,
                size: AppIconSize.sm,
                color: _catIconInk(type),
                fallback: Icons.circle_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          // '몸무게'·'메이팅' 3글자가 줄바꿈되지 않을 만큼 확보.
          // 시스템 글자 크기를 키운 기기에서도 넘치지 않도록 배율을 반영한다.
          SizedBox(
            width: (48 * MediaQuery.textScalerOf(context).scale(1.0))
                .clamp(48.0, 76.0),
            child: Text(label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          const Spacer(),
          // 개체 칩들 — 직각
          // 개체 이름 칩 — 알약. 기록 종류색을 그대로 입어 어느 카테고리의
          // 개체인지 왼쪽 타일과 색으로 묶인다.
          ...visible.map((n) => Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: AppRadius.brPill,
              ),
              child: Text(n,
                  style: AppTextStyles.label
                      .copyWith(color: _catIconInk(type)),
                  overflow: TextOverflow.ellipsis),
            ),
          )),
          if (overflow > 0) Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.bgAlt,
                borderRadius: AppRadius.brPill,
              ),
              child: Text('+$overflow',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.ink2)),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const AppIcon(AppIcons.chevronRight,
              size: AppIconSize.sm, color: AppColors.ink3),
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

    return AppSheet(
      title: label,
      // 목록만 있는 시트다 — 고르면 바로 닫히므로 주 버튼이 없다.
      // 개체별 기록 줄이 제 면을 안 들고 있어 카드 한 겹을 씌운다.
      child: SheetCard(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarDay> days;

  /// 'YYYY-MM-DD' → 그 날의 기념일. 기록이 아니라 파생값이라 [days] 와 따로 온다.
  final Map<String, List<Anniversary>> anniversaries;
  final DateTime today;
  final String? selDate;
  final ValueChanged<String> onSelect;

  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.anniversaries,
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
          anniversaries:
              anniversaries['$ym-${d.toString().padLeft(2, '0')}'] ??
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
  final List<Anniversary> anniversaries;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _DayCell({
    required this.day,
    required this.dateStr,
    required this.categories,
    required this.anniversaries,
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
        _ => AppColors.ink3,
      };

  /// 이 날 찍을 기념일 종류 (해칭 먼저, 중복 제거)
  List<AnniversaryKind> get _annivKinds {
    final kinds = anniversaries.map((a) => a.kind).toSet().toList();
    kinds.sort((a, b) => a.index.compareTo(b.index));
    return kinds;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(dateStr),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 선택일은 `AppColors.primary`(먹색 #121A15) 정사각형이었다. 검은 블록은
          // 눌린 것보다 **꺼진 것**처럼 보이고, 테마의 유일한 강조색이 에메랄드인데
          // 그 강조가 달력에만 없었다. 선택 = 브랜드 **원**, 오늘 = 연녹 원으로
          // 두 단계를 만든다(둘 다 해당하면 선택이 이긴다 — 더 최근의 내 동작).
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.brandAction
                  : isToday
                      ? AppColors.brandTint
                      : Colors.transparent,
            ),
            child: Text(
              '$day',
              style: AppTextStyles.label.copyWith(
                color: isSelected
                    ? AppColors.bg
                    : isToday
                        ? AppColors.brandTintInk
                        : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (categories.isNotEmpty || anniversaries.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 기념일 먼저 — 같은 날 여러 마리여도 종류당 하나만 찍는다.
                // 셀이 한 줄뿐이라 마릿수까지 세면 점이 밀려 안 보인다.
                for (final kind in _annivKinds)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnniversaryMark(kind: kind, size: 9),
                  ),
                ...categories
                    .take(3 - _annivKinds.length)
                    .map((c) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _catColor(c),
                            shape: BoxShape.circle,
                          ),
                        )),
              ],
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
    return AppSheet(
      title: '연·월 선택',
      // 연도 줄과 월 그리드를 흰 카드 위에. 월 칩이 연회색(bg2)이라 바탕이
      // 같은 연회색이면 안 고른 칩들이 통째로 사라져 보인다.
      child: SheetCard(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      ),
    );
  }
}
