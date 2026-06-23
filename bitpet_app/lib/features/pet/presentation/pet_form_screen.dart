import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import 'widgets/species_bottom_sheet.dart';
import 'widgets/parent_pet_bottom_sheet.dart';

// ════════════════════════════════════════════════════════════════
// 03s · 개체 등록 — 6단계 스텝 위저드
// 1) 사진+이름  2) 종+모프  3) 성별+날짜  4) 몸무게+부모  5) 메모  6) 확인
// ════════════════════════════════════════════════════════════════

class PetFormScreen extends ConsumerStatefulWidget {
  final int? petId;
  const PetFormScreen({super.key, this.petId});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  // ── 팔레트 ──────────────────────────────────────────────────────────────────
  static const _palette = <(String, Color, Color, String)>[
    ('sage',   AppColors.petSage,   AppColors.petSageInk,   '#E8F2DC'),
    ('peach',  AppColors.petPeach,  AppColors.petPeachInk,  '#FFE3CE'),
    ('sky',    AppColors.petSky,    AppColors.petSkyInk,    '#D5F0FF'),
    ('lilac',  AppColors.petLilac,  AppColors.petLilacInk,  '#F1E5FF'),
    ('butter', AppColors.petButter, AppColors.petButterInk, '#FCF2CD'),
    ('coral',  AppColors.petCoral,  AppColors.petCoralInk,  '#FFD8D4'),
  ];

  // ── 상태 ────────────────────────────────────────────────────────────────────
  bool _initialized = false; // 수정 모드에서 기존 데이터 로딩 완료 여부

  String _colorKey = 'coral';
  final _nameCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _memoCtrl   = TextEditingController();

  Species? _species;
  final List<int>   _selectedMorphIds  = [];
  final List<Morph> _selectedMorphs    = [];
  String _gender = '수컷';
  String _hatchPrecision = 'DAY'; // 'DAY'=정확한 날짜, 'MONTH'=연·월만
  DateTime? _hatchDate;           // DAY precision: full date
  int? _hatchYear;                // MONTH precision: year
  int? _hatchMonth;               // MONTH precision: month
  bool _hatchApproximate = false; // 날짜가 정확하지 않음 표시
  DateTime? _adoptDate;
  bool _adoptUnknown = false;
  String _weightUnit = 'g';
  Pet? _fatherPet;
  Pet? _motherPet;
  bool _isPublic = false; // 검색 허용 여부 (기본 비공개)

  // ── 팔레트 헬퍼 ──────────────────────────────────────────────────────────────
  Color get _selectedBg {
    for (final (k, bg, _, __) in _palette) { if (k == _colorKey) return bg; }
    return AppColors.petCoral;
  }

  Color get _selectedInk {
    for (final (k, _, ink, __) in _palette) { if (k == _colorKey) return ink; }
    return AppColors.petCoralInk;
  }

  String get _selectedHex {
    for (final (k, _, __, hex) in _palette) { if (k == _colorKey) return hex; }
    return '#FFD8D4';
  }

