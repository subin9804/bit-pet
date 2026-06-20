// FAB 기록 바텀시트 — 피딩 플로우 06 → 06b → 06c → 06d / 06e
// 단일 모달 시트 안에서 단계를 전환해 슬라이드업 애니메이션을 1회만 발생.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/step_dots.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../data/record_repository.dart';
import '../providers/record_provider.dart';
import '../providers/feed_provider.dart';
import 'widgets/feed_items_editor.dart';
import 'widgets/selected_pet_row.dart';

// ── 플로우 단계 ────────────────────────────────────────────────
enum _FabStep {
  chooseType, // 06  기록 종류 6그리드
  pickPets,   // 06b 개체 다중 선택
  feedChoice, // 06c BULK / PER-PET
  feedBulk,   // 06d 일괄 폼
  feedPerPet, // 06e 개별 탭 폼
  done,       // 완료
}

enum _FeedMode { bulk, perPet }

// 개체별 폼 상태
class _PerPetEntry {
  List<FeedFormData> items;
  bool filled;
  _PerPetEntry() : items = [], filled = false;
}

// ── 6 기록 종류 정의 ──────────────────────────────────────────
class _RecordType {
  final String id;
  final String ko;
  final String en;
  final String ex;
  final IconData icon;
  final Color color;
  const _RecordType(this.id, this.ko, this.en, this.ex, this.icon, this.color);
}

const _recordTypes = [
  _RecordType('feed',  '피딩',   'FEEDING', '먹이·시간·양',     Icons.restaurant_outlined,       AppColors.feedBand),
  _RecordType('scale', '몸무게', 'WEIGHT',  '측정 기록',        Icons.monitor_weight_outlined,   AppColors.petSage),
  _RecordType('clean', '청소',   'CLEAN',   '바닥재·환기',       Icons.cleaning_services_outlined, AppColors.petSky),
  _RecordType('note',  '메모',   'NOTE',    '병원·관찰·증상',    Icons.note_alt_outlined,          AppColors.petLilac),
  _RecordType('mate',  '메이팅', 'MATING',  '합방·관찰',        Icons.favorite_outline,           AppColors.petCoral),
  _RecordType('lay',   '산란',   'LAYING',  '알 수·인큐베이션', Icons.egg_outlined,               AppColors.petButter),
];

// ── 메인 위젯 ──────────────────────────────────────────────────
class FabRecordSheet extends ConsumerStatefulWidget {
  const FabRecordSheet({super.key});

  @override
  ConsumerState<FabRecordSheet> createState() => _FabRecordSheetState();
}

class _FabRecordSheetState extends ConsumerState<FabRecordSheet> {
  _FabStep _step = _FabStep.chooseType;
  String   _typeId = '';          // 선택된 기록 종류
  final Set<int> _selectedPetIds = {};

  // 06c
  _FeedMode _feedMode = _FeedMode.bulk;

  // 06d 일괄 폼
  List<FeedFormData> _bulkItems = [];

  // 06e 개별 폼
  final Map<int, _PerPetEntry> _perPetForms = {};
  int _activePerPetIdx = 0;

  // 저장
  bool _saving = false;
  int  _savedCount = 0;

  // ── 헬퍼 ────────────────────────────────────────────────────
  List<Pet> _selectedPets(AsyncValue<List<Pet>> petsAsync) {
    final all = petsAsync.whenOrNull(data: (l) => l) ?? [];
    final order = _selectedPetIds.toList();
    return order.map((id) => all.firstWhere(
      (p) => p.id == id,
      orElse: () => all.first,
    )).where((p) => _selectedPetIds.contains(p.id)).toList();
  }

  void _onTypeSelected(String typeId) {
    setState(() {
      _typeId = typeId;
      _step   = _FabStep.pickPets;
    });
  }

  void _applyPets(Set<int> ids) {
    setState(() {
      _selectedPetIds
        ..clear()
        ..addAll(ids);
      if (_typeId == 'feed') {
        if (ids.length <= 1) {
          // 1마리 → 06c 건너뛰고 06d 직행
          _step = _FabStep.feedBulk;
        } else {
          _step = _FabStep.feedChoice;
        }
      } else {
        // 피딩 이외 종류 → 간단 폼(추후 확장)
        _step = _FabStep.feedBulk;
      }
    });
  }

