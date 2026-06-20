// 01 · 홈 대시보드 — PALE 디자인 (handoff 반영)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../record/data/record_repository.dart';
import '../../record/data/models/record_models.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/bulk_confirm_sheet.dart';
import '../../routine/presentation/per_pet_confirm_sheet.dart';
import '../../group/providers/group_provider.dart';

// ignore_for_file: prefer_const_constructors_in_immutables


class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  final _pageController = PageController(viewportFraction: 0.86);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authAsync    = ref.watch(authStateProvider);
    final userName     = authAsync.valueOrNull?.name ?? '사용자';

    // 그룹이 없으면 설정 화면으로 이동
    ref.listen(myGroupProvider, (_, next) {
      next.whenData((group) {
        if (group == null) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.go('/groups/setup'));
        }
      });
    });

    final todayAsync   = ref.watch(todayRoutinesProvider);
    final petsAsync    = ref.watch(petListProvider);
    final recentAsync  = ref.watch(recentRecordsProvider);
    final unread       = ref.watch(unreadNotificationCountProvider);

    final allRoutines  = todayAsync.valueOrNull ?? [];
    final remaining    = allRoutines.where((r) => !r.isAllCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: Column(
        children: [
          // ── 헤더 (고정, 스크롤 안됨) ──────────────────────────
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
              onRefresh: () async {
                ref.invalidate(todayRoutinesProvider);
                ref.invalidate(recentRecordsProvider);
                ref.read(petListProvider.notifier).load();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),

                    // ── TODAY 섹션 ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                      child: Row(
                        children: [
                          Text('TODAY',
                              style: AppTextStyles.mono(11, FontWeight.w700,
                                  color: AppColors.paleInk2)),
                          const Spacer(),
                          todayAsync.whenOrNull(data: (r) => Text(
                            '${r.length - remaining} / ${r.length}',
                            style: AppTextStyles.mono(11, FontWeight.w700,
                                color: AppColors.paleInk3),
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

                    // ── 내 개체 섹션 ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 32, 22, 14),
                      child: Row(
                        children: [
                          const Text('내 개체',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go('/pets'),
                            child: Row(
                              children: [
                                Text('전체보기',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.paleInk2)),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right,
                                    size: 14, color: AppColors.paleInk3),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                          children: [
                            // + 추가 (점선) — 제일 앞
                            _AddPetButton(onTap: () => context.push('/pets/new')),
                            ...pets.map((p) => Padding(
                              padding: const EdgeInsets.only(left: 14),
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
                    const SizedBox(height: 0),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
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
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 워드마크
                Text(
                  'bit-pet',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.paleInk2,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                // 인사
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: -0.7,
                      height: 1.15,
                    ),
                    children: [
                      TextSpan(text: '안녕, $userName님\n'),
                      TextSpan(
                        text: '오늘의 루틴 $remainingCount개',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 알림 버튼
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.paleLine),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_outlined,
                      size: 18, color: AppColors.primary),
                ),
                if (hasUnread)
                  Positioned(
                    right: 7, top: 7,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE05C3A), // oklch(0.7 0.18 25)
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
    return todayAsync.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox(
        height: 220,
        child: Center(child: Text('루틴을 불러올 수 없어요')),
      ),
      data: (routines) {
        if (routines.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.paleBgAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('오늘 예정된 루틴이 없어요 🌿',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.paleInk2,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: routines.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                      left: i == 0 ? 22 : 0,
                      right: 12),
                  child: _TodayRoutineCard(
                    routine: routines[i],
                    index: i,
                    total: routines.length,
                  ),
                ),
              ),
            ),
            // 도트 인디케이터
            if (routines.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(routines.length, (i) {
                    final active = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.paleLine,
                        borderRadius: BorderRadius.circular(3),
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

  IconData get _icon => switch (routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.star_outline,
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
      opacity: allDone ? 0.62 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시각 + 인덱스 pill
            Row(
              children: [
                Text(
                  routine.alarmTime ?? '--:--',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.paleInk2),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                    style: AppTextStyles.mono(10, FontWeight.w700,
                        color: AppColors.paleInk2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 아이콘 + 제목 + 마리수 pill
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(_icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel,
                          style: AppTextStyles.mono(9, FontWeight.w700,
                              color: AppColors.paleInk2)),
                      const SizedBox(height: 2),
                      Text(
                        routine.title,
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.primary, letterSpacing: -0.4,
                          decoration: allDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.paleInk2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('$totalPets마리',
                          style: AppTextStyles.mono(11, FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 진행도
            Row(
              children: [
                const Spacer(),
                Text('$done / $totalPets 완료',
                    style: AppTextStyles.mono(11, FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),

            // 액션 버튼 2개
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: allDone ? null : () => _openBulk(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: allDone ? Colors.transparent : AppColors.primary,
                        border: allDone
                            ? Border.all(color: AppColors.paleInk2, width: 1.5)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!allDone) ...[
                            const Icon(Icons.check,
                                size: 14, color: AppColors.paleBg),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            allDone ? '완료됨' : '일괄 완료',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: allDone
                                  ? AppColors.paleInk2
                                  : AppColors.paleBg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPerPet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.view_list_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text('개별 완료',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ── 개체 아바타 아이템 (64px, 이름만) ────────────────────────────
class _PetAvatarItem extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetAvatarItem({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pale = PalePalette.pale(PalePalette.keyFromHex(pet.colorCode));

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
                color: pale,
                borderRadius: BorderRadius.circular(18),
              ),
              child: pet.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.network(
                        pet.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.pets, size: 26, color: AppColors.primary),
                      ),
                    )
                  : const Icon(Icons.pets, size: 26, color: AppColors.primary),
            ),
            const SizedBox(height: 7),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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

// ── 개체 추가 버튼 (점선 원) ─────────────────────────────────────
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
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.paleLine,
                  width: 1.5,
                  // Flutter은 dashed border를 기본 지원하지 않으므로 실선으로 대체
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 24,
                color: AppColors.paleInk2,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '추가',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.paleInk2,
              ),
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
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.3)),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: Text(trailing!,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.paleInk2)),
            ),
        ],
      ),
    );
  }
}

// ── 최근 기록 타일 ────────────────────────────────────────────
class _RecentTile extends StatelessWidget {
  final RecentRecord record;
  final bool hasDivider;

  const _RecentTile({required this.record, this.hasDivider = true});

  Color get _dotColor {
    if (record.colorCode == null) return AppColors.petSage;
    try {
      return Color(int.parse(record.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petSage;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    return '${diff.inDays}일 전';
  }

  String _routeFor(RecentRecord r) {
    return switch (r.recordType) {
      'FEEDING'  => '/pets/${r.petId}/feeding',
      'WEIGHT'   => '/pets/${r.petId}/weight',
      'CLEANING' => '/pets/${r.petId}/records/cleaning',
      'MEMO'     => '/pets/${r.petId}/records/memo',
      'MATING'   => '/pets/${r.petId}/records/mating',
      'LAYING'   => '/pets/${r.petId}/records/laying',
      _ => '/pets/${r.petId}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(_routeFor(record)),
      child: Container(
        decoration: hasDivider
            ? const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.paleLineSoft)))
            : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _dotColor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                '${record.petName}  ${record.summary}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.paleInk3),
            const SizedBox(width: 2),
            Text(
              _timeAgo(record.createdAt),
              style: AppTextStyles.mono(10, FontWeight.w600,
                  color: AppColors.paleInk3),
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
  final Map<String, AsyncValue<List<RecentRecord>>> _dayCache = {};

  static const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    // 오늘 날짜 자동 선택 및 기록 로드
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _selDate = todayStr;
    _dayCache[todayStr] = const AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recordRepositoryProvider).getRecordsByDate(todayStr).then((records) {
        if (mounted) setState(() => _dayCache[todayStr] = AsyncData(records));
      }).catchError((e, s) {
        if (mounted) setState(() => _dayCache[todayStr] = AsyncError(e, s));
      });
    });
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

  void _selectDate(String date) {
    if (_selDate == date) {
      setState(() => _selDate = null);
      return;
    }
    setState(() => _selDate = date);
    if (!_dayCache.containsKey(date)) {
      setState(() => _dayCache[date] = const AsyncLoading());
      ref.read(recordRepositoryProvider).getRecordsByDate(date).then((records) {
        if (mounted) setState(() => _dayCache[date] = AsyncData(records));
      }).catchError((e, s) {
        if (mounted) setState(() => _dayCache[date] = AsyncError(e, s));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(homeCalendarProvider(_yearMonth));
    final dayAsync = _selDate != null ? _dayCache[_selDate!] : null;
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.paleLine),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              // 월 네비게이션
              Row(children: [
                GestureDetector(
                  onTap: _prev,
                  child: const Icon(Icons.chevron_left,
                      size: 20, color: AppColors.paleInk2),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 7),
                Text(
                  '${_month.year}년 ${_month.month}월',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  '전체 개체',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.paleInk3),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isCurrentMonth ? null : _next,
                  child: Icon(Icons.chevron_right,
                      size: 20,
                      color: isCurrentMonth
                          ? AppColors.paleLine
                          : AppColors.paleInk2),
                ),
              ]),
              const SizedBox(height: 10),
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
                                      ? AppColors.petPeach
                                      : AppColors.paleInk3,
                                )),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              // 날짜 그리드 — 기록 dot 유무와 무관하게 항상 렌더링
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

// ── 선택일 기록 섹션 (개체별 그룹핑) ────────────────────────────
// ── 날짜별 기록 섹션 (카테고리 행 + 개체 칩) ────────────────
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
    'FEEDING': '피딩', 'WEIGHT': '몸무게', 'CLEANING': '청소',
    'MEMO': '메모', 'MATING': '메이팅', 'LAYING': '산란',
  };
  static const _catIcon = {
    'FEEDING': Icons.restaurant_outlined,
    'WEIGHT': Icons.monitor_weight_outlined,
    'CLEANING': Icons.cleaning_services_outlined,
    'MEMO': Icons.sticky_note_2_outlined,
    'MATING': Icons.favorite_outline,
    'LAYING': Icons.egg_outlined,
  };

  static Color _petColor(String? code) {
    if (code == null || code.isEmpty) return AppColors.petSage;
    try { return Color(int.parse(code.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppColors.petSage; }
  }

  void _openDetail(BuildContext ctx, String type, List<RecentRecord> recs) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryDetailSheet(
        type: type,
        label: _catLabel[type] ?? type,
        records: recs,
        petColor: _petColor,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(header,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.2)),
            if (recordsAsync.hasValue)
              Text('$totalCount건',
                  style: AppTextStyles.mono(12, FontWeight.w700,
                      color: AppColors.paleInk2)),
          ],
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
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.paleLine, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('이 날의 기록이 없어요',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.paleInk3)),
                ),
              );
            }

            // 카테고리별 그룹핑 (정해진 순서)
            final grouped = <String, List<RecentRecord>>{};
            for (final r in records) {
              grouped.putIfAbsent(r.recordType, () => []).add(r);
            }
            final categories = _catOrder.where((c) => grouped.containsKey(c)).toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: categories.asMap().entries.map((e) {
                  final idx  = e.key;
                  final type = e.value;
                  final recs = grouped[type]!;
                  return _CategoryRow(
                    isLast: idx == categories.length - 1,
                    type: type,
                    icon: _catIcon[type] ?? Icons.circle_outlined,
                    label: _catLabel[type] ?? type,
                    records: recs,
                    petColor: _petColor,
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
  final bool isLast;
  final String type;
  final IconData icon;
  final String label;
  final List<RecentRecord> records;
  final Color Function(String?) petColor;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.isLast,
    required this.type,
    required this.icon,
    required this.label,
    required this.records,
    required this.petColor,
    required this.onTap,
  });

  static Color _catBg(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeed,
    'WEIGHT'   => AppColors.catWeight,
    'CLEANING' => AppColors.catClean,
    'MEMO'     => AppColors.catMemo,
    'MATING'   => AppColors.catMating,
    'LAYING'   => AppColors.catLaying,
    _ => AppColors.paleBgAlt,
  };

  static Color _catIconInk(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeedInk,
    'WEIGHT'   => AppColors.catWeightInk,
    'CLEANING' => AppColors.catCleanInk,
    'MEMO'     => AppColors.catMemoInk,
    'MATING'   => AppColors.catMatingInk,
    'LAYING'   => AppColors.catLayingInk,
    _ => AppColors.paleInk2,
  };

  @override
  Widget build(BuildContext context) {
    final names = records.map((r) => (name: r.petName, color: r.colorCode)).toList();
    const showMax = 2;
    final overflow = names.length > showMax ? names.length - showMax : 0;
    final visible = names.take(showMax).toList();
    final chipBg = _catBg(type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null
              : const Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
        ),
        child: Row(children: [
          // 카테고리 아이콘 칩
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 14, color: _catIconInk(type)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.paleInk2)),
          ),
          const Spacer(),
          // 개체 칩들 (우측 정렬, 카테고리 색 배경)
          ...visible.map((n) => Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(n.name,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _catIconInk(type)),
                  overflow: TextOverflow.ellipsis),
            ),
          )),
          if (overflow > 0) Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.paleBgAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+$overflow',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.paleInk2)),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.paleInk3),
        ]),
      ),
    );
  }
}

// ── 카테고리 상세 바텀시트 ────────────────────────────────────
class _CategoryDetailSheet extends StatelessWidget {
  final String type;
  final String label;
  final List<RecentRecord> records;
  final Color Function(String?) petColor;

  const _CategoryDetailSheet({
    required this.type,
    required this.label,
    required this.records,
    required this.petColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
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
              decoration: BoxDecoration(
                  color: AppColors.paleLine, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.3)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: records.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.paleLineSoft),
              itemBuilder: (_, i) {
                final r = records[i];
                final hasMemo = r.memo != null && r.memo!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            color: petColor(r.colorCode), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.petName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            if (r.summary.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(r.summary,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.paleInk2)),
                            ],
                            if (hasMemo) ...[
                              const SizedBox(height: 4),
                              Text(r.memo!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.paleInk3,
                                      fontStyle: FontStyle.italic)),
                            ],
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
        _ => AppColors.paleInk3,
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
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.paleBgAlt
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.paleBg : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
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
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
