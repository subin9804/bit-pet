// 01d · 루틴 개별 완료 — peek 캐러셀
// 저장 트리거: 1) 이 개체 완료 버튼  2) 다음 버튼/슬라이드  3) 종료 버튼
//   단, 2·3번은 추가 데이터(급여 항목 또는 메모)가 있을 때만 저장
//   마지막 개체에서 종료 버튼은 루틴 완료를 의미하지 않음 (메모 있으면 저장만)
// 이전 버튼: 저장 없이 이동, 입력 상태 유지
// 완료됨 버튼: 클릭 시 로그 삭제 후 미완료 상태로 복귀
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../../record/presentation/widgets/feed_items_editor.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import 'widgets/confirm_accordion.dart';
import '../../record/providers/record_invalidation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';

// ── 개체별 입력 상태 ──────────────────────────────────────────────
class _PerPetRec {
  List<FeedFormData> feedItems;
  String memo;
  String weight; // WEIGHT 루틴 전용 — 완료 시 필수
  bool done;
  bool dirty; // 마지막 저장 이후 입력이 바뀌었는지 — 완료 상태에서 재저장 판단용
  bool feedOpen;
  bool memoOpen;
  int? savedLogId;
  final TextEditingController memoCtrl;
  final TextEditingController weightCtrl;

  _PerPetRec({required this.done, int? logId})
      : feedItems = const [],
        memo = '',
        weight = '',
        dirty = false,
        feedOpen = false,
        memoOpen = false,
        savedLogId = logId,
        memoCtrl = TextEditingController(),
        weightCtrl = TextEditingController();

  double? get weightG => double.tryParse(weight.trim());
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
  bool get _isWeight => widget.routine.routineType == RoutineType.WEIGHT;
  bool get _isLast => _idx >= _pets.length - 1;
  int get _completedCount => _rec.values.where((r) => r.done).length;

  Color get _accent => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  @override
  void initState() {
    super.initState();
    // viewportFraction 1.0 — 예전엔 0.84 로 양옆 카드를 흐릿하게 걸쳐 보여줬는데,
    // 그 peek 때문에 **정작 입력하는 현재 개체의 폭이 16% 깎였다**.
    // 슬라이드로 개체를 넘기는 동작은 그대로 두고, 옆 카드를 내밀지만 않는다.
    _page = PageController();
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
    for (final r in _rec.values) {
      r.memoCtrl.dispose();
      r.weightCtrl.dispose();
    }
    super.dispose();
  }