  void _initPerPetForms(List<Pet> pets) {
    for (final p in pets) {
      _perPetForms.putIfAbsent(p.id, () => _PerPetEntry());
    }
  }

  int get _filledCount =>
      _perPetForms.values.where((e) => e.filled).length;

  void _markFilled(int petId, bool val, List<Pet> pets) {
    setState(() {
      _perPetForms[petId]!.filled = val;
      if (val) {
        // 다음 미완료 개체로 자동 이동
        final nextIdx = pets.indexWhere(
            (p) => !(_perPetForms[p.id]?.filled ?? false) && p.id != petId);
        if (nextIdx != -1) _activePerPetIdx = nextIdx;
      }
    });
  }

  // ── 저장 ─────────────────────────────────────────────────────
  Future<void> _saveBulk(List<Pet> pets) async {
    if (_bulkItems.isEmpty) {
      showToast(context, '먹이를 목록에 추가해 주세요', type: ToastType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      final now  = DateTime.now();
      for (final pet in pets) {
        for (final item in _bulkItems) {
          await repo.addFeeding(pet.id, item.toApiMap(fedAt: now));
        }
        ref.invalidate(feedSessionsProvider(pet.id));
        ref.invalidate(petDetailProvider(pet.id));
      }
      setState(() {
        _savedCount = pets.length;
        _step = _FabStep.done;
      });
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePerPet(List<Pet> pets) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      final now  = DateTime.now();
      int count = 0;
      for (final pet in pets) {
        final entry = _perPetForms[pet.id];
        if (entry == null || !entry.filled || entry.items.isEmpty) continue;
        for (final item in entry.items) {
          await repo.addFeeding(pet.id, item.toApiMap(fedAt: now));
        }
        ref.invalidate(feedSessionsProvider(pet.id));
        ref.invalidate(petDetailProvider(pet.id));
        count++;
      }
      setState(() {
        _savedCount = count;
        _step = _FabStep.done;
      });
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 뒤로 ─────────────────────────────────────────────────────
  void _goBack() {
    setState(() {
      _step = switch (_step) {
        _FabStep.pickPets   => _FabStep.chooseType,
        _FabStep.feedChoice => _FabStep.pickPets,
        _FabStep.feedBulk   =>
            _selectedPetIds.length > 1 ? _FabStep.feedChoice : _FabStep.pickPets,
        _FabStep.feedPerPet => _FabStep.feedChoice,
        _                   => _FabStep.chooseType,
      };
    });
  }

  // ── 빌드 ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final isFormStep = _step == _FabStep.feedBulk || _step == _FabStep.feedPerPet;
    final screenH = MediaQuery.of(context).size.height;

    final sheet = Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: isFormStep ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // 그랩 핸들
          Container(
            width: 44, height: 4,
            margin: const EdgeInsets.fromLTRB(0, 8, 0, 10),
            decoration: BoxDecoration(
              color: AppColors.paleLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 단계별 본문
          Flexible(
            child: _buildStep(petsAsync),
          ),
        ],
      ),
    );

    if (isFormStep) {
      return SizedBox(height: screenH * 0.85, child: sheet);
    }
    return sheet;
  }

  Widget _buildStep(AsyncValue<List<Pet>> petsAsync) {
    return switch (_step) {
      _FabStep.chooseType => _buildChooseType(petsAsync),
      _FabStep.pickPets   => _buildPickPets(),
      _FabStep.feedChoice => _buildFeedChoice(petsAsync),
      _FabStep.feedBulk   => _buildFeedBulk(petsAsync),
      _FabStep.feedPerPet => _buildFeedPerPet(petsAsync),
      _FabStep.done       => _buildDone(),
    };
  }

  // ── 06 · 기록 종류 선택 (BFinalFabSheetV2 — 컴팩트 3×2) ────────
  Widget _buildChooseType(AsyncValue<List<Pet>> petsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text('NEW RECORD',
              style: AppTextStyles.mono(11, FontWeight.w700,
                  color: AppColors.paleInk2)),
          const SizedBox(height: 3),
          const Text('무엇을 기록할까요?',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.4)),
          const SizedBox(height: 3),
          Text('종류를 고르면 대상 개체를 선택해요',
              style: TextStyle(fontSize: 11.5, color: AppColors.paleInk3,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),

          // 기록 종류 — 3×2 컴팩트 그리드
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: _recordTypes.map((rt) => _CompactTypeCard(
              type: rt,
              onTap: () => _onTypeSelected(rt.id),
            )).toList(),
          ),

          // 구분선
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.paleLineSoft, height: 1),
          ),

          // 개체 추가 버튼
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              // 개체 등록으로 이동 — 라우터로 push 불가(context 소멸 후)하므로 pop 후 외부에서 처리
              // Navigator.of(context).pop('/pets/new'); 대신 토스트 안내
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paleBgAlt,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.paleLine),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('개체 추가',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.primary)),
                        const SizedBox(height: 1),
                        Text('새로운 반려동물 등록',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.paleInk2,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.paleInk2),
                ],
              ),
            ),
          ),

          // 취소
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text('취소',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.paleInk2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 06b · 대상 개체 선택 (인라인) ─────────────────────────────
  Widget _buildPickPets() {
    return _PetPickerContent(
      preSelected: _selectedPetIds,
      onApply: (ids) => _applyPets(ids),
      onBack: _goBack,
    );
  }

  // ── 06c · 일괄/개별 선택 ──────────────────────────────────────
  Widget _buildFeedChoice(AsyncValue<List<Pet>> petsAsync) {
    final pets = _selectedPets(petsAsync);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('NEW FEEDING',
                    style: AppTextStyles.mono(11, FontWeight.w700,
                        color: AppColors.paleInk2)),
                const SizedBox(width: 8),
                const StepDots(step: 2),
              ]),
              const SizedBox(height: 6),
              const Text('어떻게 입력할까요?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('여러 개체를 선택했어요. 같은 정보로 한 번에 기록하거나\n개체별로 다르게 작성할 수 있어요',
                  style: TextStyle(fontSize: 12, color: AppColors.paleInk2)),
            ],
          ),
        ),
        if (pets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: SelectedPetRow(pets: pets),
          ),
        // 선택 카드
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                _ChoiceCard(
                  icon: Icons.grid_view_outlined,
                  en: 'BULK',
                  title: '일괄 입력',
                  desc: '선택한 개체 모두에게 같은 정보로 기록할 거예요',
                  examples: const ['귀뚜라미 5마리', '같은 시각 · 같은 메모'],
                  recommended: true,
                  selected: _feedMode == _FeedMode.bulk,
                  onTap: () => setState(() => _feedMode = _FeedMode.bulk),
                ),
                const SizedBox(height: 10),
                _ChoiceCard(
                  icon: Icons.view_list_outlined,
                  en: 'PER-PET',
                  title: '개별 입력',
                  desc: '개체마다 다른 양·메모를 따로 작성할 거예요',
                  examples: const ['고도 5마리', '삼식 3마리', '베타 1마리'],
                  selected: _feedMode == _FeedMode.perPet,
                  onTap: () => setState(() => _feedMode = _FeedMode.perPet),
                ),
              ],
            ),
          ),
        ),
        // 푸터
        _Footer(
          onBack: _goBack,
          nextLabel: '다음',
          onNext: () => setState(() => _step = _feedMode == _FeedMode.bulk
              ? _FabStep.feedBulk
              : _FabStep.feedPerPet),
        ),
      ],
    );
  }

  // ── 06d · 일괄 폼 ────────────────────────────────────────────
  Widget _buildFeedBulk(AsyncValue<List<Pet>> petsAsync) {
    final pets = _selectedPets(petsAsync);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  _typeId == 'feed' ? 'FEEDING · BULK' : _typeId.toUpperCase(),
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.paleInk2),
                ),
                const SizedBox(width: 8),
                const StepDots(step: 3),
              ]),
              const SizedBox(height: 6),
              const Text('피딩 기록',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: -0.4)),
            ],
          ),
        ),
        if (pets.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 2),
            child: SelectedPetRow(pets: pets),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            child: Text(
              '아래 급여 목록을 모든 개체에 동일하게 기록해요',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: AppColors.paleInk2),
            ),
          ),
        ],
        // 본문 (스크롤)
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
            child: FeedItemsEditor(
              items: _bulkItems,
              onChanged: (list) => setState(() => _bulkItems = list),
            ),
          ),
        ),
        // 푸터
        _Footer(
          onBack: _goBack,
          nextLabel: '완료',
          nextIcon: Icons.check,
          nextEnabled: _bulkItems.isNotEmpty && !_saving,
          nextBadge: _bulkItems.isNotEmpty ? '${_bulkItems.length}종 저장' : null,
          loading: _saving,
          onNext: () => _saveBulk(pets),
        ),
      ],
    );
  }

  // ── 06e · 개별 탭 폼 ─────────────────────────────────────────
  Widget _buildFeedPerPet(AsyncValue<List<Pet>> petsAsync) {
    final pets = _selectedPets(petsAsync);
    if (pets.isEmpty) return const SizedBox.shrink();
    _initPerPetForms(pets);

    final activePet = pets[_activePerPetIdx];
    final entry     = _perPetForms[activePet.id]!;
    final pale      = PalePalette.pale(
        PalePalette.keyFromHex(activePet.colorCode));
    final paleInk   = PalePalette.ink(
        PalePalette.keyFromHex(activePet.colorCode));
    final allFilled = _filledCount == pets.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('FEEDING · PER-PET',
                          style: AppTextStyles.mono(11, FontWeight.w700,
                              color: AppColors.paleInk2)),
                      const SizedBox(width: 8),
                      const StepDots(step: 3),
                    ]),
                    const SizedBox(height: 6),
                    const Text('피딩 기록',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppColors.primary, letterSpacing: -0.4)),
                  ],
                ),
              ),
              // 완료 카운트 pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allFilled ? AppColors.feedBand : AppColors.card,
                  border: allFilled
                      ? null
                      : Border.all(color: AppColors.paleLine),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_filledCount / ${pets.length}',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.paleInk2),
                ),
              ),
            ],
          ),
        ),

        // 개체 탭 (가로 스크롤)
        Container(
          height: 46,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.paleLineSoft)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final p       = pets[i];
              final active  = i == _activePerPetIdx;
              final pKey    = PalePalette.keyFromHex(p.colorCode);
              final pPale   = PalePalette.pale(pKey);
              final pInk    = PalePalette.ink(pKey);
              final isFilled = _perPetForms[p.id]?.filled ?? false;
              return GestureDetector(
                onTap: () => setState(() => _activePerPetIdx = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? pPale : AppColors.card,
                    border: Border.all(
                        color: active ? pInk : AppColors.paleLine,
                        width: active ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.55)
                              : pPale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.pets, size: 12,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(width: 6),
                      isFilled
                          ? Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  size: 9, color: Colors.white))
                          : Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.paleInk3,
                                      width: 1.5,
                                      style: BorderStyle.solid))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 본문 (스크롤)
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
            child: Column(
              children: [
                // 개체 히어로
                Container(
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.pets, size: 22,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activePet.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(
                              '${activePet.speciesName}${activePet.latestWeightG != null ? ' · ${activePet.latestWeightG!.toStringAsFixed(0)}g' : ''}',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.paleInk2),
                            ),
                          ],
                        ),
                      ),
                      if (_activePerPetIdx > 0)
                        GestureDetector(
                          onTap: () => setState(() => _activePerPetIdx--),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.chevron_left,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      if (_activePerPetIdx < pets.length - 1) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _activePerPetIdx++),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // FeedItemsEditor (개체별 — 목록에 추가)
                FeedItemsEditor(
                  items: entry.items,
                  bandColor: pale,
                  onChanged: (list) => setState(() => entry.items = list),
                ),
                const SizedBox(height: 18),

                // 완료 / 저장됨 액션
                if (entry.filled)
                  _SavedBanner(
                    petName: activePet.name,
                    pale: pale,
                    paleInk: paleInk,
                    onUndo: () => setState(() {
                      _perPetForms[activePet.id]!.filled = false;
                    }),
                  )
                else
                  GestureDetector(
                    onTap: entry.items.isNotEmpty
                        ? () => _markFilled(activePet.id, true, pets)
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry.items.isNotEmpty
                            ? AppColors.primary
                            : AppColors.paleLine,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check,
                              color: entry.items.isNotEmpty
                                  ? AppColors.paleBg
                                  : AppColors.paleInk3,
                              size: 16),
                          const SizedBox(width: 8),
                          Text(
                            entry.items.isEmpty
                                ? '${activePet.name} 완료'
                                : '${activePet.name} 완료 (${entry.items.length}종)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: entry.items.isNotEmpty
                                    ? AppColors.paleBg
                                    : AppColors.paleInk3),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // 이전/다음 개체 네비게이션
                if (pets.length > 1)
                  Row(
                    children: [
                      if (_activePerPetIdx > 0) ...[
                        Expanded(
                          flex: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _activePerPetIdx--),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                border: Border.all(color: AppColors.paleLine),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chevron_left,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('이전',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_activePerPetIdx < pets.length - 1) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activePerPetIdx++),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                border: Border.all(
                                    color: AppColors.paleLine, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: PalePalette.pale(PalePalette
                                          .keyFromHex(pets[_activePerPetIdx + 1].colorCode)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.pets, size: 12,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '다음 · ${pets[_activePerPetIdx + 1].name}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.primary),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      size: 16, color: AppColors.primary),
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
        ),

        // 푸터
        _Footer(
          onBack: _goBack,
          nextLabel: '닫기',
          nextBadge: '$_filledCount건 저장됨',
          onNext: _filledCount > 0
              ? () => _savePerPet(pets)
              : () => Navigator.of(context).pop(),
          loading: _saving,
        ),
      ],
    );
  }

  // ── 완료 화면 ──────────────────────────────────────────────────
  Widget _buildDone() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 32, 22, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
                color: AppColors.feedBand, shape: BoxShape.circle),
            child: const Icon(Icons.check,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('기록 완료!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          Text('$_savedCount마리의 급여 기록이 저장되었어요',
              style: TextStyle(fontSize: 13, color: AppColors.paleInk2)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('닫기',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.paleBg)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 06b 개체 선택 컨텐츠 (인라인 위젯) ─────────────────────────
class _PetPickerContent extends ConsumerStatefulWidget {
  final Set<int> preSelected;
  final ValueChanged<Set<int>> onApply;
  final VoidCallback onBack;

  const _PetPickerContent({
    required this.preSelected,
    required this.onApply,
    required this.onBack,
  });

  @override
  ConsumerState<_PetPickerContent> createState() => _PetPickerContentState();
}

class _PetPickerContentState extends ConsumerState<_PetPickerContent> {
  late Set<int> _selected;
  String _query  = '';
  String _filter = 'all';

  static const _filters = [
    ('all', '전체'), ('gecko', '게코'), ('snake', '뱀'), ('lizard', '도마뱀'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.preSelected);
  }

  bool _matchFilter(Pet p) {
    final sp = p.speciesName.toLowerCase();
    return switch (_filter) {
      'gecko'  => sp.contains('게코'),
      'snake'  => sp.contains('파이톤') || sp.contains('스네이크') ||
                  sp.contains('보아') || sp.contains('콘'),
      'lizard' => sp.contains('드래곤') || sp.contains('도마뱀') ||
                  sp.contains('스킨크') || sp.contains('이구아나'),
      _        => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final allPets   = petsAsync.whenOrNull(data: (l) => l) ?? <Pet>[];
    final q         = _query.toLowerCase();
    final filtered  = allPets.where((p) =>
        _matchFilter(p) &&
        (q.isEmpty || p.name.toLowerCase().contains(q) ||
            p.speciesName.toLowerCase().contains(q))).toList();

    final allSelected  = filtered.isNotEmpty && filtered.every((p) => _selected.contains(p.id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT TARGET',
                        style: AppTextStyles.mono(11, FontWeight.w700,
                            color: AppColors.paleInk2)),
                    const SizedBox(height: 4),
                    const Text('대상 개체 선택',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppColors.primary, letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Text('여러 개체에 같은 기록을 한 번에 남길 수 있어요',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.paleInk2)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _selected.isNotEmpty
                      ? AppColors.feedBand
                      : AppColors.card,
                  border: _selected.isNotEmpty
                      ? null
                      : Border.all(color: AppColors.paleLine),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_selected.length} / ${allPets.length}',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: _selected.isNotEmpty
                          ? AppColors.primary
                          : AppColors.paleInk3),
                ),
              ),
            ],
          ),
        ),

        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 18, color: AppColors.paleInk2),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration.collapsed(
                      hintText: '이름 또는 종 검색…',
                      hintStyle: TextStyle(color: AppColors.paleInk3),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _query = ''),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.paleInk3),
                  ),
              ],
            ),
          ),
        ),

        // 종 필터 칩
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            children: _filters.map((f) {
              final active = _filter == f.$1;
              final count  = allPets.where((p) => switch (f.$1) {
                'gecko'  => p.speciesName.toLowerCase().contains('게코'),
                'snake'  => p.speciesName.toLowerCase().contains('파이톤') ||
                            p.speciesName.toLowerCase().contains('스네이크') ||
                            p.speciesName.toLowerCase().contains('콘'),
                'lizard' => p.speciesName.toLowerCase().contains('드래곤') ||
                            p.speciesName.toLowerCase().contains('도마뱀'),
                _        => true,
              }).length;
              return GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.card,
                    border: active
                        ? null
                        : Border.all(color: AppColors.paleLine),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Text(f.$2,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.paleBg
                                  : AppColors.primary)),
                      const SizedBox(width: 5),
                      Text('$count',
                          style: AppTextStyles.mono(10, FontWeight.w700,
                              color: active
                                  ? AppColors.paleBg.withValues(alpha: 0.6)
                                  : AppColors.paleInk3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // 전체선택/해제 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(
              top:    BorderSide(color: AppColors.paleLineSoft),
              bottom: BorderSide(color: AppColors.paleLineSoft),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${filtered.length}마리 표시 중',
                style: AppTextStyles.mono(11, FontWeight.w700,
                    color: AppColors.paleInk2),
              ),
              const Spacer(),
              _SelectBarBtn(
                icon: Icons.check,
                label: '전체선택',
                disabled: allSelected,
                onTap: () => setState(() {
                  for (final p in filtered) _selected.add(p.id);
                }),
              ),
              const SizedBox(width: 6),
              _SelectBarBtn(
                icon: Icons.close,
                label: '전체해제',
                disabled: _selected.isEmpty,
                onTap: () => setState(() => _selected.clear()),
              ),
            ],
          ),
        ),

        // 개체 3열 그리드
        Flexible(
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('일치하는 개체가 없어요',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.paleInk3)),
                  ),
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.78,
                  children: filtered.map((p) {
                    final isOn  = _selected.contains(p.id);
                    final key   = PalePalette.keyFromHex(p.colorCode);
                    final pale  = PalePalette.pale(key);
                    final pInk  = PalePalette.ink(key);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isOn) _selected.remove(p.id);
                        else      _selected.add(p.id);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: isOn ? pale : AppColors.card,
                          border: Border.all(
                              color: isOn ? pInk : AppColors.paleLine,
                              width: isOn ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                        child: Column(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: isOn
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : pale,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.pets, size: 24,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(p.speciesName,
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.paleInk2,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${p.gender == 'MALE' ? '♂' : p.gender == 'FEMALE' ? '♀' : '?'}'
                              '${p.latestWeightG != null ? ' · ${p.latestWeightG!.toStringAsFixed(0)}g' : ''}',
                              style: AppTextStyles.mono(9, FontWeight.w700,
                                  color: isOn
                                      ? AppColors.paleInk2
                                      : AppColors.paleInk3),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),

        // 푸터
        _Footer(
          onBack: widget.onBack,
          nextLabel: '적용',
          nextBadge: _selected.isNotEmpty ? '${_selected.length}마리' : null,
          nextEnabled: _selected.isNotEmpty,
          onNext: () => widget.onApply(Set.from(_selected)),
        ),
      ],
    );
  }
}

