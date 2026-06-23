import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../data/pet_repository.dart';
import '../providers/pet_provider.dart';
import 'widgets/species_bottom_sheet.dart';
import 'widgets/parent_pet_bottom_sheet.dart';

// ════════════════════════════════════════════════════════════════
// 개체 일괄 등록 화면
// 필수: 종, 마리수 / 선택: 이름 접두어, 성별, 해칭일, 입양일, 부모개체
// ════════════════════════════════════════════════════════════════

class PetBulkFormScreen extends ConsumerStatefulWidget {
  const PetBulkFormScreen({super.key});

  @override
  ConsumerState<PetBulkFormScreen> createState() => _PetBulkFormScreenState();
}

class _PetBulkFormScreenState extends ConsumerState<PetBulkFormScreen> {
  // ── 필수 ──────────────────────────────────────────────────────────────────
  Species? _species;
  int _count = 1;

  // ── 선택 ──────────────────────────────────────────────────────────────────
  final _prefixCtrl = TextEditingController();
  String _gender = 'UNKNOWN';
  DateTime? _hatchDate;
  DateTime? _adoptDate;
  Pet? _fatherPet;
  Pet? _motherPet;

  bool _submitting = false;

  @override
  void dispose() {
    _prefixCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _species != null && _count >= 1 && !_submitting;

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isHatch}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isHatch) _hatchDate = picked;
        else _adoptDate = picked;
      });
    }
  }

  Future<void> _openSpeciesSheet() async {
    final result = await showModalBottomSheet<Species>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpeciesBottomSheet(initialSelection: _species),
    );
    if (result != null) setState(() => _species = result);
  }

  Future<void> _openParentSheet({required bool isFather}) async {
    final result = await showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPetBottomSheet(
        isFather: isFather,
        initialSelection: isFather ? _fatherPet : _motherPet,
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

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final repo = ref.read(petRepositoryProvider);
    final prefix = _prefixCtrl.text.trim().isNotEmpty
        ? _prefixCtrl.text.trim()
        : _species!.nameKo;

    int successCount = 0;
    try {
      for (int i = 0; i < _count; i++) {
        final name = _count == 1 ? prefix : '$prefix ${i + 1}';
        await repo.createPet(CreatePetRequest(
          speciesId: _species!.id,
          name: name,
          gender: _gender,
          hatchingDate: _hatchDate != null ? _isoDate(_hatchDate!) : null,
          hatchingDatePrecision: _hatchDate != null ? 'DAY' : null,
          adoptionDate: _adoptDate != null ? _isoDate(_adoptDate!) : null,
          fatherPetId: _fatherPet?.id,
          motherPetId: _motherPet?.id,
        ));
        successCount++;
      }
      ref.invalidate(petListProvider);
      if (mounted) {
        ToastMessage.show(
          context,
          '$successCount마리 등록 완료!',
          type: ToastType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          successCount > 0 ? '$successCount마리 등록 후 오류 발생' : '등록 실패: $e',
          type: ToastType.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 바 ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('입력 내용을 삭제할까요?',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            content: const Text('지금 나가면 입력한 정보가 모두 삭제돼요.',
                                style: TextStyle(fontSize: 14, height: 1.5)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('계속 작성',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('나가기',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) context.pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.paleInk2,
                      ),
                      child: const Text('뒤로',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.paleInk2)),
                    ),
                  ),
                  const Expanded(
                    child: Text('일괄 개체 등록',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 68),
                ],
              ),
            ),

            // ── 본문 ──────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 필수 섹션 ────────────────────────────────────────────
                    _SectionHeader(label: '필수 항목'),
                    const SizedBox(height: 12),

                    // 종 선택
                    _FieldLabel(label: '종', required: true),
                    const SizedBox(height: 6),
                    _TapField(
                      value: _species?.nameKo,
                      placeholder: '종을 선택하세요',
                      icon: Icons.search,
                      onTap: _openSpeciesSheet,
                    ),
                    const SizedBox(height: 16),

                    // 마리수
                    _FieldLabel(label: '마리수', required: true),
                    const SizedBox(height: 6),
                    _CountStepper(
                      value: _count,
                      onChanged: (v) => setState(() => _count = v),
                    ),
                    const SizedBox(height: 24),

                    // ── 선택 섹션 ────────────────────────────────────────────
                    _SectionHeader(label: '선택 항목', muted: true),
                    const SizedBox(height: 12),

                    // 이름 접두어
                    _FieldLabel(label: '이름 접두어', required: false),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.paleLine),
                      ),
                      child: TextField(
                        controller: _prefixCtrl,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: _species != null
                              ? '비워두면 "${_species!.nameKo}"으로 자동 설정'
                              : '예: 차우, 개구리 등',
                          hintStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.paleInk3),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_count > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '예: ${_prefixCtrl.text.isEmpty ? (_species?.nameKo ?? '이름') : _prefixCtrl.text} 1, ${_prefixCtrl.text.isEmpty ? (_species?.nameKo ?? '이름') : _prefixCtrl.text} 2 …',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.paleInk3,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 성별
                    _FieldLabel(label: '성별', required: false),
                    const SizedBox(height: 6),
                    _GenderPicker(
                      value: _gender,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 16),

                    // 해칭일
                    _FieldLabel(label: '해칭일', required: false),
                    const SizedBox(height: 6),
                    _TapField(
                      value: _hatchDate != null ? _fmtDate(_hatchDate!) : null,
                      placeholder: '해칭일 선택 (선택)',
                      icon: Icons.egg_outlined,
                      onTap: () => _pickDate(isHatch: true),
                      trailing: _hatchDate != null
                          ? GestureDetector(
                              onTap: () => setState(() => _hatchDate = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.paleInk3),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 입양일
                    _FieldLabel(label: '입양일', required: false),
                    const SizedBox(height: 6),
                    _TapField(
                      value: _adoptDate != null ? _fmtDate(_adoptDate!) : null,
                      placeholder: '입양일 선택 (선택)',
                      icon: Icons.home_outlined,
                      onTap: () => _pickDate(isHatch: false),
                      trailing: _adoptDate != null
                          ? GestureDetector(
                              onTap: () => setState(() => _adoptDate = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.paleInk3),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 부모 개체
                    _FieldLabel(label: '부모 개체', required: false),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _TapField(
                            value: _fatherPet?.name,
                            placeholder: '아버지 개체',
                            icon: Icons.male,
                            onTap: () => _openParentSheet(isFather: true),
                            trailing: _fatherPet != null
                                ? GestureDetector(
                                    onTap: () =>
                                        setState(() => _fatherPet = null),
                                    child: const Icon(Icons.close,
                                        size: 16, color: AppColors.paleInk3),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TapField(
                            value: _motherPet?.name,
                            placeholder: '어머니 개체',
                            icon: Icons.female,
                            onTap: () => _openParentSheet(isFather: false),
                            trailing: _motherPet != null
                                ? GestureDetector(
                                    onTap: () =>
                                        setState(() => _motherPet = null),
                                    child: const Icon(Icons.close,
                                        size: 16, color: AppColors.paleInk3),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── 등록 버튼 ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
              ),
              child: GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _canSubmit ? AppColors.primary : AppColors.paleLine,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _submitting
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.paleBg),
                          ),
                        )
                      : Text(
                          _count == 1 ? '개체 등록' : '$_count마리 일괄 등록',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _canSubmit
                                ? AppColors.paleBg
                                : AppColors.paleInk3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 공용 소형 위젯
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool muted;
  const _SectionHeader({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: muted ? AppColors.paleInk3 : AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: muted ? AppColors.paleInk3 : AppColors.primary,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.paleLineSoft),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.petCoralInk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '필수',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.petCoralInk,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TapField({
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: hasValue ? AppColors.primary.withValues(alpha: 0.25) : AppColors.paleLine,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: hasValue ? AppColors.primary : AppColors.paleInk3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasValue ? AppColors.primary : AppColors.paleInk3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!
            else const Icon(Icons.chevron_right,
                size: 16, color: AppColors.paleInk3),
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _CountStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: value > 1 ? () => onChanged(value - 1) : null,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.paleLine)),
              ),
              child: Text(
                '−',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: value > 1 ? AppColors.primary : AppColors.paleLine,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '마리',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paleInk2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: value < 50 ? () => onChanged(value + 1) : null,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.paleLine)),
              ),
              child: Text(
                '＋',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: value < 50 ? AppColors.primary : AppColors.paleLine,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderPicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _GenderPicker({required this.value, required this.onChanged});

  static const _options = [
    ('UNKNOWN', '미상', AppColors.paleInk3),
    ('MALE', '수컷', AppColors.petSkyInk),
    ('FEMALE', '암컷', AppColors.petCoralInk),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((o) {
        final (val, label, ink) = o;
        final on = value == val;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: val == _options.last.$1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onChanged(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: on ? ink.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: on ? ink : AppColors.paleLine,
                    width: on ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: on ? ink : AppColors.paleInk2,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