  // ── 저장된 오늘 로그 복원 (메모·급여 항목·체중, 완료/미완료 무관) ─────
  Future<void> _loadSavedLogs() async {
    if (!mounted) return;
    try {
      final logs = await ref.read(routineRepositoryProvider).getLogs(widget.routine.id);
      final now = DateTime.now();
      for (final pet in _pets) {
        final rec = _rec[pet.petId]!;
        // executedAt은 UTC로 내려오므로 로컬로 변환해 '오늘'을 비교
        final log = logs.where((l) {
          final ex = l.executedAt.toLocal();
          return l.petId == pet.petId &&
              ex.year == now.year && ex.month == now.month && ex.day == now.day;
        }).lastOrNull;
        if (log == null) continue;
        rec.savedLogId = log.id;
        rec.done = log.status == RoutineLogStatus.COMPLETED;
        if (log.memo != null && log.memo!.isNotEmpty) {
          rec.memo = log.memo!;
          rec.memoCtrl.text = log.memo!;
          rec.memoOpen = true;
        }
        if (_isFeed && log.feedItems.isNotEmpty) {
          rec.feedItems = log.feedItems;
          rec.feedOpen = true;
        }
        if (_isWeight && log.weightG != null) {
          rec.weight = log.weightG!.toString();
          rec.weightCtrl.text = rec.weight;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ── 개체 완료 저장 (이 개체 완료 버튼) ───────────────────────────
  Future<void> _completePet(TodayPetStatus pet) async {
    final rec = _rec[pet.petId]!;
    // 체중 루틴은 실측값 필수 (서버도 거부함)
    if (_isWeight && rec.weightG == null) {
      showToast(context, '${pet.petName}의 몸무게를 입력해 주세요', type: ToastType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      await _persist(pet, completed: true);
      if (mounted) {
        setState(() {});
        showToast(context, '${pet.petName} 완료', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 실제 저장 (신규 생성 또는 기존 로그 갈아끼우기) ─────────────────
  // completed=true  → 완료(COMPLETED), false → 미완료(REFUSED).
  // 완료 여부와 무관하게 유저가 입력한 내용(급여·체중·메모)은 모두 저장한다.
  // 기존 로그가 있으면 삭제 후 재생성 → 완료↔미완료 전환·수정 반영.
  // (백엔드 deleteLog가 짝 급여·체중·청소·메모 기록까지 함께 정리)
  Future<void> _persist(TodayPetStatus pet, {required bool completed}) async {
    final rec  = _rec[pet.petId]!;
    final repo = ref.read(routineRepositoryProvider);
    final memo = rec.memo.trim().isEmpty ? null : rec.memo.trim();
    final prevLogId = rec.savedLogId;
    if (prevLogId != null) {
      await repo.deleteLog(prevLogId);
      rec.savedLogId = null;
    }
    final log = await repo.completeIndividual(
      widget.routine.id,
      RoutineCompleteIndividualRequest(
        petId:     pet.petId,
        status:    completed ? RoutineLogStatus.COMPLETED : RoutineLogStatus.REFUSED,
        feedItems: _isFeed ? rec.feedItems : const [],
        weightG:   _isWeight ? rec.weightG : null,
        memo:      memo,
      ),
    );
    rec.savedLogId = log?.id;
    rec.done  = completed;
    rec.dirty = false;
    ref.read(todayRoutinesProvider.notifier)
        .updatePetStatus(widget.routine.id, pet.petId, completed);
    // 종료 버튼으로 나가야만 갱신되면, X 로 닫은 사람은 캘린더가 옛 값인 채로 남는다
    invalidatePetRecords(ref, pet.petId);
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
      invalidatePetRecords(ref, pet.petId);
      if (mounted) setState(() => rec.done = false);
    } catch (e) {
      if (mounted) showToast(context, '취소 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 입력한 내용 존재 여부 (메모·급여 항목·체중) ─────────────────────
  bool _hasEnteredData(_PerPetRec rec) =>
      rec.memo.trim().isNotEmpty ||
      (_isFeed && rec.feedItems.isNotEmpty) ||
      (_isWeight && rec.weightG != null);

  // ── 저장이 필요할 때만 저장 (다음/종료/슬라이드 트리거) ──────────
  //  · 완료됨(버튼 누름): 이후 수정(dirty)이 있으면 완료 상태로 재저장
  //  · 미완료: '이 개체 완료'를 안 눌렀어도, 입력한 내용(급여·체중·메모)이
  //           있으면 미완료(REFUSED)로 저장해 내용을 보존하고 나중에 다시 볼 수 있게 함.
  Future<void> _saveIfNeeded(TodayPetStatus pet) async {
    final rec = _rec[pet.petId]!;
    if (rec.done) {
      if (!rec.dirty) return;
      // 완료 상태 유지한 채 수정분 반영 (체중 미입력이면 서버 거부 → 스킵)
      if (_isWeight && rec.weightG == null) return;
      try {
        await _persist(pet, completed: true);
        if (mounted) setState(() {});
      } catch (_) {}
      return;
    }
    // 완료 버튼을 안 눌렀어도 입력한 내용이 있으면 '미완료'로 저장
    if (!_hasEnteredData(rec)) return;
    try {
      await _persist(pet, completed: false);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _handleNext() {
    _saveIfNeeded(_pets[_idx]).then((_) {
      if (mounted) _go(_idx + 1);
    });
  }

  void _handleFinish() {
    final routine = widget.routine;
    // 종료 시 현재 개체의 입력·수정도 반드시 저장하고 닫는다
    _saveIfNeeded(_pets[_idx]).then((_) {
      if (!mounted) return;
      // ⚠️ 무효화를 pop 보다 먼저 한다. 닫고 나서 부르면 이 시트의 ref 가 이미
      // 버려진 뒤라, 던지는 순간 뒤따르는 무효화가 통째로 건너뛰어진다.
      ref.invalidate(routineTodayStatusProvider(routine.id));
      for (final p in _pets) {
        invalidatePetRecords(ref, p.petId);
      }
      Navigator.of(context).pop();
      if (_completedCount > 0) {
        showToast(context, '$_completedCount마리 완료 처리됐어요',
            type: ToastType.success);
      }
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
    final screenH   = MediaQuery.of(context).size.height;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    // 카드 높이. 상한이 524 고정이라 요즘 폰에서는 화면 위아래가 남는데도 개체 목록만
    // 좁게 스크롤됐다 — 개체가 많을수록 손해다. 화면 비율로 바꿔 큰 폰에서 실제로 커지게 한다.
    // (작은 폰에서는 screenH - 112 쪽이 먼저 걸려 예전과 거의 같다)
    final cardH = (screenH - 112 - keyboardH).clamp(0.0, screenH * 0.82);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: const Color(0x801C1610)),
          ),
          // 키보드가 올라오면 그만큼 위로 밀어 입력창을 가리지 않게 함 (일괄 완료와 동일)
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(bottom: keyboardH),
            child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: SizedBox(
                  height: cardH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.paleBg,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: AppColors.paleLine),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // ── 헤더 밴드 ──────────────────────────────
                        Container(
                          color: _accent,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  borderRadius: AppRadius.brLg,
                                ),
                                child: RecordTypeIcon(widget.routine.routineType.name,
                                    size: 21, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '개별 완료 · ${routine.alarmTime ?? '--:--'}',
                                      style: AppTextStyles.mono(10, FontWeight.w700,
                                          color: AppColors.paleInk2),
                                    ),
                                    const SizedBox(height: 4),
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: AppRadius.brPill,
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
                            onPageChanged: (i) {
                              final prev = _idx;
                              setState(() => _idx = i);
                              // 앞으로 슬라이드할 때 이전 개체 조건부 저장
                              if (i > prev) _saveIfNeeded(_pets[prev]);
                            },
                            itemCount: _pets.length,
                            itemBuilder: (_, i) => _PetPage(
                              pet: _pets[i],
                              rec: _rec[_pets[i].petId]!,
                              isFeed: _isFeed,
                              isWeight: _isWeight,
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
          ),
        ],
      ),
    );
  }
}

// ── 개체 1장 ──────────────────────────────────────────────────────
class _PetPage extends StatelessWidget {
  final TodayPetStatus pet;
  final _PerPetRec rec;
  final bool isFeed;
  final bool isWeight;
  final Color accent;
  final bool saving;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onChanged;

  const _PetPage({
    required this.pet,
    required this.rec,
    required this.isFeed,
    required this.isWeight,
    required this.accent,
    required this.saving,
    required this.onComplete,
    required this.onUndo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개체 식별행
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.bgAlt,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: pet.imageUrl != null
                      ? ClipRRect(
                          borderRadius: AppRadius.brLg,
                          child: AppNetworkImage(pet.imageUrl,
                              fit: BoxFit.cover,
                              memWidth: 150,
                              placeholder: AppIcon(AppIcons.petLine,
                                  size: 24, color: AppColors.primary)))
                      : AppIcon(AppIcons.petLine, size: 24, color: AppColors.primary),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rec.done ? AppColors.primary : AppColors.paleBgAlt,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rec.done) ...[
                        const Icon(Icons.check, size: 16, color: AppColors.paleBg),
                        const SizedBox(width: 4),
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
            const SizedBox(height: 20),

            // 완료/미완료 버튼
            GestureDetector(
              onTap: saving ? null : (rec.done ? onUndo : onComplete),
              child: Container(
                width: double.infinity, height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rec.done ? AppColors.paleBgAlt : AppColors.primary,
                  border: rec.done ? Border.all(color: AppColors.paleLine) : null,
                  borderRadius: AppRadius.brMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(rec.done ? Icons.check_circle_outline : Icons.check,
                        size: 20,
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
            const SizedBox(height: 8),
            Center(
              child: Text(
                rec.done
                    ? '다시 클릭하면 완료가 취소돼요'
                    : isWeight
                        ? '몸무게 입력 후 완료를 눌러주세요'
                        : '완료하려면 위 버튼 · 입력만 하고 넘기면 미완료로 저장돼요',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.paleInk3),
              ),
            ),
            const SizedBox(height: 8),

            // 몸무게 입력 (WEIGHT 루틴 — 필수)
            if (isWeight) ...[
              const SizedBox(height: 8),
              Text('몸무게 (g) *',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.paleInk2)),
              const SizedBox(height: 8),
              TextField(
                controller: rec.weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  rec.weight = v;
                  rec.dirty = true;
                  onChanged();
                },
                style: const TextStyle(fontSize: 14, color: AppColors.primary),
                decoration: AppInputStyles.textarea(hintText: '예: 52.5')
                    .copyWith(suffixText: 'g'),
              ),
            ],

            // 급여 내용 아코디언 (feed 타입만)
            if (isFeed)
              ConfirmAccordion(
                label: '급여 내용',
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
                  petId: pet.petId,
                  bandColor: accent,
                  onChanged: (items) {
                    rec.feedItems = items;
                    rec.dirty = true;
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
                onChanged: (v) {
                  rec.memo = v;
                  rec.dirty = true;
                },
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
                decoration: AppInputStyles.textarea(
                  hintText: '예: 1마리 남김 · 식욕 좋음',
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                        borderRadius: AppRadius.brMd,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16, color: AppColors.paleBg),
                          SizedBox(width: 8),
                          Text('종료',
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
                        borderRadius: AppRadius.brMd,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('다음',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          SizedBox(width: 4),
                          AppIcon(AppIcons.chevronRight,
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
            borderRadius: AppRadius.brMd,
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