// ── 컴팩트 기록 종류 타일 (3×2, 아이콘 + 이름만) ──────────────────
class _CompactTypeCard extends StatelessWidget {
  final _RecordType type;
  final VoidCallback onTap;

  const _CompactTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: type.color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(type.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 7),
            Text(type.ko,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.primary,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

// ── 선택 카드 (06c BULK / PER-PET) ────────────────────────────
class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String en;
  final String title;
  final String desc;
  final List<String> examples;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.en,
    required this.title,
    required this.desc,
    required this.examples,
    this.recommended = false,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.paleLine,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.feedBand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(en,
                          style: AppTextStyles.mono(9, FontWeight.w700,
                              color: AppColors.paleInk2)),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.feedBand,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('RECOMMENDED',
                              style: AppTextStyles.mono(9, FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.primary, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.paleInk2,
                          height: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: examples.map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.paleBgAlt,
                        border: Border.all(color: AppColors.paleLineSoft),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(e,
                          style: AppTextStyles.mono(10, FontWeight.w700,
                              color: AppColors.paleInk3)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.paleInk3),
          ],
        ),
      ),
    );
  }
}

// ── 저장됨 배너 (06e) ──────────────────────────────────────────
class _SavedBanner extends StatelessWidget {
  final String petName;
  final Color pale;
  final Color paleInk;
  final VoidCallback onUndo;

