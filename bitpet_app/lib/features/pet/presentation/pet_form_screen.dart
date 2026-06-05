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
  String _colorKey = 'coral';
  final _nameCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _memoCtrl   = TextEditingController();

  Species? _species;
  String? _morphText;
  String _gender = '수컷';
  DateTime? _hatchDate;
  bool _hatchUnknown = false;
  DateTime? _adoptDate;
  bool _adoptUnknown = false;
  String _weightUnit = 'g';
  Pet? _fatherPet;
  Pet? _motherPet;

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
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
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
        _morphText = null;
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
        if (isHatching) { _hatchDate = picked; _hatchUnknown = false; }
        else { _adoptDate = picked; _adoptUnknown = false; }
      });
    }
  }

  Future<void> _openMorphInput() async {
    final ctrl = TextEditingController(text: _morphText);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('모프 직접 입력',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '모프명을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _morphText = result.isEmpty ? null : result);
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

    await ref.read(petListProvider.notifier).add(
      CreatePetRequest(
        speciesId: _species!.id,
        name: _nameCtrl.text.trim(),
        gender: _gender == '수컷' ? 'MALE' : _gender == '암컷' ? 'FEMALE' : 'UNKNOWN',
        colorCode: _selectedHex,
        morphText: _morphText,
        hatchingDate: _hatchUnknown ? null : fmt(_hatchDate),
        adoptionDate: _adoptUnknown ? null : fmt(_adoptDate),
        currentWeightG: weightG,
        fatherPetId: _fatherPet?.id,
        motherPetId: _motherPet?.id,
        description: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      ),
    );

    if (mounted) {
      ToastMessage.show(context, '개체가 등록되었습니다!', type: ToastType.success);
      context.pop();
    }
  }

  // ── 날짜 포맷 ──────────────────────────────────────────────────────────────
  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  // ── 스텝 빌드 ─────────────────────────────────────────────────────────────
  List<StepConfig> get _steps => [
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
          SField(
            label: '모프',
            hint: _species == null ? '종 먼저' : null,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_morphText != null)
                  Chip(
                    label: Text(_morphText!, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.paleBgAlt,
                    side: const BorderSide(color: AppColors.paleLine),
                    onDeleted: () => setState(() => _morphText = null),
                    deleteIconColor: AppColors.paleInk2,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                GestureDetector(
                  onTap: _openMorphInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.paleLine),
                    ),
                    child: const Text(
                      '+ 직접 입력',
                      style: TextStyle(fontSize: 12, color: AppColors.paleInk2, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // ── Step 3: 성별+날짜 ────────────────────────────────────────────────────
    StepConfig(
      title: '성별과 날짜',
      desc: '모르는 날짜는 "모르겠어요"로 비워둘 수 있어요.',
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
            child: _DateField(
              date: _hatchDate,
              unknown: _hatchUnknown,
              onTap: () => _pickDate(isHatching: true),
              onUnknownChanged: (v) => setState(() {
                _hatchUnknown = v;
                if (v) _hatchDate = null;
              }),
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
      render: (_) => SField(
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
    ),

    // ── Step 6: 확인 ─────────────────────────────────────────────────────────
    StepConfig(
      title: '등록 내용을 확인하세요',
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
            StepSummaryRow(k: '모프', v: _morphText ?? '', muted: _morphText == null),
          ]),
          StepSummaryGroup(label: '성별·날짜', step: 2, rows: [
            StepSummaryRow(k: '성별', v: _gender),
            StepSummaryRow(
              k: '해칭일',
              v: _hatchUnknown ? '모름' : (_hatchDate != null ? _fmtDate(_hatchDate!) : ''),
              muted: _hatchUnknown || _hatchDate == null,
            ),
            StepSummaryRow(
              k: '입양일',
              v: _adoptUnknown ? '모름' : (_adoptDate != null ? _fmtDate(_adoptDate!) : ''),
              muted: _adoptUnknown || _adoptDate == null,
            ),
          ]),
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
          StepSummaryGroup(label: '메모', step: 4, rows: [
            StepSummaryRow(k: '메모', v: _memoCtrl.text, muted: _memoCtrl.text.isEmpty),
          ]),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
