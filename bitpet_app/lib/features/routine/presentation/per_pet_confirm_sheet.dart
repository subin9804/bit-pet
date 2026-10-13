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
        RoutineType.WEIGHT   => AppColors.petClay,
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
    final media   = MediaQuery.of(context);

    // ⚠️ 이 시트는 `AppSheet` 의 7슬롯을 쓰지 않는다 — 개체를 한 장씩 넘기는
    // 캐러셀이라 '이전/다음'이 필요한데, 7슬롯에는 주 버튼 하나 자리뿐이다
    // (FabRecordSheet 와 같은 예외). 대신 **껍데기는 완전히 같게** 맞춘다:
    // **canvas 바탕** · brSheet 모서리 · 40×4 핸들 · 스크림 · 최대 높이 0.9.
    //
    // ⛔ 헤더 eyebrow 의 `개별 완료 · 09:00` 중 시각은 지웠다 — 루틴에 수행
    //    시각은 없다. 그 자리는 '몇 마리 끝났나'가 쓴다.
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        // ⚠️ `height: 0.9` 고정이었다 — 개체가 1마리여도 시트가 화면 끝까지
        // 올라와 빈 공간만 가득했다. `AppSheet` 과 같은 방식으로 **최대치만**
        // 정하고 높이는 내용이 결정한다(아래 `mainAxisSize.min`).
        constraints: BoxConstraints(
          maxHeight: (media.size.height - media.viewInsets.bottom) * 0.9,
        ),
        // ⚠️ 흰 바탕에 연회색 블록을 얹고 있었다 — 앱의 규칙(**연회색 바탕 +
        // 흰 카드**)과 정확히 **반대**라 같은 내용인데 다른 앱처럼 보였다.
        // 시트도 하나의 화면이다: 바탕은 `canvas`, 내용은 흰 카드.
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.brSheet,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그랩 핸들 — AppSheet 의 것과 같은 치수·색·여백
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brPill,
              ),
            ),

            // ── 헤더 ───────────────────────────────────────────
            // 타입색(복숭아·하늘·세이지·라일락) 밴드를 폭 전체에 깔던 자리다.
            // 밴드는 연녹 한 가지로 통일하고, 타입색은 아이콘 타일에만 남겼다 —
            // 색이 날라야 하는 정보는 '무슨 루틴이냐' 하나뿐이다.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent,
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
                        Text('개체별 완료', style: AppTextStyles.heading),
                        const SizedBox(height: AppSpacing.xs),
                        Text(routine.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.mono(12, FontWeight.w700,
                            color: AppColors.brandTintInk),
                        children: [
                          TextSpan(text: '$_completedCount'),
                          TextSpan(text: ' / ${_pets.length}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── peek 캐러셀 ────────────────────────────────────
            // `PageView` 는 높이가 유한해야 한다. 한 장의 내용 길이가 개체마다
            // 다르므로(체중 칸·급여 아코디언) **장 높이를 고정하고 안에서
            // 스크롤**한다 — 장마다 시트 높이가 들썩이면 넘길 때마다 화면이 뛴다.
            // `Flexible` 로 감싸 키보드가 올라와 자리가 줄면 같이 줄어든다.
            Flexible(
              child: SizedBox(
                height: (media.size.height * 0.46).clamp(280.0, 460.0),
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
            ),

            // ── 푸터 ───────────────────────────────────────────
            _Footer(
              isLast: _isLast,
              canPrev: _idx > 0,
              onPrev: () => _go(_idx - 1),
              onNext: _handleNext,
              onFinish: _handleFinish,
            ),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl,
            AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개체 + 완료 버튼은 **한 덩어리**다 ("이 개체를 끝냈나").
            // 연회색 바탕 위의 흰 카드 — 홈 화면의 섹션들과 같은 규칙.
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecor.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: AppRadius.brMd,
                        ),
                        child: pet.imageUrl != null
                            ? ClipRRect(
                                borderRadius: AppRadius.brMd,
                                child: AppNetworkImage(pet.imageUrl,
                                    fit: BoxFit.cover,
                                    memWidth: 150,
                                    placeholder: const AppIcon(AppIcons.petLine,
                                        size: AppIconSize.md,
                                        color: AppColors.ink3)),
                              )
                            : const AppIcon(AppIcons.petLine,
                                size: AppIconSize.md, color: AppColors.ink3),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pet.petName,
                                style: AppTextStyles.subheading,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (pet.speciesName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(pet.speciesName,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 완료 알약 — 먹색(`primary`) 채움이었다. 검은 블록은
                      // '완료'보다 '잠김'으로 읽힌다. 홈 루틴 행의 완료 표시와
                      // 같은 연녹 알약을 쓴다.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: rec.done
                              ? AppColors.brandTint
                              : AppColors.bgAlt,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rec.done) ...[
                              const Icon(Icons.check,
                                  size: 13, color: AppColors.brandTintInk),
                              const SizedBox(width: 3),
                            ],
                            Text(rec.done ? '완료' : '대기',
                                style: AppTextStyles.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: rec.done
                                        ? AppColors.brandTintInk
                                        : AppColors.ink3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 주 동작. 손으로 그린 `GestureDetector` + `Container` 였고
                  // 채움색이 먹색이라 브랜드색 버튼이 쓰이는 다른 시트들과
                  // 혼자 달랐다. 테마 버튼을 그대로 쓴다(폭이 유한한 자리라
                  // `minimumSize` 의 무한 minWidth 가 문제되지 않는다).
                  SizedBox(
                    height: 48,
                    child: rec.done
                        ? OutlinedButton.icon(
                            onPressed: saving ? null : onUndo,
                            icon: const Icon(Icons.check_circle_outline,
                                size: AppIconSize.md),
                            label: const Text('완료 취소'),
                          )
                        : ElevatedButton.icon(
                            onPressed: saving ? null : onComplete,
                            icon: const Icon(Icons.check, size: AppIconSize.md),
                            label: const Text('이 개체 완료'),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    rec.done
                        ? '다시 누르면 완료가 취소돼요'
                        : isWeight
                            ? '몸무게를 적고 완료를 눌러주세요'
                            : '입력만 하고 넘기면 미완료로 저장돼요',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // 몸무게 입력 (WEIGHT 루틴 — 필수)
            // 라벨+입력칸이 바탕에 맨몸으로 떠 있었다. 아래 아코디언들과 같은
            // 층으로 보이게 흰 카드로 묶는다 — 다만 이건 접히지 않는다(필수).
            if (isWeight) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecor.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('몸무게 (g) *', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: rec.weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        rec.weight = v;
                        rec.dirty = true;
                        onChanged();
                      },
                      style: AppTextStyles.body,
                      decoration: AppInputStyles.textarea(hintText: '예: 52.5')
                          .copyWith(suffixText: 'g'),
                    ),
                  ],
                ),
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
                style: AppTextStyles.sub,
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
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _Footer({
    required this.isLast,
    required this.canPrev,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    // ⛔ 주 버튼 옆에 '취소'를 두지 않는다 — 시트는 핸들을 내리거나 바깥을 눌러
    //    닫는다. 여기 있던 '취소'는 '이전'과 뜻이 겹쳐 셋 중 뭘 누를지 멈칫했다.
    return Container(
      decoration: const BoxDecoration(
        // 바탕색은 시트와 같게 둔다 — 위쪽 선 하나로 이미 구분되고, 흰 띠를
        // 깔면 `AppSheet` 의 주 버튼 자리(바탕 그대로)와 모양이 갈린다.
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Row(
        children: [
          _FooterBtn(label: '이전', onTap: canPrev ? onPrev : null),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              // 7슬롯 주 버튼과 같은 52px — 시트마다 버튼 높이가 다르면
              // 같은 동작인데 다른 화면처럼 보인다.
              height: 52,
              child: isLast
                  ? ElevatedButton.icon(
                      onPressed: onFinish,
                      icon: const Icon(Icons.check, size: AppIconSize.sm),
                      label: const Text('종료'),
                    )
                  : OutlinedButton(
                      onPressed: onNext,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('다음'),
                          SizedBox(width: AppSpacing.xs),
                          AppIcon(AppIcons.chevronRight,
                              size: AppIconSize.sm, color: AppColors.ink2),
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
    // ⚠️ 앱 테마의 `minimumSize: Size.fromHeight(52)` 는 **minWidth 가 무한**이다
    // (`Size.fromHeight` 의 width 는 double.infinity). 그래서 테마를 그대로 쓰는
    // 버튼은 **폭이 유한한 자리에만** 놓을 수 있다 — `Row` 의 비(非)flex 자식처럼
    // 폭 제약이 무한한 자리에 두면 `BoxConstraints forces an infinite width` 로
    // 시트가 통째로 안 뜬다. 여기서는 minWidth 를 유한값으로 덮어쓴다.
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(76, 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      child: Text(label),
    );
  }
}