  const _SavedBanner({
    required this.petName,
    required this.pale,
    required this.paleInk,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pale,
        border: Border.all(color: paleInk, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: paleInk, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$petName · 저장됨',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('수정하려면 미완료로 되돌린 뒤 다시 완료하세요',
                    style: TextStyle(fontSize: 11, color: AppColors.paleInk2)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUndo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('미완료',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 푸터 (뒤로 / 다음) ────────────────────────────────────
class _Footer extends StatelessWidget {
  final VoidCallback? onBack;
  final String nextLabel;
  final IconData? nextIcon;
  final String? nextBadge;
  final bool nextEnabled;
  final bool loading;
  final VoidCallback? onNext;

  const _Footer({
    this.onBack,
    required this.nextLabel,
    this.nextIcon,
    this.nextBadge,
    this.nextEnabled = true,
    this.loading = false,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          22, 12, 22, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.paleLine),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('뒤로',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: GestureDetector(
              onTap: nextEnabled && !loading ? onNext : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nextEnabled ? AppColors.primary : AppColors.paleLine,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (nextIcon != null) ...[
                            Icon(nextIcon,
                                size: 16,
                                color: nextEnabled
                                    ? AppColors.paleBg
                                    : AppColors.paleInk3),
                            const SizedBox(width: 8),
                          ],
                          Text(nextLabel,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: nextEnabled
                                      ? AppColors.paleBg
                                      : AppColors.paleInk3)),
                          if (nextBadge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: nextEnabled
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(nextBadge!,
                                  style: AppTextStyles.mono(11, FontWeight.w700,
                                      color: nextEnabled
                                          ? AppColors.paleBg
                                          : AppColors.paleInk3)),
                            ),
                          ],
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

// ── 전체선택/해제 버튼 ─────────────────────────────────────────
class _SelectBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool disabled;
  final VoidCallback onTap;

  const _SelectBarBtn({
    required this.icon,
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paleBg,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: disabled ? AppColors.paleInk3 : AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: disabled ? AppColors.paleInk3 : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