  @override
  void initState() {
    super.initState();
    if (widget.petId == null) {
      _initialized = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit(widget.petId!));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit(int petId) async {
    try {
      final pet = await ref.read(petDetailProvider(petId).future);

      // 이미 pet.morphs에 N:N 목록이 들어있으므로 직접 사용
      final matchedMorphs = List<Morph>.from(pet.morphs);

      if (!mounted) return;

      setState(() {
        // 식별색
        for (final (k, _, __, hex) in _palette) {
          if (hex.toLowerCase() == (pet.colorCode ?? '').toLowerCase()) {
            _colorKey = k;
            break;
          }
        }
        // 이름
        _nameCtrl.text = pet.name;
        // 종 (스텁)
        _species = Species(id: pet.speciesId, code: '', category: '', nameKo: pet.speciesName);
        // 모프 (N:N)
        _selectedMorphIds
          ..clear()
          ..addAll(matchedMorphs.map((m) => m.id));
        _selectedMorphs
          ..clear()
          ..addAll(matchedMorphs);
        // 성별
        _gender = pet.gender == 'MALE' ? '수컷' : pet.gender == 'FEMALE' ? '암컷' : '미상';
        // 해칭일
        if (pet.hatchingDate != null) {
          _hatchPrecision = pet.hatchingDatePrecision;
          if (pet.hatchingDatePrecision == 'MONTH') {
            _hatchYear = pet.hatchingDate!.year;
            _hatchMonth = pet.hatchingDate!.month;
          } else {
            _hatchDate = pet.hatchingDate;
          }
        }
        _hatchApproximate = pet.hatchingDateApproximate;
        // 입양일
        _adoptDate = pet.adoptionDate;
        // 메모/설명
        _memoCtrl.text = pet.description ?? '';
        // 검색 허용
        _isPublic = pet.privateYn == 'N';

        _initialized = true;
      });
    } catch (_) {
      if (mounted) {
        ToastMessage.show(context, '개체 정보를 불러올 수 없어요', type: ToastType.warning);
        context.pop();
      }
    }
  }

  // ── 액션 ──────────────────────────────────────────────────────────────────
  Future<void> _openSpeciesSheet() async {
    final result = await showModalBottomSheet<Species>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpeciesBottomSheet(initialSelection: _species),
    );
    if (result != null) {
      setState(() {
        _species = result;
        _selectedMorphIds.clear();
        _selectedMorphs.clear();
      });
    }
  }

