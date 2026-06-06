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
import '../../record/data/models/record_models.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/bulk_confirm_sheet.dart';
import '../../routine/presentation/per_pet_confirm_sheet.dart';
import '../../group/providers/group_provider.dart';


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
                            ...pets.map((p) => Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: _PetAvatarItem(
                                pet: p,
                                onTap: () => context.push('/pets/${p.id}'),
                              ),
                            )),
                            // + 추가 (점선)
                            _AddPetButton(onTap: () => context.push('/pets/new')),
                          ],
                        ),
                      ),
                    ),

                    // ── 최근 기록 섹션 ──────────────────────────
                    _SectionHeader(
                      title: '최근 기록',
                      trailing: '더보기 →',
                      onTap: () => context.go('/pets'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                      child: recentAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (records) {
                          if (records.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.paleBgAlt,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text('아직 기록이 없어요',
                                  style: TextStyle(
                                      color: AppColors.paleInk3,
                                      fontSize: 13)),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.paleLine),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Column(
                              children: records.take(4).toList().asMap().entries.map((e) {
                                final i = e.key;
                                final r = e.value;
                                return _RecentTile(
                                  record: r,
                                  hasDivider: i < records.take(4).length - 1,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
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
              height: 216,
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
  final String trailing;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.trailing,
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
          GestureDetector(
            onTap: onTap,
            child: Text(trailing,
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            _timeAgo(record.createdAt),
            style: AppTextStyles.mono(10, FontWeight.w600,
                color: AppColors.paleInk3),
          ),
        ],
      ),
    );
  }
}
