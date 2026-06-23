// 01d · 루틴 개별 완료 — peek 캐러셀
// 저장 트리거: 1) 이 개체 완료 버튼  2) 다음 버튼  3) 저장하고 종료 버튼
// 이전 버튼: 저장 없이 이동, 입력 상태 유지
// 완료됨 버튼: 클릭 시 로그 삭제 후 미완료 상태로 복귀
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/toast_message.dart';
import '../../record/presentation/widgets/feed_items_editor.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import 'widgets/confirm_accordion.dart';
import '../../record/providers/record_provider.dart';

// ── 개체별 입력 상태 ──────────────────────────────────────────────
class _PerPetRec {
  List<FeedFormData> feedItems;
  String memo;
  bool done;
  bool feedOpen;
  bool memoOpen;
  int? savedLogId;
  final TextEditingController memoCtrl;

  _PerPetRec({required this.done, int? logId})
      : feedItems = const [],
        memo = '',
        feedOpen = false,
        memoOpen = false,
        savedLogId = logId,
        memoCtrl = TextEditingController();
}

class PerPetConfirmSheet extends ConsumerStatefulWidget {
  final TodayRoutine routine;
  const PerPetConfirmSheet({super.key, required this.routine});

  @override
  ConsumerState<PerPetConfirmSheet> createState() =>
      _PerPetConfirmSheetState();
}

class _PerPetConfirmSheetState extends ConsumerState<PerPetConfirmSheet> {
  late final PageController _page;
  late final Map<int, _PerPetRec> _rec;
  int _idx = 0;
  bool _saving = false;

  List<TodayPetStatus> get _pets => widget.routine.petStatuses;
  bool get _isFeed => widget.routine.routineType == RoutineType.FEEDING;
  bool get _isLast => _idx >= _pets.length - 1;
  int get _completedCount => _rec.values.where((r) => r.done).length;