  Future<void> _openParentSheet({required bool isFather}) async {
    final result = await showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPetBottomSheet(
        isFather: isFather,
        initialSelection: isFather ? _fatherPet : _motherPet,
        excludePetId: widget.petId,
        filterSpeciesId: _species?.id,
      ),
    );
    if (result != null) {
      setState(() {
        if (isFather) _fatherPet = result;
        else _motherPet = result;
      });
    }
  }

  Future<void> _pickDate({required bool isHatching}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isHatching ? (_hatchDate ?? now) : (_adoptDate ?? now),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isHatching) _hatchDate = picked;
        else { _adoptDate = picked; _adoptUnknown = false; }
      });
    }
  }

  Future<void> _pickYearMonth() async {
    final now = DateTime.now();
    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _YearMonthPickerSheet(
        initialYear: _hatchYear ?? now.year,
        initialMonth: _hatchMonth ?? now.month,
      ),
    );
    if (result != null) {
      setState(() {
        _hatchYear = result.$1;
        _hatchMonth = result.$2;
      });
    }
  }

  Future<void> _submit() async {
    if (_species == null) {
      ToastMessage.show(context, '종을 선택해주세요', type: ToastType.warning);
      return;
    }
    final rawWeight = double.tryParse(_weightCtrl.text);
    final weightG = rawWeight != null && rawWeight > 0
        ? (_weightUnit == 'kg' ? rawWeight * 1000 : rawWeight)
        : null;

    String? fmt(DateTime? dt) {
      if (dt == null) return null;
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    final genderCode = _gender == '수컷' ? 'MALE' : _gender == '암컷' ? 'FEMALE' : 'UNKNOWN';

    String? hatchingDate;
    String? hatchingDatePrecision;
    if (_hatchPrecision == 'DAY' && _hatchDate != null) {
      hatchingDate = fmt(_hatchDate);
      hatchingDatePrecision = 'DAY';
    } else if (_hatchPrecision == 'MONTH' && _hatchYear != null && _hatchMonth != null) {
      hatchingDate = '$_hatchYear-${_hatchMonth.toString().padLeft(2, '0')}-01';
      hatchingDatePrecision = 'MONTH';
    }

    if (widget.petId != null) {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'speciesId': _species!.id,
        'gender': genderCode,
        'colorCode': _selectedHex,
        if (_selectedMorphIds.isNotEmpty) 'morphIds': _selectedMorphIds,
        'privateYn': _isPublic ? 'N' : 'Y',
        if (hatchingDate != null) 'hatchingDate': hatchingDate,
        if (hatchingDatePrecision != null) 'hatchingDatePrecision': hatchingDatePrecision,
        'hatchingDateApproximate': _hatchApproximate,
        'adoptionDate': _adoptUnknown ? null : fmt(_adoptDate),
        if (weightG != null) 'currentWeightG': weightG,
        'description': _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      };
      await ref.read(petListProvider.notifier).update(widget.petId!, data);
      ref.invalidate(petDetailProvider(widget.petId!));
      if (mounted) {
        ToastMessage.show(context, '수정되었습니다!', type: ToastType.success);
        context.pop();
      }
    } else {
      await ref.read(petListProvider.notifier).add(
        CreatePetRequest(
          speciesId: _species!.id,
          name: _nameCtrl.text.trim(),
          gender: genderCode,
          colorCode: _selectedHex,
          morphIds: List.from(_selectedMorphIds),
          hatchingDate: hatchingDate,
          hatchingDatePrecision: hatchingDatePrecision,
          hatchingDateApproximate: _hatchApproximate,
          adoptionDate: _adoptUnknown ? null : fmt(_adoptDate),
          currentWeightG: weightG,
          fatherPetId: _fatherPet?.id,
          motherPetId: _motherPet?.id,
          description: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
          privateYn: _isPublic ? 'N' : 'Y',
        ),
      );
      if (mounted) {
        ToastMessage.show(context, '개체가 등록되었습니다!', type: ToastType.success);
        context.pop();
      }
    }
  }

  // ── 날짜 포맷 ──────────────────────────────────────────────────────────────
  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  // ── 스텝 빌드 ─────────────────────────────────────────────────────────────
  List<StepConfig> get _steps {
    final isEdit = widget.petId != null;
    final all = _buildAllSteps(isEdit);
    // 수정 모드: Step 4(몸무게+부모) 제외
    return isEdit ? [all[0], all[1], all[2], all[4], all[5]] : all;
  }

  List<StepConfig> _buildAllSteps(bool isEdit) => [
    // ── Step 1: 사진+이름 ────────────────────────────────────────────────────
    StepConfig(
      title: '사진과 이름',
      desc: '식별 색을 고르고 이름을 지어주세요.',
      valid: () => _nameCtrl.text.trim().isNotEmpty,
      render: (_) => ListenableBuilder(
        listenable: _nameCtrl,
        builder: (_, __) => Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 아바타
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: _selectedBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('🦎', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => ToastMessage.show(
                          context, '이미지 선택은 준비 중이에요', type: ToastType.info,
                        ),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.paleLine),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.paleInk2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IDENTITY COLOR',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.paleInk2, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 10),
                      _PalettePicker(
                        value: _colorKey,
                        palette: _palette,
                        onChanged: (k) => setState(() => _colorKey = k),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SField(
              label: '이름',
              child: PaleTextField(
                controller: _nameCtrl,
                placeholder: '개체 이름',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    ),

    // ── Step 2: 종+모프 ──────────────────────────────────────────────────────
    StepConfig(
      title: '종과 모프',
      desc: '종을 고르면 모프 후보가 나타나요.',
      valid: () => _species != null,
      render: (_) => Column(
        children: [
          SField(
            label: '종',
            child: GestureDetector(
              onTap: _openSpeciesSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.paleLine),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _species?.nameKo ?? '종을 선택하세요',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _species == null ? AppColors.paleInk3 : AppColors.primary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.paleInk3, size: 20),
                  ],
                ),
              ),
            ),
          ),
          Consumer(
            builder: (ctx, ref, _) {
              final morphsAsync = _species == null
                  ? const AsyncValue<List<Morph>>.data([])
                  : ref.watch(morphsBySpeciesProvider(_species!.id));

              return SField(
                label: '모프',
                hint: _species == null ? '종 먼저' : null,
                child: morphsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (morphs) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 카탈로그 모프 추천 칩
                      ...morphs.map((m) {
                        final selected = _selectedMorphIds.contains(m.id);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedMorphIds.remove(m.id);
                              _selectedMorphs.removeWhere((s) => s.id == m.id);
                            } else {
                              _selectedMorphIds.add(m.id);
                              _selectedMorphs.add(m);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.paleLine,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m.nameKo,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppColors.paleBg : AppColors.primary,
                                  ),
                                ),
                                if (m.nameEn != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    m.nameEn!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: selected ? AppColors.paleBg.withValues(alpha: 0.75) : AppColors.paleInk2,
                                    ),
                                  ),
                                ],
                                if (m.hasHealthConcern) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: '건강 우려 모프',
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 13,
                                      color: selected ? AppColors.paleBg.withValues(alpha: 0.85) : const Color(0xFFCC8800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      // 건강 우려 안내
                      if (morphs.any((m) => m.hasHealthConcern))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFCC8800)),
                              SizedBox(width: 4),
                              Text(
                                '건강 우려 모프가 포함되어 있어요',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFFCC8800), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),

    // ── Step 3: 성별+날짜 ────────────────────────────────────────────────────
    StepConfig(
      title: '성별과 날짜',
      desc: '연·월만 알고 있거나 날짜가 정확하지 않으면 체크해주세요.',
      render: (_) => Column(
        children: [
          SField(
            label: '성별',
            child: PaleSegment(
              options: const ['수컷', '암컷', '미상'],
              value: _gender,
              onChange: (v) => setState(() => _gender = v),
            ),
          ),
          SField(
            label: '해칭일',
            child: _HatchDateField(
              precision: _hatchPrecision,
              date: _hatchDate,
              year: _hatchYear,
              month: _hatchMonth,
              approximate: _hatchApproximate,
              onPrecisionChanged: (p) => setState(() {
                _hatchPrecision = p;
                _hatchDate = null;
                _hatchYear = null;
                _hatchMonth = null;
              }),
              onPickDay: () => _pickDate(isHatching: true),
              onPickYearMonth: _pickYearMonth,
              onApproximateChanged: (v) => setState(() => _hatchApproximate = v),
              fmtDate: _fmtDate,
            ),
          ),
          SField(
            label: '입양일',
            child: _DateField(
              date: _adoptDate,
              unknown: _adoptUnknown,
              onTap: () => _pickDate(isHatching: false),
              onUnknownChanged: (v) => setState(() {
                _adoptUnknown = v;
                if (v) _adoptDate = null;
              }),
              fmtDate: _fmtDate,
            ),
          ),
        ],
      ),
    ),

    // ── Step 4: 몸무게+부모 ──────────────────────────────────────────────────
    StepConfig(
      title: '몸무게와 부모',
      desc: '나중에 기록 탭에서 이어서 관리해요.',
      render: (_) => Column(
        children: [
          SField(
            label: '현재 몸무게',
            hint: '기록 탭에 누적',
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.paleLine),
                    ),
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: const TextStyle(color: AppColors.paleInk3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: InputBorder.none,
                        suffixText: _weightUnit,
                        suffixStyle: const TextStyle(fontSize: 13, color: AppColors.paleInk2, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _WeightUnitToggle(
                  selected: _weightUnit,
                  onChanged: (u) => setState(() => _weightUnit = u),
                ),
              ],
            ),
          ),
          SField(
            label: '부모 개체',
            hint: '일련번호 검색',
            child: Column(
              children: [
                _ParentTile(
                  isFather: true,
                  pet: _fatherPet,
                  onTap: () => _openParentSheet(isFather: true),
                  onClear: () => setState(() => _fatherPet = null),
                ),
                const SizedBox(height: 8),
                _ParentTile(
                  isFather: false,
                  pet: _motherPet,
                  onTap: () => _openParentSheet(isFather: false),
                  onClear: () => setState(() => _motherPet = null),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // ── Step 5: 메모 ─────────────────────────────────────────────────────────
    StepConfig(
      title: '메모',
      desc: '사육환경·병원 기록 등 자유롭게 (선택).',
      render: (_) => Column(
        children: [
          SField(
            label: '메모',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.paleLine),
              ),
              child: TextField(
                controller: _memoCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 14, color: AppColors.primary, height: 1.55),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  hintText: '예: 온도 26°C · 습도 70%\n2024.11.18 — 첫 동물병원 검진 (이상 없음)',
                  hintStyle: TextStyle(color: AppColors.paleInk3, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 검색 허용 토글
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('메이팅 검색 허용',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text('공개 시 다른 사용자가 일련번호로 이 개체를 검색할 수 있어요.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.paleInk2)),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublic,
                  activeColor: AppColors.petSageInk,
                  activeTrackColor: AppColors.petSage,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // ── Step 6: 확인 ─────────────────────────────────────────────────────────
    StepConfig(
      title: isEdit ? '수정 내용을 확인하세요' : '등록 내용을 확인하세요',
      desc: '"수정"으로 각 단계를 다시 고칠 수 있어요.',
      render: (ctx) => StepSummary(
        goEdit: ctx.goEdit,
        groups: [
          StepSummaryGroup(label: '기본', step: 0, rows: [
            StepSummaryRow(k: '이름', v: _nameCtrl.text),
            StepSummaryRow(k: '식별색', v: _colorKey),
          ]),
          StepSummaryGroup(label: '종·모프', step: 1, rows: [
            StepSummaryRow(k: '종', v: _species?.nameKo ?? ''),
            StepSummaryRow(
              k: '모프',
              v: _selectedMorphs.isEmpty
                  ? ''
                  : _selectedMorphs.map((m) => m.nameKo).join(', '),
              muted: _selectedMorphs.isEmpty,
            ),
          ]),
          StepSummaryGroup(label: '성별·날짜', step: 2, rows: [
            StepSummaryRow(k: '성별', v: _gender),
            StepSummaryRow(
              k: '해칭일',
              v: () {
                final base = _hatchPrecision == 'MONTH' && _hatchYear != null && _hatchMonth != null
                    ? '$_hatchYear년 ${_hatchMonth}월 (연·월)'
                    : (_hatchDate != null ? _fmtDate(_hatchDate!) : '');
                return base.isEmpty ? '' : (_hatchApproximate ? '약 $base' : base);
              }(),
              muted: _hatchDate == null && (_hatchYear == null || _hatchMonth == null),
            ),
            StepSummaryRow(
              k: '입양일',
              v: _adoptUnknown ? '모름' : (_adoptDate != null ? _fmtDate(_adoptDate!) : ''),
              muted: _adoptUnknown || _adoptDate == null,
            ),
          ]),
          if (!isEdit)
            StepSummaryGroup(label: '몸무게·부모', step: 3, rows: [
              StepSummaryRow(
                k: '몸무게',
                v: _weightCtrl.text.isNotEmpty ? '${_weightCtrl.text} $_weightUnit' : '',
                muted: _weightCtrl.text.isEmpty,
              ),
              StepSummaryRow(
                k: '부 / 모',
                v: '${_fatherPet?.name ?? '—'} / ${_motherPet?.name ?? '—'}',
                muted: _fatherPet == null && _motherPet == null,
              ),
            ]),
          StepSummaryGroup(label: '메모', step: isEdit ? 3 : 4, rows: [
            StepSummaryRow(k: '메모', v: _memoCtrl.text, muted: _memoCtrl.text.isEmpty),
            StepSummaryRow(k: '메이팅 검색', v: _isPublic ? '공개' : '비공개'),
          ]),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.paleBg,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: StepShell(
          headerTitle: widget.petId == null ? '개체 등록' : '개체 수정',
          accentInk: _selectedInk,
          steps: _steps,
          doneLabel: widget.petId == null ? '개체 저장' : '수정 완료',
          onDone: _submit,
          onCancel: () => context.pop(),
          initialStep: widget.petId != null ? 4 : 0,
        ),
      ),
    );
  }
}

// ── 팔레트 피커 ────────────────────────────────────────────────────────────────

class _PalettePicker extends StatelessWidget {
  final String value;
  final List<(String, Color, Color, String)> palette;
  final void Function(String) onChanged;

  const _PalettePicker({
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.map((entry) {
        final (key, bg, ink, _) = entry;
        final sel = value == key;
        return GestureDetector(
          onTap: () => onChanged(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? ink : AppColors.paleLine,
                width: sel ? 2 : 1,
              ),
            ),
            child: sel ? Icon(Icons.check, size: 14, color: ink) : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── 날짜 필드 ──────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final DateTime? date;
  final bool unknown;
  final VoidCallback onTap;
  final void Function(bool) onUnknownChanged;
  final String Function(DateTime) fmtDate;

  const _DateField({
    required this.date,
    required this.unknown,
    required this.onTap,
    required this.onUnknownChanged,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: unknown ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: unknown ? AppColors.paleBgAlt : AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: unknown ? AppColors.paleInk3 : AppColors.paleInk2,
                ),
                const SizedBox(width: 10),
                Text(
                  date != null ? fmtDate(date!) : '날짜 선택',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: date == null || unknown ? AppColors.paleInk3 : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onUnknownChanged(!unknown),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: unknown ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: unknown ? AppColors.primary : AppColors.paleLine,
                    width: 1.5,
                  ),
                ),
                child: unknown
                    ? const Icon(Icons.check, size: 12, color: AppColors.paleBg)
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                '모르겠어요',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.paleInk2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 몸무게 단위 토글 ────────────────────────────────────────────────────────────

class _WeightUnitToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _WeightUnitToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.paleLine),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['g', 'kg'].map((u) {
          final sel = selected == u;
          return GestureDetector(
            onTap: () => onChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel ? AppColors.primary : AppColors.paleInk2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 부모 개체 타일 ─────────────────────────────────────────────────────────────

class _ParentTile extends StatelessWidget {
  final bool isFather;
  final Pet? pet;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ParentTile({
    required this.isFather,
    required this.pet,
    required this.onTap,
    required this.onClear,
  });

  Color _bgOf(Pet p) {
    if (p.colorCode == null) return AppColors.paleBgAlt;
    try { return Color(int.parse(p.colorCode!.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppColors.paleBgAlt; }
  }

  @override
  Widget build(BuildContext context) {
    if (pet == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.paleLine),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paleBgAlt,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    isFather ? '♂' : '♀',
                    style: TextStyle(
                      fontSize: 16,
                      color: isFather ? AppColors.petSkyInk : AppColors.petCoralInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFather ? '부 (수컷)' : '모 (암컷)',
                      style: const TextStyle(fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      '일련번호로 검색해 추가',
                      style: TextStyle(fontSize: 13, color: AppColors.paleInk2, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.search, color: AppColors.paleInk3, size: 20),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _bgOf(pet!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🦎', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet!.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${pet!.serialNo} · ${pet!.speciesName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.paleInk3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.paleInk3,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── 해칭일 입력 필드 (정밀도 선택 포함) ─────────────────────────────────────────

class _HatchDateField extends StatelessWidget {
  final String precision;          // 'DAY' or 'MONTH'
  final DateTime? date;            // DAY precision
  final int? year;                 // MONTH precision
  final int? month;                // MONTH precision
  final bool approximate;
  final void Function(String) onPrecisionChanged;
  final VoidCallback onPickDay;
  final VoidCallback onPickYearMonth;
  final void Function(bool) onApproximateChanged;
  final String Function(DateTime) fmtDate;

  const _HatchDateField({
    required this.precision,
    required this.date,
    required this.year,
    required this.month,
    required this.approximate,
    required this.onPrecisionChanged,
    required this.onPickDay,
    required this.onPickYearMonth,
    required this.onApproximateChanged,
    required this.fmtDate,
  });

  String get _displayText {
    if (precision == 'MONTH') {
      if (year != null && month != null) return '$year년 ${month}월';
      return '연·월 선택';
    } else {
      return date != null ? fmtDate(date!) : '날짜 선택';
    }
  }

  bool get _hasValue => precision == 'MONTH'
      ? (year != null && month != null)
      : date != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 정밀도 토글
        Container(
          decoration: BoxDecoration(
            color: AppColors.paleBgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.paleLine),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PrecisionTab(
                label: '연·월만',
                active: precision == 'MONTH',
                onTap: () => onPrecisionChanged('MONTH'),
              ),
              _PrecisionTab(
                label: '정확한 날짜',
                active: precision == 'DAY',
                onTap: () => onPrecisionChanged('DAY'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 날짜 선택 버튼
        GestureDetector(
          onTap: precision == 'MONTH' ? onPickYearMonth : onPickDay,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.paleInk2),
                const SizedBox(width: 10),
                Text(
                  _displayText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _hasValue ? AppColors.primary : AppColors.paleInk3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onApproximateChanged(!approximate),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: approximate ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: approximate ? AppColors.primary : AppColors.paleLine,
                    width: 1.5,
                  ),
                ),
                child: approximate
                    ? const Icon(Icons.check, size: 12, color: AppColors.paleBg)
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                '정확하지 않아요',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.paleInk2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrecisionTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PrecisionTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.paleInk2,
          ),
        ),
      ),
    );
  }
}

// ── 연·월 선택 바텀시트 ──────────────────────────────────────────────────────────

class _YearMonthPickerSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _YearMonthPickerSheet({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_YearMonthPickerSheet> createState() => _YearMonthPickerSheetState();
}

class _YearMonthPickerSheetState extends State<_YearMonthPickerSheet> {
  late int _year;
  late int _month;
  late final TextEditingController _yearCtrl;

  static const _monthLabels = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
    _yearCtrl = TextEditingController(text: '$_year');
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  void _commitYear() {
    final v = int.tryParse(_yearCtrl.text);
    final now = DateTime.now().year;
    if (v != null && v >= 1990 && v <= now) {
      setState(() => _year = v);
    } else {
      _yearCtrl.text = '$_year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(color: AppColors.paleLine, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: Row(
              children: [
                const Text(
                  '태어난 시기를 선택하세요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // 연도 선택
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _year > 1990 ? () => setState(() { _year--; _yearCtrl.text = '$_year'; }) : null,
                  child: Icon(Icons.chevron_left, size: 28,
                      color: _year > 1990 ? AppColors.primary : AppColors.paleLine),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _commitYear(),
                        onEditingComplete: _commitYear,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          suffixText: '년',
                          suffixStyle: TextStyle(fontSize: 15, color: AppColors.paleInk2, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _year < now.year ? () => setState(() { _year++; _yearCtrl.text = '$_year'; }) : null,
                  child: Icon(Icons.chevron_right, size: 28,
                      color: _year < now.year ? AppColors.primary : AppColors.paleLine),
                ),
              ],
            ),
          ),
          // 월 그리드
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isFuture = _year == now.year && m > now.month;
                final selected = _month == m;
                return GestureDetector(
                  onTap: isFuture ? null : () => setState(() => _month = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : isFuture
                              ? AppColors.paleBgAlt
                              : AppColors.card,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.paleLine,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _monthLabels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.paleBg
                              : isFuture
                                  ? AppColors.paleInk3
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // 확인 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, (_year, _month)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$_year년 ${_month}월 선택',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paleBg,
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
