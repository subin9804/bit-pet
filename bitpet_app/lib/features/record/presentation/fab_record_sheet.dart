// FAB 기록 바텀시트 — 급여 플로우 06 → 06b → 06c → 06d / 06e
// 단일 모달 시트 안에서 단계를 전환해 슬라이드업 애니메이션을 1회만 발생.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pet_avatar.dart';
import '../../../core/widgets/step_dots.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/providers/pet_provider.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';
import '../providers/record_provider.dart';
import '../providers/record_invalidation.dart';
import 'widgets/feed_items_editor.dart';
import 'widgets/selected_pet_row.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/sex_icon.dart';

// ── 플로우 단계 ────────────────────────────────────────────────
enum _FabStep {
  chooseType, // 06  기록 종류 6그리드
  pickPets,   // 06b 개체 다중 선택
  feedChoice, // 06c BULK / PER-PET
  feedBulk,   // 06d 일괄 폼
  feedPerPet, // 06e 개별 탭 폼
  simpleForm, // scale / clean / note / mate / lay 폼
  done,       // 완료
}

enum _FeedMode { bulk, perPet }

// 개체별 폼 상태
class _PerPetEntry {
  List<FeedFormData> items;
  bool filled;
  String memo;
  _PerPetEntry() : items = [], filled = false, memo = '';
}

// ── 6 기록 종류 정의 ──────────────────────────────────────────
class _RecordType {
  final String id;
  final String ko;
  final String en;
  final String ex;
  /// [AppIcons] 의 SVG 경로. `en` 이 CLEAN/NOTE 라 코드로 되짚을 수 없어 직접 건다.
  final String icon;
  final Color color;
  const _RecordType(this.id, this.ko, this.en, this.ex, this.icon, this.color);
}

const _recordTypes = [
  _RecordType('feed',  '급여',   'FEEDING', '종류·시간·양',     AppIcons.feeding,  AppColors.catFeed),
  _RecordType('scale', '몸무게', 'WEIGHT',  '측정 기록',        AppIcons.weight,   AppColors.catWeight),
  _RecordType('clean', '청소',   'CLEAN',   '바닥재·환기',       AppIcons.cleaning, AppColors.catClean),
  _RecordType('note',  '메모',   'NOTE',    '병원·관찰·증상',    AppIcons.memo,     AppColors.catMemo),
  _RecordType('mate',  '메이팅', 'MATING',  '합방·관찰',        AppIcons.mating,   AppColors.catMating),
  _RecordType('lay',   '산란',   'LAYING',  '알 수·인큐베이션', AppIcons.laying,   AppColors.catLaying),
];

// ── 메인 위젯 ──────────────────────────────────────────────────
class FabRecordSheet extends ConsumerStatefulWidget {
  /// 미리 정해진 기록 종류 ('feed' / 'scale' / ...). 지정하면 06 종류 선택을 건너뛴다.
  final String? initialTypeId;

  /// 대상 개체가 이미 정해진 경우. **06b 개체 선택 단계가 통째로 사라진다.**
  /// * 개체 상세 FAB — 개체만 고정, 종류 선택부터 시작
  /// * NFC 태그 스캔 — [initialTypeId]까지 함께 넘어와 폼으로 직행
  final int? initialPetId;

  const FabRecordSheet({super.key, this.initialTypeId, this.initialPetId});

  @override
  ConsumerState<FabRecordSheet> createState() => _FabRecordSheetState();
}

class _FabRecordSheetState extends ConsumerState<FabRecordSheet> {
  _FabStep _step = _FabStep.chooseType;
  String   _typeId = '';          // 선택된 기록 종류
  final Set<int> _selectedPetIds = {};

  /// 기록 날짜 — 기본은 **오늘**. 지난 날짜를 고를 수 있다(어제 급여를 깜빡하고
  /// 다음 날 적는 일이 흔하다). 시트 전체가 한 날짜를 공유한다 — 한 번의 기록
  /// 작업은 한 시점의 일이고, 개체마다 날짜가 갈리는 입력은 쓸 일이 없다.
  /// ⛔ 미래는 못 고른다 — 전부 '이미 일어난 일'의 기록이다.
  DateTime _recordDate = DateTime.now();

  bool get _isTodaySelected {
    final now = DateTime.now();
    return _recordDate.year == now.year &&
        _recordDate.month == now.month &&
        _recordDate.day == now.day;
  }

  /// 저장에 실어 보내는 시각. 오늘이면 **지금**, 지난 날짜면 **정오**다.
  /// 지난 기록의 시·분에는 의미가 없는데, 지금 시각을 그대로 붙이면 자정 전후에
  /// 적을 때 UTC 로 바뀌면서 날짜가 하루 밀려 캘린더에 다른 날로 찍힌다.
  DateTime get _recordAt => _isTodaySelected
      ? DateTime.now()
      : DateTime(_recordDate.year, _recordDate.month, _recordDate.day, 12);

  /// 기록 종류별 날짜 레이블 — '날짜' 하나로 두면 무슨 날짜인지가 애매하다.
  String get _dateLabel => switch (_typeId) {
        'feed'  => '급여일',
        'scale' => '측정일',
        'clean' => '청소일',
        'mate'  => '합사일',
        'lay'   => '산란일',
        _       => '기록일',
      };