  Color get _accent => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  IconData get _icon => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.star_outline,
      };

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.84);
    _rec = {
      for (final s in _pets)
        s.petId: _PerPetRec(done: s.isCompleted, logId: s.logId),
    };
    // 이미 완료된 개체의 저장 메모 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedLogs());
  }

  @override
  void dispose() {
    _page.dispose();
    for (final r in _rec.values) r.memoCtrl.dispose();
    super.dispose();
  }

  // ── 이미 완료된 개체의 저장 메모 로드 ─────────────────────────────
  Future<void> _loadSavedLogs() async {
    if (!mounted || !_pets.any((p) => p.isCompleted)) return;
    try {
      final logs = await ref.read(routineRepositoryProvider).getLogs(widget.routine.id);
      final today = DateTime.now();
      for (final pet in _pets) {
        if (!pet.isCompleted) continue;
        final rec = _rec[pet.petId]!;
        final log = logs.where((l) =>
          l.petId == pet.petId &&
          l.executedAt.year == today.year &&
          l.executedAt.month == today.month &&
          l.executedAt.day == today.day
        ).lastOrNull;
        if (log != null && mounted) {
          setState(() {
            rec.savedLogId = log.id;
            if (log.memo != null) {
              rec.memo = log.memo!;
              rec.memoCtrl.text = log.memo!;
            }
          });
        }
      }
    } catch (_) {}
  }

  // ── 개체 완료 저장 (이 개체 완료 버튼) ───────────────────────────
  Future<void> _completePet(TodayPetStatus pet) async {
    final rec  = _rec[pet.petId]!;
    final memo = rec.memo.trim().isEmpty ? null : rec.memo.trim();
    setState(() => _saving = true);
    try {
      final log = await ref.read(routineRepositoryProvider).completeIndividual(
        widget.routine.id,
        RoutineCompleteIndividualRequest(
          petId:     pet.petId,
          status:    RoutineLogStatus.COMPLETED,
          feedItems: _isFeed ? rec.feedItems : const [],
          memo:      memo,
        ),
      );
      rec.savedLogId = log?.id;
      ref.read(todayRoutinesProvider.notifier)
          .updatePetStatus(widget.routine.id, pet.petId, true);
      if (mounted) {
        setState(() => rec.done = true);
        showToast(context, '${pet.petName} 완료', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 완료 취소 (완료됨 버튼 → 로그 삭제) ───────────────────────────
  Future<void> _undoPet(TodayPetStatus pet) async {
    final rec   = _rec[pet.petId]!;
    final logId = rec.savedLogId;
    if (logId == null) {
      // 로그 ID 없이 로컬에서만 done=true인 경우 (드문 케이스)
      setState(() => rec.done = false);
      ref.read(todayRoutinesProvider.notifier)
          .updatePetStatus(widget.routine.id, pet.petId, false);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(routineRepositoryProvider).deleteLog(logId);
      rec.savedLogId = null;
      ref.read(todayRoutinesProvider.notifier)
          .updatePetStatus(widget.routine.id, pet.petId, false);
      if (mounted) setState(() => rec.done = false);
    } catch (e) {
      if (mounted) showToast(context, '취소 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 미완료 시 저장 (다음/저장하고 종료 버튼) ──────────────────────
  Future<void> _saveIfNotDone(TodayPetStatus pet) async {
    final rec = _rec[pet.petId]!;
    if (rec.done) return;
    final memo = rec.memo.trim().isEmpty ? null : rec.memo.trim();
    try {
      final log = await ref.read(routineRepositoryProvider).completeIndividual(
        widget.routine.id,
        RoutineCompleteIndividualRequest(
          petId:     pet.petId,
          status:    RoutineLogStatus.COMPLETED,
          feedItems: _isFeed ? rec.feedItems : const [],
          memo:      memo,
        ),
      );
      rec.savedLogId = log?.id;
      ref.read(todayRoutinesProvider.notifier)
          .updatePetStatus(widget.routine.id, pet.petId, true);
      if (mounted) setState(() => rec.done = true);
    } catch (_) {}
  }

  void _handleNext() {
    _saveIfNotDone(_pets[_idx]).then((_) {
      if (mounted) _go(_idx + 1);
    });
  }

  void _handleFinish() {
    final routine = widget.routine;
    _saveIfNotDone(_pets[_idx]).then((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(routineTodayStatusProvider(routine.id));
      final ym = DateTime.now();
      ref.invalidate(homeCalendarProvider(
          '${ym.year}-${ym.month.toString().padLeft(2, '0')}'));
      showToast(context, '$_completedCount마리 완료 처리됐어요',
          type: ToastType.success);
    });
  }

  void _go(int target) {
    _page.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;
    final screenH = MediaQuery.of(context).size.height;
    final cardH   = (screenH - 112).clamp(0.0, 524.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: const Color(0x801C1610)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 326),
                child: SizedBox(
                  height: cardH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.paleBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x521C1610),
                          blurRadius: 60, offset: Offset(0, 24)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // ── 헤더 밴드 ──────────────────────────────
                        Container(
                          color: _accent,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(_icon, size: 21, color: AppColors.primary),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '개별 완료 · ${routine.alarmTime ?? '--:--'}',
                                      style: AppTextStyles.mono(10, FontWeight.w700,
                                          color: AppColors.paleInk2),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      routine.title,
                                      style: const TextStyle(
                                          fontSize: 17, fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: -0.4),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppTextStyles.mono(12, FontWeight.w700),
                                    children: [
                                      TextSpan(text: '$_completedCount'),
                                      TextSpan(
                                        text: ' / ${_pets.length} 완료',
                                        style: const TextStyle(
                                            color: AppColors.paleInk2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── peek 캐러셀 ────────────────────────────
                        Expanded(
                          child: PageView.builder(
                            controller: _page,
                            onPageChanged: (i) => setState(() => _idx = i),
                            itemCount: _pets.length,
                            itemBuilder: (_, i) => _PetPage(
                              page: _page,
                              index: i,
                              pet: _pets[i],
                              rec: _rec[_pets[i].petId]!,
                              isFeed: _isFeed,
                              accent: _accent,
                              saving: _saving,
                              onComplete: () => _completePet(_pets[i]),
                              onUndo: () => _undoPet(_pets[i]),
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ),

                        // ── 푸터 ───────────────────────────────────
                        _Footer(
                          isLast: _isLast,
                          canPrev: _idx > 0,
                          onCancel: () => Navigator.of(context).pop(),
                          onPrev: () => _go(_idx - 1),
                          onNext: _handleNext,
                          onFinish: _handleFinish,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 개체 1장 (peek 스케일 적용) ────────────────────────────────────
class _PetPage extends StatelessWidget {
  final PageController page;
  final int index;
  final TodayPetStatus pet;
  final _PerPetRec rec;
  final bool isFeed;
  final Color accent;
  final bool saving;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onChanged;

  const _PetPage({
    required this.page,
    required this.index,
    required this.pet,
    required this.rec,
    required this.isFeed,
    required this.accent,
    required this.saving,
    required this.onComplete,
    required this.onUndo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: page,
      builder: (context, child) {
        double delta = 0;
        if (page.position.haveDimensions) {
          delta = (page.page ?? page.initialPage.toDouble()) - index;
        }
        final t       = (1 - delta.abs()).clamp(0.0, 1.0);
        final scale   = 0.92 + 0.08 * t;
        final opacity = 0.4 + 0.6 * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개체 식별행
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: PalePalette.pale(PalePalette.keyFromHex(pet.colorCode)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: pet.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(pet.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.pets,
                                  size: 24, color: AppColors.primary)))
                      : Icon(Icons.pets, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.petName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.primary, letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis),
                      if (pet.speciesName.isNotEmpty)
                        Text(pet.speciesName,
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600,
                                color: AppColors.paleInk2),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // 대기/완료 칩
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rec.done ? AppColors.primary : AppColors.paleBgAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rec.done) ...[
                        const Icon(Icons.check, size: 12, color: AppColors.paleBg),
                        const SizedBox(width: 3),
                      ],
                      Text(rec.done ? '완료' : '대기',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: rec.done
                                  ? AppColors.paleBg
                                  : AppColors.paleInk3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 완료/미완료 버튼
            GestureDetector(
              onTap: saving ? null : (rec.done ? onUndo : onComplete),
              child: Container(
                width: double.infinity, height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rec.done ? AppColors.paleBgAlt : AppColors.primary,
                  border: rec.done ? Border.all(color: AppColors.paleLine) : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(rec.done ? Icons.check_circle_outline : Icons.check,
                        size: 17,
                        color: rec.done ? AppColors.paleInk2 : AppColors.paleBg),
                    const SizedBox(width: 8),
                    Text(
                      rec.done ? '완료됨' : '이 개체 완료',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700,
                          color: rec.done ? AppColors.paleInk2 : AppColors.paleBg),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                rec.done ? '다시 클릭하면 완료가 취소돼요' : '\'다음\' 버튼으로도 저장할 수 있어요',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.paleInk3),
              ),
            ),
            const SizedBox(height: 4),

            // 피딩 내용 아코디언 (feed 타입만)
            if (isFeed)
              ConfirmAccordion(
                label: '피딩 내용',
                optional: true,
                summary: null,
                summaryActive: false,
                open: rec.feedOpen,
                onToggle: () {
                  rec.feedOpen = !rec.feedOpen;
                  onChanged();
                },
                child: FeedItemsEditor(
                  items: rec.feedItems,
                  bandColor: accent,
                  onChanged: (items) {
                    rec.feedItems = items;
                    onChanged();
                  },
                ),
              ),

            // 메모 아코디언
            ConfirmAccordion(
              label: '메모',
              optional: true,
              summary: null,
              summaryActive: false,
              open: rec.memoOpen,
              onToggle: () {
                rec.memoOpen = !rec.memoOpen;
                onChanged();
              },
              child: TextField(
                controller: rec.memoCtrl,
                onChanged: (v) => rec.memo = v,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: '예: 1마리 남김 · 식욕 좋음',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: AppColors.paleLine)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: AppColors.paleLine)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 푸터 ─────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool isLast;
  final bool canPrev;
  final VoidCallback onCancel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _Footer({
    required this.isLast,
    required this.canPrev,
    required this.onCancel,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Row(
        children: [
          if (!isLast) ...[
            _FooterBtn(label: '취소', onTap: onCancel),
            const SizedBox(width: 8),
          ],
          _FooterBtn(label: '이전', onTap: canPrev ? onPrev : null),
          const SizedBox(width: 8),
          Expanded(
            child: isLast
                ? GestureDetector(
                    onTap: onFinish,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16, color: AppColors.paleBg),
                          SizedBox(width: 7),
                          Text('저장하고 종료',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.paleBg)),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: onNext,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('다음',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 16, color: AppColors.paleInk2),
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

class _FooterBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _FooterBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.paleLine),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.paleInk2)),
        ),
      ),
    );
  }
}
