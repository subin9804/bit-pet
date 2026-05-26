import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../record/data/models/record_models.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/routine_today_check_sheet.dart';
import '../../record/presentation/feeding_record_sheet.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final userName = authAsync.valueOrNull?.name ?? '사용자';
    final todayAsync = ref.watch(todayRoutinesProvider);
    final petsAsync = ref.watch(petListProvider);
    final recentAsync = ref.watch(recentRecordsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    final todayCount = todayAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayRoutinesProvider);
            ref.invalidate(recentRecordsProvider);
            ref.read(petListProvider.notifier).load();
          },
          child: CustomScrollView(
            slivers: [
              // ── 헤더 ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'bit-pet',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('안녕, ${userName}님', style: AppTextStyles.h1),
                            Text(
                              '오늘의 루틴 ${todayCount}개',
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, size: 26),
                            onPressed: () => context.push('/notifications'),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 10,
                              top: 10,
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
                    ],
                  ),
                ),
              ),

              // ── TODAY 루틴 슬라이더 ───────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            'TODAY',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 12,
                              letterSpacing: 2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (todayAsync.valueOrNull != null)
                            Text(
                              '${_currentPage + 1} / ${todayCount}',
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    todayAsync.when(
                      loading: () => SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox(
                        height: 200,
                        child: Center(child: Text('루틴을 불러올 수 없어요')),
                      ),
                      data: (routines) {
                        if (routines.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('오늘 예정된 루틴이 없어요 🌿'),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemCount: routines.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _RoutineCard(
                                routine: routines[i],
                                index: i,
                                total: routines.length,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // 페이지 도트
                    if (todayCount > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(todayCount, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentPage ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ),

              // ── 내 개체 ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                      child: Row(
                        children: [
                          Text('내 개체', style: AppTextStyles.h3),
                          const Spacer(),
                          petsAsync.whenOrNull(
                                data: (pets) => TextButton(
                                  onPressed: () => context.go('/pets'),
                                  child: Text(
                                    '${pets.length} →',
                                    style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ) ??
                              const SizedBox(),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: petsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) =>
                            const Center(child: Text('개체 로드 실패')),
                        data: (pets) {
                          if (pets.isEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GestureDetector(
                                onTap: () => context.push('/pets/new'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg2,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('첫 개체 등록하기'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: pets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => _PetChip(pet: pets[i]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── 최근 기록 ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('최근 기록', style: AppTextStyles.h3),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/pets'),
                        child: Text(
                          '더보기 →',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              recentAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
                data: (records) {
                  if (records.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('아직 기록이 없어요',
                              style: AppTextStyles.caption),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _RecentRecordTile(record: records[i]),
                        childCount: records.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 루틴 카드 (TODAY 슬라이더) ──────────────────────────────────────────────

class _RoutineCard extends ConsumerWidget {
  final TodayRoutine routine;
  final int index;
  final int total;

  const _RoutineCard({
    required this.routine,
    required this.index,
    required this.total,
  });

  Color get _bgColor {
    if (routine.isAllCompleted) return AppColors.petColorMint;
    return switch (routine.routineType) {
      RoutineType.FEEDING => AppColors.petColorPeach,
      RoutineType.CLEANING => AppColors.petColorSky,
      RoutineType.WEIGHT => AppColors.petColorLavender,
      RoutineType.CUSTOM => AppColors.petColorButter,
    };
  }

  String get _typeLabel => switch (routine.routineType) {
        RoutineType.FEEDING => '피딩',
        RoutineType.CLEANING => '청소',
        RoutineType.WEIGHT => '체중',
        RoutineType.CUSTOM => '사용자',
      };

  IconData get _typeIcon => switch (routine.routineType) {
        RoutineType.FEEDING => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM => Icons.star_outline,
      };

  void _onComplete(BuildContext context, WidgetRef ref) {
    if (routine.isAllCompleted) return;
    if (routine.routineType == RoutineType.FEEDING) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FeedingRecordSheet(
          routine: routine,
          fromHome: true,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RoutineTodayCheckSheet(routine: routine),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstPet =
        routine.petStatuses.isNotEmpty ? routine.petStatuses.first : null;

    return Container(
      margin: const EdgeInsets.only(left: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 & 카운터
          Row(
            children: [
              Text(
                routine.alarmTime ?? '--:--',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 개체 정보 & 스프라이트
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PetSprite(
                colorCode: firstPet?.colorCode,
                imageUrl: firstPet?.imageUrl,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstPet?.petName ?? routine.title,
                      style: AppTextStyles.bodyBold.copyWith(
                        decoration: firstPet != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                    Text(_typeLabel, style: AppTextStyles.caption),
                    if (routine.totalPetCount > 1)
                      Text(
                        '${routine.totalPetCount}마리',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // 완료 버튼
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onComplete(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: routine.isAllCompleted
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: routine.isAllCompleted
                            ? Colors.transparent
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        routine.isAllCompleted ? '완료됨' : '완료',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: routine.isAllCompleted
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  routine.isAlarmEnabled
                      ? Icons.notifications_outlined
                      : Icons.notifications_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 개체 칩 (내 개체 가로 스크롤) ────────────────────────────────────────────

class _PetChip extends StatelessWidget {
  final Pet pet;
  const _PetChip({required this.pet});

  Color get _color {
    if (pet.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(pet.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
            child: pet.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      pet.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets,
                        color: _color.withValues(alpha: 0.6),
                        size: 32,
                      ),
                    ),
                  )
                : Icon(
                    Icons.pets,
                    color: _colorForeground,
                    size: 32,
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              pet.name,
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color get _colorForeground {
    final luminance = 0.299 * _color.r + 0.587 * _color.g + 0.114 * _color.b;
    return luminance > 0.6
        ? AppColors.primary.withValues(alpha: 0.6)
        : Colors.white70;
  }
}

// ── 최근 기록 타일 ──────────────────────────────────────────────────────────

class _RecentRecordTile extends StatelessWidget {
  final RecentRecord record;
  const _RecentRecordTile({required this.record});

  Color get _dotColor {
    if (record.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(record.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
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
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${record.petName}  ${record.summary}',
                style: AppTextStyles.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(_timeAgo(record.createdAt), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── 공유 위젯: 펫 스프라이트 플레이스홀더 ────────────────────────────────────

class _PetSprite extends StatelessWidget {
  final String? colorCode;
  final String? imageUrl;
  final double size;

  const _PetSprite({this.colorCode, this.imageUrl, this.size = 48});

  Color get _bgColor {
    if (colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.25),
              child: Image.network(imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _icon()),
            )
          : _icon(),
    );
  }

  Widget _icon() {
    return Icon(Icons.pets,
        size: size * 0.5, color: AppColors.primary.withValues(alpha: 0.5));
  }
}