  Future<void> _pickRecordDate() async {
    final today  = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      helpText: '$_dateLabel 선택',
    );
    if (picked != null && mounted) setState(() => _recordDate = picked);
  }

  /// 개체가 밖에서 정해져 들어온 시트인가 (개체 선택 단계를 건너뛴다)
  bool get _petLocked => widget.initialPetId != null;

  @override
  void initState() {
    super.initState();
    final petId = widget.initialPetId;
    if (petId != null) _selectedPetIds.add(petId);

    final type = widget.initialTypeId;
    if (type == null || !_recordTypes.any((t) => t.id == type)) return;
    _typeId = type;
    // 종류까지 정해졌으면 폼으로 직행 (개체 1마리 = 급여는 06d, 나머지는 단일 폼)
    _step = petId == null
        ? _FabStep.pickPets
        : (type == 'feed' ? _FabStep.feedBulk : _FabStep.simpleForm);
  }

  // 06c
  _FeedMode _feedMode = _FeedMode.bulk;

  // 06d 일괄 폼
  List<FeedFormData> _bulkItems = [];
  final _bulkMemoCtrl = TextEditingController();

  // 06e 개별 폼
  final Map<int, _PerPetEntry> _perPetForms = {};
  final Map<int, TextEditingController> _perPetMemoCtrl = {};
  int _activePerPetIdx = 0;

  // simpleForm 공통
  final _simpleMemoCtrl = TextEditingController();
  // scale
  final _weightCtrl = TextEditingController();
  // clean
  String? _cleaningType; // 'FULL' | 'PARTIAL' | 'WATER_CHANGE'
  // note — 분류 단일 선택(라디오). null이면 미분류.
  String? _memoTag; // 'VET' | 'SHED' | 'POOP' | 'BEHAVIOR' | 'ETC'
  // mate
  bool _partnerExternal = false;
  // 합사 결과. **null(결과 미정)이 기본이고 그게 정상 상태다** — FAB 은 합사 직후
  // 그 자리에서 찍는 기록이라 성공 여부는 대개 나중에 안다. 기본을 '성공'으로
  // 두면 아무도 안 고친 기록이 전부 성공으로 쌓인다.
  bool? _mateSuccess;
  Pet? _partnerPet;       // 내 개체 (인터널)
  Pet? _searchedPartner;  // 검색으로 찾은 외부 개체
  bool _searchLoading = false;
  String? _searchError;
  final _partnerExtCtrl = TextEditingController(); // 일련번호 입력
  // lay
  final _eggTotalCtrl   = TextEditingController();
  final _eggFertileCtrl = TextEditingController();

  // 저장
  bool _saving = false;
  int  _savedCount = 0;

  // ── 헬퍼 ────────────────────────────────────────────────────
  List<Pet> _selectedPets(AsyncValue<List<Pet>> petsAsync) {
    final all = petsAsync.whenOrNull(data: (l) => l) ?? [];
    // 개체 목록이 아직 로딩 중일 수 있다 (딥링크로 폼 단계부터 열리는 경우)
    if (all.isEmpty) return [];
    final order = _selectedPetIds.toList();
    return order.map((id) => all.firstWhere(
      (p) => p.id == id,
      orElse: () => all.first,
    )).where((p) => _selectedPetIds.contains(p.id)).toList();
  }

  void _onTypeSelected(String typeId) {
    setState(() {
      _typeId = typeId;
      // 개체가 이미 정해진 시트면 개체 선택을 건너뛰고 바로 폼으로
      _step = _petLocked
          ? (typeId == 'feed' ? _FabStep.feedBulk : _FabStep.simpleForm)
          : _FabStep.pickPets;
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
        _step = _FabStep.simpleForm;
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
    if (pets.isEmpty) {
      showToast(context, '개체 정보를 불러오는 중이에요', type: ToastType.warning);
      return;
    }
    if (_bulkItems.isEmpty) {
      showToast(context, '급여를 목록에 추가해 주세요', type: ToastType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo     = ref.read(recordRepositoryProvider);
      final now      = _recordAt;
      final bulkMemo = _bulkMemoCtrl.text.trim();
      for (final pet in pets) {
        for (final item in _bulkItems) {
          final apiItem = bulkMemo.isNotEmpty ? item.copyWith(memo: bulkMemo) : item;
          await repo.addFeeding(pet.id, apiItem.toApiMap(fedAt: now));
        }
        invalidatePetRecords(ref, pet.id);
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
      final now  = _recordAt;
      int count = 0;
      for (final pet in pets) {
        final entry = _perPetForms[pet.id];
        if (entry == null || !entry.filled || entry.items.isEmpty) continue;
        final petMemo = entry.memo.trim();
        for (final item in entry.items) {
          final apiItem = petMemo.isNotEmpty ? item.copyWith(memo: petMemo) : item;
          await repo.addFeeding(pet.id, apiItem.toApiMap(fedAt: now));
        }
        invalidatePetRecords(ref, pet.id);
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
  /// 딥링크로 폼 단계부터 열린 시트는 그 첫 화면에서 뒤로 = 시트 닫기.
  /// (개체도 종류도 이미 정해져 있어 돌아갈 앞 단계가 없다)
  bool get _isEntryStep =>
      _petLocked &&
      widget.initialTypeId != null &&
      (_step == _FabStep.feedBulk || _step == _FabStep.simpleForm);

  void _goBack() {
    if (_isEntryStep) {
      Navigator.of(context).pop();
      return;
    }
    // 개체가 고정된 시트에는 개체 선택 단계가 없으므로 종류 선택으로 되돌아간다
    final afterForm = _petLocked ? _FabStep.chooseType : _FabStep.pickPets;
    setState(() {
      _step = switch (_step) {
        _FabStep.pickPets   => _FabStep.chooseType,
        _FabStep.feedChoice => _FabStep.pickPets,
        _FabStep.feedBulk   =>
            _selectedPetIds.length > 1 ? _FabStep.feedChoice : afterForm,
        _FabStep.feedPerPet => _FabStep.feedChoice,
        _FabStep.simpleForm => afterForm,
        _                   => _FabStep.chooseType,
      };
    });
  }

  @override
  void dispose() {
    _bulkMemoCtrl.dispose();
    for (final c in _perPetMemoCtrl.values) c.dispose();
    _simpleMemoCtrl.dispose();
    _weightCtrl.dispose();
    _partnerExtCtrl.dispose();
    _eggTotalCtrl.dispose();
    _eggFertileCtrl.dispose();
    super.dispose();
  }

  // ── 빌드 ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final media = MediaQuery.of(context);
    final screenH = media.size.height;

    // ⚠️ 이 시트만 `AppSheet` 의 7슬롯 골격을 쓰지 않는다 — 7단계 마법사라
    // 단계마다 제목이 바뀌고 **'뒤로'가 필요**한데, 7슬롯에는 뒤로 자리가
    // 의도적으로 없다(주 버튼 하나 규칙). 대신 **껍데기는 완전히 같게** 맞춘다:
    // 배경·모서리(brSheet)·핸들(40×4, border 색)·스크림·최대 높이 0.9.
    // 띄우는 쪽도 `showAppSheet` 를 쓴다.
    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.9),
      decoration: const BoxDecoration(
        // `AppSheet` 과 같은 **canvas 바탕**. 안의 박스들이 이미 `AppColors.card`
        // (흰색)라, 바탕이 흰색이던 동안은 카드 경계가 테두리로만 겨우 보였다.
        color: AppColors.canvas,
        borderRadius: AppRadius.brSheet,
      ),
      // 키보드가 올라온 만큼 **시트 전체**를 띄운다 (`AppSheet` 슬롯 7과 동일).
      // 본문 스크롤뷰에 `viewInsets` 를 먹이는 방식은 본문만 피하고 푸터는
      // 키보드 뒤에 깔린다.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
        // ⛔ **높이를 고정하지 말 것** (`SizedBox(height: screenH * 0.85)`).
        // 2026-10-14 에 '푸터가 중간에 뜬다'를 고치려고 시트를 0.85 높이로
        // 못 박고 폼 단계만 `MainAxisSize.max` 로 돌렸는데, 내용이 짧은 단계는
        // 반대로 **헤더와 푸터 사이가 통째로 비어** 같은 증상이 남았다.
        // 앱의 다른 시트 26개가 쓰는 `AppSheet` 과 같은 방식이 답이다 —
        // 높이는 내용이 정하고(최대 0.9) 푸터는 늘 시트의 마지막 자식이라
        // 어느 단계에서나 시트 밑면 = 화면 밑면에 붙는다.
        mainAxisSize: MainAxisSize.min,
        children: [
          // 그랩 핸들 — AppSheet 의 것과 같은 치수·색·여백
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.brPill,
            ),
          ),
          // 단계별 본문
          Flexible(
            child: _buildStep(petsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(AsyncValue<List<Pet>> petsAsync) {
    return switch (_step) {
      _FabStep.chooseType => _buildChooseType(petsAsync),
      _FabStep.pickPets   => _buildPickPets(),
      _FabStep.feedChoice => _buildFeedChoice(petsAsync),
      _FabStep.feedBulk   => _buildFeedBulk(petsAsync),
      _FabStep.feedPerPet => _buildFeedPerPet(petsAsync),
      _FabStep.simpleForm => _buildSimpleForm(petsAsync),
      _FabStep.done       => _buildDone(),
    };
  }

  // ── 06 · 기록 종류 선택 (BFinalFabSheetV2 — 컴팩트 3×2) ────────
  Widget _buildChooseType(AsyncValue<List<Pet>> petsAsync) {
    // 개체가 고정된 시트(개체 상세 FAB)는 대상을 제목에 박아준다
    final locked = _petLocked ? _selectedPets(petsAsync) : const <Pet>[];
    final lockedPet = locked.isEmpty ? null : locked.first;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 32 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text('NEW RECORD',
              style: AppTextStyles.mono(11, FontWeight.w700,
                  color: AppColors.ink2)),
          const SizedBox(height: 4),
          Text(
            lockedPet == null ? '무엇을 기록할까요?' : '${lockedPet.name} · 무엇을 기록할까요?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.ink, letterSpacing: -0.4),
          ),
          const SizedBox(height: 4),
          Text(
            _petLocked ? '종류를 고르면 바로 입력해요' : '종류를 고르면 대상 개체를 선택해요',
            style: const TextStyle(fontSize: 12, color: AppColors.ink3,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

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

          // 개체가 고정된 시트에서는 '개체 추가'가 맥락에 맞지 않아 숨긴다
          if (!_petLocked) ...[
          const SizedBox(height: 24),

          // 개체 추가 버튼
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/pets/new');
            },
            child: Container(
              // 회색 블록(bgAlt)이라 꺼진 자리처럼 보였다. 누르면 개체 등록으로
              // 가는 카드이므로 다른 카드와 같은 흰 면 + 높이로 둔다.
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
                borderRadius: AppRadius.brMd,
                boxShadow: AppShadows.elev1,
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(Icons.add,
                        size: 20, color: AppColors.brandAction),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('개체 추가',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.ink)),
                        const SizedBox(height: 1),
                        Text('새로운 반려동물 등록',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.ink2,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const AppIcon(AppIcons.chevronRight,
                      size: 16, color: AppColors.ink2),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  // ── 06b · 대상 개체 선택 (인라인) ─────────────────────────────
  Widget _buildPickPets() {
    return _PetPickerContent(
      typeId: _typeId,
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('NEW FEEDING',
                    style: AppTextStyles.mono(11, FontWeight.w700,
                        color: AppColors.ink2)),
                const SizedBox(width: 8),
                const StepDots(step: 2),
              ]),
              const SizedBox(height: 8),
              const Text('어떻게 입력할까요?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.ink, letterSpacing: -0.4)),
              const SizedBox(height: 2),
              // 설명은 한 줄로 줄였다. 선택지 두 개에 제목·설명이 각각 붙으므로
              // 여기서 같은 말을 다시 풀면 한 화면에 같은 설명이 세 번 나온다.
              Text('선택한 개체 ${pets.length}마리를 한 번에, 또는 따로 적을 수 있어요',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
            ],
          ),
        ),
        if (pets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SelectedPetRow(pets: pets, tint: AppColors.catFeed),
          ),
        // 선택 카드
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _ChoiceCard(
                  icon: Icons.grid_view_outlined,
                  title: '일괄 입력',
                  desc: '모두 같은 내용으로 한 번에',
                  recommended: true,
                  selected: _feedMode == _FeedMode.bulk,
                  onTap: () => setState(() => _feedMode = _FeedMode.bulk),
                ),
                const SizedBox(height: 8),
                _ChoiceCard(
                  icon: Icons.view_list_outlined,
                  title: '개별 입력',
                  desc: '개체마다 양·메모를 따로',
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
      // 높이는 **내용이 정한다** (`build` 의 ⛔ 주석 참고). 시트를 고정 높이로
      // 못 박고 여기서 `max` 를 쓰면, 급여 목록이 한두 줄인 흔한 경우에
      // 헤더와 푸터 사이가 통째로 빈 canvas 가 된다.
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  _typeId == 'feed' ? 'FEEDING · BULK' : _typeId.toUpperCase(),
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.ink2),
                ),
                const SizedBox(width: 8),
                const StepDots(step: 3),
              ]),
              const SizedBox(height: 8),
              const Text('급여 기록',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.ink, letterSpacing: -0.4)),
            ],
          ),
        ),
        if (pets.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: SelectedPetRow(pets: pets, tint: AppColors.catFeed),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '아래 급여 목록을 모든 개체에 동일하게 기록해요',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: AppColors.ink2),
            ),
          ),
        ],
        // 본문 (스크롤)
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateRow(
                  label: _dateLabel,
                  date: _recordDate,
                  onTap: _pickRecordDate,
                ),
                const SizedBox(height: 20),
                FeedItemsEditor(
                  items: _bulkItems,
                  onChanged: (list) => setState(() => _bulkItems = list),
                ),
                const SizedBox(height: 16),
                const _MemoLabel(),
                const SizedBox(height: 8),
                TextField(
                  controller: _bulkMemoCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
                ),
              ],
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
    // 개체별 색은 걷어냈다 — 이 화면에서 색이 나르는 정보는 '누구냐'가 아니라
    // **'지금 이걸 작성 중이다'** 이므로 선택 상태 = 브랜드색이다.
    const pale      = AppColors.brandTint;
    const accent   = AppColors.brandAction;
    final allFilled = _filledCount == pets.length;

    return Column(
      mainAxisSize: MainAxisSize.min, // 06d 와 같은 이유 (높이는 내용이 정한다)
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
                              color: AppColors.ink2)),
                      const SizedBox(width: 8),
                      const StepDots(step: 3),
                    ]),
                    const SizedBox(height: 8),
                    const Text('급여 기록',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppColors.ink, letterSpacing: -0.4)),
                  ],
                ),
              ),
              // 완료 카운트 pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                // 다 채웠다는 진행 상태를 복숭아색(분류색)으로 말하고 있었다.
                decoration: BoxDecoration(
                  color: allFilled ? AppColors.brandTint : AppColors.card,
                  border: allFilled
                      ? null
                      : Border.all(color: AppColors.line),
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  '$_filledCount / ${pets.length}',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: allFilled
                          ? AppColors.brandTintInk
                          : AppColors.ink2),
                ),
              ),
            ],
          ),
        ),

        // 개체 탭 (가로 스크롤)
        //
        // ⚠️ 높이를 46 으로 조이면 **알약 안에서 이름이 잘린다**(사용자 지적).
        // 알약 한 칸은 아바타 22 + 위아래 패딩 16 + 테두리 3 = 41 이고, 거기에
        // 리스트 상하 패딩까지 들어간다. 치수를 건드릴 땐 이 합을 다시 셀 것.
        Container(
          height: 56,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p       = pets[i];
              final active  = i == _activePerPetIdx;
              const pPale   = AppColors.brandTintSoft;
              const pInk    = AppColors.brandAction;
              final isFilled = _perPetForms[p.id]?.filled ?? false;
              return GestureDetector(
                onTap: () => setState(() => _activePerPetIdx = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? pPale : AppColors.card,
                    border: Border.all(
                        color: active ? pInk : AppColors.line,
                        width: active ? 1.5 : 1),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    children: [
                      PetAvatar(
                        imageUrl: p.profileImageUrl,
                        size: 22,
                        background: active ? AppColors.bg : AppColors.bgAlt,
                        iconColor: AppColors.ink2,
                        subcategory: p.speciesSubcategory,
                      ),
                      const SizedBox(width: 8),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(width: 8),
                      isFilled
                          ? Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                  color: AppColors.brandAction,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white))
                          : Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.ink3,
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
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 16),
            child: Column(
              children: [
                // 개체 히어로
                Container(
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: AppRadius.brMd,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      PetAvatar(
                        imageUrl: activePet.profileImageUrl,
                        size: 44,
                        background: Colors.white.withValues(alpha: 0.55),
                        iconColor: AppColors.ink,
                        subcategory: activePet.speciesSubcategory,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activePet.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text(
                              '${activePet.speciesName}${activePet.latestWeightG != null ? ' · ${activePet.latestWeightG!.toStringAsFixed(0)}g' : ''}',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.ink2),
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
                              borderRadius: AppRadius.brMd,
                            ),
                            child: const Icon(Icons.chevron_left,
                                size: 20, color: AppColors.ink),
                          ),
                        ),
                      if (_activePerPetIdx < pets.length - 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _activePerPetIdx++),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: AppRadius.brMd,
                            ),
                            child: const AppIcon(AppIcons.chevronRight,
                                size: 20, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _DateRow(
                  label: _dateLabel,
                  date: _recordDate,
                  onTap: _pickRecordDate,
                ),
                const SizedBox(height: 20),
                // FeedItemsEditor (개체별 — 목록에 추가)
                FeedItemsEditor(
                  items: entry.items,
                  petId: activePet.id,
                  bandColor: pale,
                  onChanged: (list) => setState(() => entry.items = list),
                ),
                const SizedBox(height: 16),
                const _MemoLabel(),
                const SizedBox(height: 8),
                TextField(
                  controller: _perPetMemoCtrl.putIfAbsent(
                      activePet.id, () => TextEditingController()),
                  onChanged: (v) => entry.memo = v,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.ink),
                  decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
                ),
                const SizedBox(height: 16),

                // 완료 / 저장됨 액션
                if (entry.filled)
                  _SavedBanner(
                    petName: activePet.name,
                    pale: pale,
                    accent: accent,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry.items.isNotEmpty
                            ? AppColors.brandAction
                            : AppColors.brandTint,
                        borderRadius: AppRadius.brLg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check,
                              color: entry.items.isNotEmpty
                                  ? AppColors.bg
                                  : AppColors.brandTintInk,
                              size: 16),
                          const SizedBox(width: 8),
                          Text(
                            entry.items.isEmpty
                                ? '${activePet.name} 완료'
                                : '${activePet.name} 완료 (${entry.items.length}종)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: entry.items.isNotEmpty
                                    ? AppColors.bg
                                    : AppColors.brandTintInk),
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
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                color: AppColors.card,
                                border: Border.fromBorderSide(
                                    BorderSide(color: AppColors.line)),
                                borderRadius: AppRadius.brLg,
                                boxShadow: AppShadows.elev1,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chevron_left,
                                      size: 16, color: AppColors.ink),
                                  const SizedBox(width: 4),
                                  Text('이전',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.ink)),
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
                                  horizontal: 16, vertical: 12),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.card,
                                border: Border.fromBorderSide(BorderSide(
                                    color: AppColors.line, width: 1.5)),
                                borderRadius: AppRadius.brLg,
                                boxShadow: AppShadows.elev1,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PetAvatar(
                                    imageUrl: pets[_activePerPetIdx + 1].profileImageUrl,
                                    size: 22,
                                    background: AppColors.bgAlt,
                                    iconColor: AppColors.ink2,
                                    subcategory: pets[_activePerPetIdx + 1]
                                        .speciesSubcategory,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '다음 · ${pets[_activePerPetIdx + 1].name}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.ink),
                                  ),
                                  const AppIcon(AppIcons.chevronRight,
                                      size: 16, color: AppColors.ink),
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

  // ── 일련번호로 외부 개체 검색 ─────────────────────────────────
  Future<void> _searchPartnerBySerial(String speciesName) async {
    final q = _partnerExtCtrl.text.trim().toUpperCase();
    if (q.isEmpty) return;
    setState(() { _searchLoading = true; _searchError = null; _searchedPartner = null; });
    try {
      final repo = ref.read(petRepositoryProvider);
      final found = await repo.findBySerial(q);
      if (!mounted) return;
      if (found == null) {
        setState(() { _searchError = '검색 결과 없음 (비공개이거나 존재하지 않는 일련번호)'; _searchLoading = false; });
      } else if (found.speciesName != speciesName) {
        setState(() { _searchError = '같은 종의 개체만 메이팅 파트너로 선택할 수 있어요 (${found.speciesName})'; _searchLoading = false; });
      } else {
        setState(() { _searchedPartner = found; _searchLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _searchError = '검색 중 오류가 발생했어요'; _searchLoading = false; });
    }
  }

  // ── simpleForm 저장 ────────────────────────────────────────────
  bool _simpleFormValid() {
    return switch (_typeId) {
      'scale' => _weightCtrl.text.trim().isNotEmpty &&
                 (double.tryParse(_weightCtrl.text.trim()) ?? 0) > 0,
      'clean' => _cleaningType != null,
      // 내용을 적었거나, 분류(병원/탈피/배변 등)를 하나 골랐으면 저장 가능
      'note'  => _simpleMemoCtrl.text.trim().isNotEmpty || _memoTag != null,
      'mate'  => _partnerExternal
                   ? _searchedPartner != null
                   : _partnerPet != null,
      'lay'   => (int.tryParse(_eggTotalCtrl.text.trim()) ?? 0) > 0,
      _       => false,
    };
  }

  Future<void> _saveSimple(List<Pet> pets) async {
    if (pets.isEmpty) {
      showToast(context, '개체 정보를 불러오는 중이에요', type: ToastType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      final now  = _recordAt;
      final memo = _simpleMemoCtrl.text.trim();

      for (final pet in pets) {
        switch (_typeId) {
          case 'scale':
            final w = double.parse(_weightCtrl.text.trim());
            await repo.addWeight(pet.id, w, now, memo.isEmpty ? null : memo);
          case 'clean':
            await repo.addCleaning(
              pet.id,
              CleaningType.values.firstWhere((c) => c.name == _cleaningType),
              now, memo.isEmpty ? null : memo,
            );
          case 'note':
            final isVet = _memoTag == 'VET';
            // 선택한 분류의 한글 라벨 — 내용을 안 적었으면 이 값으로 저장
            final tagLabel = _memoTag == null
                ? null
                : (ref.read(memoTagsProvider).valueOrNull ?? const <MemoTag>[])
                    .where((t) => t.code == _memoTag)
                    .map((t) => t.labelKo)
                    .firstOrNull;
            final content = memo.isNotEmpty ? memo : (tagLabel ?? '');
            final data = <String, dynamic>{
              'content': content,
              'loggedAt': now.toUtc().toIso8601String(),
              if (_memoTag != null) 'tags': [_memoTag],
              // VET 태그는 vetExt 필수 (없으면 서버가 400) — 상세 정보는 추후 입력
              if (isVet) 'vetExt': <String, dynamic>{},
            };
            await repo.addMemo(pet.id, data);
          case 'mate':
            int? malePetId, femalePetId;
            String? extText;
            if (_partnerExternal) {
              final ext = _searchedPartner;
              if (ext != null) {
                if (pet.gender == 'MALE') {
                  malePetId = pet.id; femalePetId = ext.id;
                } else {
                  femalePetId = pet.id; malePetId = ext.id;
                }
              } else {
                femalePetId = pet.id;
              }
            } else {
              final partner = _partnerPet;
              if (partner != null) {
                if (pet.gender == 'MALE') {
                  malePetId = pet.id; femalePetId = partner.id;
                } else {
                  femalePetId = pet.id; malePetId = partner.id;
                }
              } else {
                femalePetId = pet.id;
              }
            }
            if (malePetId == null && femalePetId == null && extText == null) {
              femalePetId = pet.id;
            }
            final matingData = <String, dynamic>{
              if (malePetId   != null) 'petIdMale':           malePetId,
              if (femalePetId != null) 'petIdFemale':         femalePetId,
              if (extText     != null) 'externalPartnerText': extText,
              'triedAt': now.toUtc().toIso8601String(),
              'seasonLabel': now.year.toString(),
              // 미정이면 키 자체를 빼야 한다. null 을 실어 보내면 서버가 '아직
              // 모름'과 '실패'를 구분하지 못한다.
              if (_mateSuccess != null) 'isSuccessful': _mateSuccess,
              if (memo.isNotEmpty) 'memo': memo,
            };
            await repo.addMating(pet.id, matingData);
          case 'lay':
            final total   = int.parse(_eggTotalCtrl.text.trim());
            final fertile = int.tryParse(_eggFertileCtrl.text.trim());
            final layData = <String, dynamic>{
              'eggCountTotal': total,
              if (fertile != null && fertile > 0) 'eggCountFertile': fertile,
              'laidAt': now.toUtc().toIso8601String(),
              if (memo.isNotEmpty) 'memo': memo,
            };
            await repo.addLaying(pet.id, layData);
        }
        invalidatePetRecords(ref, pet.id);
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

  // ── simpleForm 빌드 ────────────────────────────────────────────
  Widget _buildSimpleForm(AsyncValue<List<Pet>> petsAsync) {
    final pets  = _selectedPets(petsAsync);
    final rt    = _recordTypes.firstWhere((r) => r.id == _typeId,
        orElse: () => _recordTypes.first);
    final valid = _simpleFormValid();

    return Column(
      mainAxisSize: MainAxisSize.min, // 06d 와 같은 이유 (높이는 내용이 정한다)
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(rt.en,
                    style: AppTextStyles.mono(11, FontWeight.w700,
                        color: AppColors.ink2)),
                const SizedBox(width: 8),
                const StepDots(step: 3),
              ]),
              const SizedBox(height: 8),
              Text('${rt.ko} 기록',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.ink, letterSpacing: -0.4)),
            ],
          ),
        ),
        if (pets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: SelectedPetRow(pets: pets, tint: rt.color),
          ),
        // 본문
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 — 기본은 오늘. 어제 걸 깜빡하고 적는 경우가 많다.
                _DateRow(
                  label: _dateLabel,
                  date: _recordDate,
                  onTap: _pickRecordDate,
                ),
                const SizedBox(height: 20),
                _buildSimpleFields(pets),
              ],
            ),
          ),
        ),
        // 푸터
        _Footer(
          onBack: _goBack,
          nextLabel: '저장',
          nextIcon: Icons.check,
          nextEnabled: valid && !_saving,
          loading: _saving,
          onNext: () => _saveSimple(pets),
        ),
      ],
    );
  }

  Widget _buildSimpleFields(List<Pet> pets) {
    // 비밀번호 재설정·로그인 화면과 같은 박스 입력이다. 전엔 언더라인 + 먹색
    // 포커스였다 — `AppColors.ink` 가 구 별칭이라 실제 값이 `ink` 여서,
    // 이 시트 전체에 브랜드 초록이 한 군데도 없었다.
    const side        = BorderSide(color: AppColors.line);
    const focusedSide = BorderSide(color: AppColors.brandAction, width: 1.5);
    final inputDec = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
          borderRadius: AppRadius.brMd, borderSide: side),
      enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd, borderSide: side),
      focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd, borderSide: focusedSide),
    );

    switch (_typeId) {
      // ── 몸무게 ────────────────────────────────────────────────
      case 'scale':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('체중 (g)', required: true),
            const SizedBox(height: 8),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.ink),
              decoration: inputDec.copyWith(
                hintText: '예: 85.5',
                suffixText: 'g',
                suffixStyle: const TextStyle(fontSize: 14, color: AppColors.ink2),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            _FieldLabel('메모', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _simpleMemoCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
            ),
          ],
        );

      // ── 청소 ──────────────────────────────────────────────────
      case 'clean':
        const types = [
          ('FULL',         '전체 청소',  AppIcons.cleanFull),
          ('PARTIAL',      '부분 청소',  AppIcons.cleanPartial),
          ('WATER_CHANGE', '물 교체',    AppIcons.cleanWater),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('청소 종류', required: true),
            const SizedBox(height: 8),
            Row(
              children: types.map((t) {
                final sel = _cleaningType == t.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _cleaningType = t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        // 선택은 **브랜드색**이 말한다. 분류색(petSky)으로 칠하던
                        // 자리인데, 그러면 "청소 기록" 이라는 종류 표시와 "이걸 골랐다" 는
                        // 상태가 같은 색이 되어 무엇이 선택된 건지 안 읽힌다.
                        decoration: BoxDecoration(
                          color: sel ? AppColors.brandTintSoft : AppColors.card,
                          border: Border.all(
                              color: sel ? AppColors.brandAction : AppColors.line,
                              width: sel ? 1.5 : 1),
                          borderRadius: AppRadius.brLg,
                          boxShadow: sel ? AppShadows.elev0 : AppShadows.elev1,
                        ),
                        child: Column(
                          children: [
                            AppIcon(t.$3, size: 20,
                                color: sel ? AppColors.brandAction : AppColors.ink2),
                            const SizedBox(height: 4),
                            Text(t.$2,
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: sel ? AppColors.brandAction : AppColors.ink2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _FieldLabel('메모', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _simpleMemoCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
            ),
          ],
        );

      // ── 메모 ──────────────────────────────────────────────────
      case 'note':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 분류 (병원/탈피/배변/행동/기타 — 서버 제공 목록, 단일 선택 라디오)
            _FieldLabel('분류', required: false),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final tags = ref.watch(memoTagsProvider).valueOrNull ??
                  const <MemoTag>[];
              if (tags.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) {
                  final sel = _memoTag == t.code;
                  return GestureDetector(
                    onTap: () => setState(() => _memoTag = sel ? null : t.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      // 선택은 브랜드색. 분류색(petLilac)으로 칠하던 자리인데,
                      // 태그마다 제 색을 갖는 게 아니라 전부 같은 보라였으니 "메모 태그"
                      // 라는 분류 표시도 아니었고 선택 표시로도 약했다.
                      decoration: BoxDecoration(
                        color: sel ? AppColors.brandTintSoft : AppColors.card,
                        border: Border.all(
                            color: sel
                                ? AppColors.brandAction
                                : AppColors.line,
                            width: sel ? 1.5 : 1),
                        borderRadius: AppRadius.brMd,
                        boxShadow: sel ? AppShadows.elev0 : AppShadows.elev1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 라디오 원 대신 태그 그림. 선택 여부는 칩의 배경·테두리가
                          // 이미 말하고 있어서 원을 하나 더 그릴 필요가 없다.
                          AppIcon(
                            AppIcons.memoTag(t.code),
                            size: 16,
                            color: sel
                                ? AppColors.brandAction
                                : AppColors.ink2,
                          ),
                          const SizedBox(width: 8),
                          Text(t.labelKo,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? AppColors.brandAction
                                      : AppColors.ink2)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 16),
            _FieldLabel('내용', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _simpleMemoCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: AppInputStyles.textarea(
                hintText: '관찰한 내용을 기록해요 (선택)',
              ).copyWith(alignLabelWithHint: true),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );

      // ── 메이팅 ────────────────────────────────────────────────
      case 'mate':
        final allPetsList = ref.watch(petListProvider).whenOrNull(data: (l) => l) ?? <Pet>[];
        // 선택된 개체들의 종명 (첫 번째 기준)
        final selectedSpeciesName = allPetsList
            .where((p) => _selectedPetIds.contains(p.id))
            .map((p) => p.speciesName)
            .firstOrNull ?? '';
        // 같은 종, 선택된 개체 제외
        final sameSpesPets = allPetsList
            .where((p) => !_selectedPetIds.contains(p.id) &&
                (selectedSpeciesName.isEmpty || p.speciesName == selectedSpeciesName))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('파트너', required: true),
            const SizedBox(height: 8),
            // 내 개체 / 외부 개체 토글
            Row(
              children: [
                _TypeToggle(
                  label: '내 개체',
                  active: !_partnerExternal,
                  onTap: () => setState(() {
                    _partnerExternal = false;
                    _searchedPartner = null;
                    _searchError = null;
                  }),
                ),
                const SizedBox(width: 8),
                _TypeToggle(
                  label: '외부 개체',
                  active: _partnerExternal,
                  onTap: () => setState(() {
                    _partnerExternal = true;
                    _partnerPet = null;
                    _searchedPartner = null;
                    _searchError = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_partnerExternal) ...[
              // 일련번호 검색
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _partnerExtCtrl,
                      style: const TextStyle(fontSize: 14, color: AppColors.ink),
                      textCapitalization: TextCapitalization.characters,
                      decoration: inputDec.copyWith(
                        hintText: '일련번호 입력 (예: AB12CD34)',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.ink2),
                      ),
                      onChanged: (_) => setState(() { _searchedPartner = null; _searchError = null; }),
                      onSubmitted: (_) => _searchPartnerBySerial(selectedSpeciesName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // QR 버튼 (준비 중)
                  Tooltip(
                    message: '준비 중',
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          size: 20, color: AppColors.ink3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _searchLoading
                    ? null
                    : () => _searchPartnerBySerial(selectedSpeciesName),
                icon: _searchLoading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 16),
                label: const Text('검색'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAction,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.brMd),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(_searchError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.warning)),
              ],
              if (_searchedPartner != null) ...[
                const SizedBox(height: 8),
                _PartnerResultCard(pet: _searchedPartner!,
                    onClear: () => setState(() { _searchedPartner = null; _partnerExtCtrl.clear(); })),
              ],
            ] else ...[
              // 내 개체 검색 리스트 (같은 종만)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                  borderRadius: AppRadius.brMd,
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: sameSpesPets.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('같은 종의 다른 개체가 없어요',
                              style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: sameSpesPets.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (_, i) {
                          final p   = sameSpesPets[i];
                          final sel = _partnerPet?.id == p.id;
                          return GestureDetector(
                            onTap: () => setState(() => _partnerPet = sel ? null : p),
                            child: Container(
                              color: sel
                                  ? AppColors.brandTintSoft
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  PetAvatar(
                                    imageUrl: p.profileImageUrl,
                                    size: 32,
                                    background: AppColors.bgAlt,
                                    iconColor: AppColors.ink2,
                                    subcategory: p.speciesSubcategory,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink)),
                                        Text(
                                          '${p.speciesName} · ${p.gender == 'MALE' ? '수컷' : p.gender == 'FEMALE' ? '암컷' : '미확인'}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.ink2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    Container(
                                      width: 20, height: 20,
                                      decoration: const BoxDecoration(
                                          color: AppColors.brandAction,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.check,
                                          size: 16, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
            const SizedBox(height: 20),
            _FieldLabel('결과', required: false),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeToggle(
                  label: '결과 미정',
                  active: _mateSuccess == null,
                  onTap: () => setState(() => _mateSuccess = null),
                ),
                const SizedBox(width: 8),
                _TypeToggle(
                  label: '성공',
                  active: _mateSuccess == true,
                  onTap: () => setState(() => _mateSuccess = true),
                ),
                const SizedBox(width: 8),
                _TypeToggle(
                  label: '실패',
                  active: _mateSuccess == false,
                  onTap: () => setState(() => _mateSuccess = false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel('메모', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _simpleMemoCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
            ),
          ],
        );

      // ── 산란 ──────────────────────────────────────────────────
      case 'lay':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('알 총 개수', required: true),
            const SizedBox(height: 8),
            TextField(
              controller: _eggTotalCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.ink),
              decoration: inputDec.copyWith(
                hintText: '0',
                suffixText: '개',
                suffixStyle: const TextStyle(fontSize: 14, color: AppColors.ink2),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _FieldLabel('유정란 수', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _eggFertileCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
              decoration: inputDec.copyWith(
                hintText: '미확인 시 비워두세요',
                suffixText: '개',
                suffixStyle: const TextStyle(fontSize: 14, color: AppColors.ink2),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel('메모', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _simpleMemoCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── 완료 화면 ──────────────────────────────────────────────────
  Widget _buildDone() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 32, 20, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            // 저장 완료 표시. 복숭아색(급여 분류색)이 들어가 있어 어떤 기록을
            // 저장해도 급여처럼 보였다 — 성공은 브랜드색이 말한다.
            decoration: const BoxDecoration(
                color: AppColors.brandTint, shape: BoxShape.circle),
            child: const Icon(Icons.check,
                color: AppColors.brandAction, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('기록 완료!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.ink, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          Text(
            () {
              final rt = _recordTypes.firstWhere((r) => r.id == _typeId,
                  orElse: () => _recordTypes.first);
              return '$_savedCount마리의 ${rt.ko} 기록이 저장되었어요';
            }(),
            style: TextStyle(fontSize: 13, color: AppColors.ink2),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              // 이 화면의 유일한 버튼이다. 먹색(primary) 풀버튼이었는데,
              // 누르는 자리는 브랜드색이 맡는다는 규칙에서 혼자 벗어나 있었다.
              decoration: const BoxDecoration(
                color: AppColors.brandAction,
                borderRadius: AppRadius.brLg,
                boxShadow: AppShadows.elev1,
              ),
              child: const Text('닫기',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 06b 개체 선택 컨텐츠 (인라인 위젯) ─────────────────────────
class _PetPickerContent extends ConsumerStatefulWidget {
  /// 앞 단계에서 고른 기록 종류. 종류에 따라 대상이 될 수 없는 개체가 있다
  /// ([_PetPickerContentState._isEligible]).
  final String typeId;
  final Set<int> preSelected;
  final ValueChanged<Set<int>> onApply;
  final VoidCallback onBack;

  const _PetPickerContent({
    required this.typeId,
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

  /// 이 기록 종류의 대상이 될 수 있는 개체인가.
  ///
  /// 산란은 수컷에게 성립하지 않는다 — 서버가 FEMALE 만 받으므로, 고를 수 있게
  /// 두면 저장 단계에 가서야 에러로 알게 된다. 고르지 못하게 하는 쪽이 낫다.
  /// 종 필터(`_matchFilter`)와 달리 **사용자가 끌 수 없는 조건**이라 따로 둔다.
  bool _isEligible(Pet p) => widget.typeId != 'lay' || canLayEggs(p.gender);

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
    // 대상이 될 수 없는 개체를 먼저 걷어낸다. 검색·종 필터보다 앞이어야
    // '전체선택'·'N마리 표시 중'·카운트가 못 고르는 개체를 세지 않는다.
    final eligible  = allPets.where(_isEligible).toList();
    final eligibleIds = eligible.map((p) => p.id).toSet();
    final excluded  = allPets.length - eligible.length;
    final filtered  = eligible.where((p) =>
        _matchFilter(p) &&
        (q.isEmpty || p.name.toLowerCase().contains(q) ||
            p.speciesName.toLowerCase().contains(q))).toList();

    final allSelected  = filtered.isNotEmpty && filtered.every((p) => _selected.contains(p.id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT TARGET',
                        style: AppTextStyles.mono(11, FontWeight.w700,
                            color: AppColors.ink2)),
                    const SizedBox(height: 4),
                    const Text('대상 개체 선택',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppColors.ink, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Text('여러 개체에 같은 기록을 한 번에 남길 수 있어요',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ink2)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selected.isNotEmpty
                      ? AppColors.brandTint
                      : AppColors.card,
                  border: _selected.isNotEmpty
                      ? null
                      : Border.all(color: AppColors.line),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(
                  '${_selected.length} / ${allPets.length}',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: _selected.isNotEmpty
                          ? AppColors.brandTintInk
                          : AppColors.ink3),
                ),
              ),
            ],
          ),
        ),

        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: AppRadius.brPill,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 20, color: AppColors.ink2),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration.collapsed(
                      hintText: '이름 또는 종 검색…',
                      hintStyle: TextStyle(color: AppColors.ink3),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _query = ''),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.ink3),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.brandAction : AppColors.card,
                    border: active
                        ? null
                        : Border.all(color: AppColors.line),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    children: [
                      Text(f.$2,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.card
                                  : AppColors.ink)),
                      const SizedBox(width: 4),
                      Text('$count',
                          style: AppTextStyles.mono(10, FontWeight.w700,
                              color: active
                                  ? AppColors.card.withValues(alpha: 0.6)
                                  : AppColors.ink3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // 전체선택/해제 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(
              top:    BorderSide(color: AppColors.line),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: Row(
            children: [
              Text(
                // 왜 안 보이는지 말해준다 — 그냥 빼버리면 "내 개체가 없어졌다"가 된다.
                excluded > 0
                    ? '${filtered.length}마리 · 수컷 $excluded마리 제외'
                    : '${filtered.length}마리 표시 중',
                style: AppTextStyles.mono(11, FontWeight.w700,
                    color: AppColors.ink2),
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
              const SizedBox(width: 8),
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
                            fontSize: 13, color: AppColors.ink3)),
                  ),
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.78,
                  children: filtered.map((p) {
                    final isOn  = _selected.contains(p.id);
                    const pale  = AppColors.brandTintSoft;
                    const pInk  = AppColors.brandAction;
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
                              color: isOn ? pInk : AppColors.line,
                              width: isOn ? 1.5 : 1),
                          borderRadius: AppRadius.brMd,
                          boxShadow: isOn ? AppShadows.elev0 : AppShadows.elev1,
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                        child: Column(
                          children: [
                            PetAvatar(
                              imageUrl: p.profileImageUrl,
                              size: 52,
                              background: isOn ? AppColors.bg : AppColors.bgAlt,
                              iconColor: AppColors.ink2,
                              subcategory: p.speciesSubcategory,
                            ),
                            const SizedBox(height: 8),
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            // 종 + 성별을 **한 줄**로 둔다. 세 줄(이름/종/성별·체중)이던
                            // 자리인데, 3열 격자의 한 칸 높이(aspect 0.78)가 그걸 담지
                            // 못해 `RenderFlex overflowed` 가 떴다.
                            //
                            // 줄이면서 **체중은 뺐다** — 여기서 하는 일은 '누구에게 기록할지'
                            // 고르는 것뿐이라 몸무게는 판단에 쓰이지 않고, 숫자가 섞이면
                            // 작은 칸에서 이름보다 먼저 눈에 들어온다. (체중은 개체 상세와
                            // 체중 기록 화면에 있다.)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SexIcon.fromCode(p.gender, size: 11),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(p.speciesName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.ink2,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
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
          // 목록에 없는 개체는 체크도 못 하지만, 앞 단계에서 미리 선택된 채
          // 넘어온 것(`preSelected`)은 화면에 안 보이면서 선택이 살아 있다.
          // 여기서 한 번 걸러야 수컷이 산란 대상으로 새지 않는다.
          onNext: () => widget.onApply(
              _selected.where(eligibleIds.contains).toSet()),
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
        // 격자로 떠 있는 누를 수 있는 카드다. 그림자가 없어 바탕에 눌러붙어
        // 보였다 — 밟을 수 있는 면이라는 걸 높이로 알린다.
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
          borderRadius: AppRadius.brMd,
          boxShadow: AppShadows.elev1,
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: type.color,
                borderRadius: AppRadius.brLg,
              ),
              child: AppIcon(type.icon, size: 20, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(type.ko,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

// ── 선택 카드 (06c 일괄 / 개별) ────────────────────────────────
//
// ⛔ **카드 안에 영문 모노 라벨('BULK'/'PER-PET')·'RECOMMENDED'·예시 알약을
//   되살리지 말 것.** 2026-10-14 이전에는 한 카드에 라벨 1줄 + 제목 + 설명 +
//   예시 알약 2~3개가 들어 있었다. 고를 것은 둘뿐인데 읽을 것이 네 줄이라
//   "촌스럽다"는 지적을 받았다 (사용자 원문). 남은 것은 **제목 + 한 줄 설명**
//   뿐이고, 추천은 영문 알약 대신 제목 옆 '추천' 한 단어로 붙는다.
class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.desc,
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
        // 테두리만 브랜드색으로 바뀌던 자리다. 두 카드가 나란히 있을 때
        // 1.5px 선 하나로는 어느 쪽을 골랐는지 한눈에 안 들어온다 —
        // 배경까지 바꾸고, 고른 카드는 평평하게(눌린 것) 둔다.
        decoration: BoxDecoration(
          color: selected ? AppColors.brandTintSoft : AppColors.card,
          border: Border.all(
              color: selected ? AppColors.brandAction : AppColors.line,
              width: selected ? 1.5 : 1),
          borderRadius: AppRadius.brMd,
          boxShadow: selected ? AppShadows.elev0 : AppShadows.elev1,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: AppRadius.brLg,
              ),
              child: Icon(icon, size: 20, color: AppColors.brandAction),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              letterSpacing: -0.3)),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: const Text('추천',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandTintInk)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ink2, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon(AppIcons.chevronRight,
                size: 16, color: AppColors.ink3),
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
  final Color accent;
  final VoidCallback onUndo;

  const _SavedBanner({
    required this.petName,
    required this.pale,
    required this.accent,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pale,
        border: Border.all(color: accent, width: 1.5),
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$petName · 저장됨',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('수정하려면 미완료로 되돌린 뒤 다시 완료하세요',
                    style: TextStyle(fontSize: 12, color: AppColors.ink2)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUndo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: AppRadius.brPill,
              ),
              child: const Text('미완료',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
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

  /// 주 버튼 라벨 뒤에 붙는 수량 꼬리말 ('3종 저장'). 예전에는 버튼 안에
  /// 반투명 알약 + 영문 모노로 따로 떠 있었다 — 버튼 하나에 면이 두 겹이라
  /// 눌리는 자리가 어디까지인지 흐려졌다. 지금은 `다음 · 3종 저장` 처럼
  /// 라벨에 이어 붙인다.
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
    final label = nextBadge == null ? nextLabel : '$nextLabel · $nextBadge';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        // 시트 바탕은 `canvas` 인데 푸터만 흰 면 + 위쪽 선이다. 스크롤되는
        // 본문과 고정된 버튼 줄을 눈으로 가르는 게 이 선 하나뿐이라,
        // 바탕색으로 맞추면 버튼이 본문 위에 떠 있는 것처럼 보인다.
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            // 색·비활성색·눌림색은 `AppActionButton` 만 안다 (⛔ 수제 금지).
            SizedBox(
              width: 92,
              child: AppActionButton(
                '뒤로',
                tone: AppButtonTone.neutral,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: AppActionButton(
              label,
              icon: nextIcon,
              loading: loading,
              onPressed: nextEnabled ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 메모 레이블 (공유) ─────────────────────────────────────────
class _MemoLabel extends StatelessWidget {
  const _MemoLabel();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text('메모',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.ink)),
      const SizedBox(width: 8),
      Text('OPTIONAL', style: AppTextStyles.mono(9, FontWeight.w700,
          color: AppColors.ink3)),
    ],
  );
}

// ── 필드 레이블 ────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: AppColors.error)),
        ] else ...[
          const SizedBox(width: 8),
          Text('선택', style: AppTextStyles.mono(9, FontWeight.w700,
              color: AppColors.ink3)),
        ],
      ],
    );
  }
}

// ── 토글 버튼 ─────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAction : AppColors.card,
          border: Border.all(
              color: active ? AppColors.brandAction : AppColors.line,
              width: active ? 1.5 : 1),
          borderRadius: AppRadius.brMd,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? AppColors.card : AppColors.ink2)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: AppRadius.brPill,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: disabled ? AppColors.ink3 : AppColors.ink),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: disabled ? AppColors.ink3 : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _PartnerResultCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onClear;

  const _PartnerResultCard({required this.pet, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecor.cardSelected,
      child: Row(
        children: [
          PetAvatar(
            imageUrl: pet.profileImageUrl,
            size: 36,
            background: AppColors.bg,
            iconColor: AppColors.brandAction,
            subcategory: pet.speciesSubcategory,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text(
                  '${pet.speciesName} · ${pet.serialNo}',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 20, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}

// ── 기록 날짜 선택 줄 ──────────────────────────────────────────
// 오늘이 기본값이라 **대개 건드리지 않는다** — 그래서 폼 맨 위에서 자리를 많이
// 먹지 않도록 레이블과 값을 한 줄에 둔다.
class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
  });

  /// 고른 날이 오늘에서 얼마나 떨어졌는지 — 날짜만 보고 '어제인가?'를
  /// 세게 만들지 않는다.
  static String _relative(DateTime date) {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    return switch (diff) {
      0 => '오늘',
      1 => '어제',
      2 => '그제',
      _ => '$diff일 전',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FieldLabel(label, required: true),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: AppRadius.brMd,
            ),
            child: Row(
              children: [
                const Icon(Icons.event,
                    size: 16, color: AppColors.ink2),
                const SizedBox(width: 8),
                Text(
                  '${date.year}. ${date.month}. ${date.day}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                const SizedBox(width: 6),
                Text('(${_relative(date)})',
                    style: TextStyle(fontSize: 12, color: AppColors.ink2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
