import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../data/pet_repository.dart';
import '../providers/pet_provider.dart';
import 'widgets/species_bottom_sheet.dart';
import 'widgets/parent_pet_bottom_sheet.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';

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
  PetCard? _fatherPet;
  PetCard? _motherPet;

  bool _submitting = false;

  @override
  void dispose() {
    _prefixCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _species != null && _count >= 1 && !_submitting;

  /// 실제로 붙는 접두어. 비워두면 종 이름이 들어간다.
  ///
  /// 등록 로직과 미리보기가 **같은 값을 봐야 한다** — 따로 계산하면 예시와
  /// 실제로 저장되는 이름이 갈라져도 아무도 모른다.
  String get _effectivePrefix {
    final typed = _prefixCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return _species?.nameKo ?? '이름';
  }

  /// 확인을 받을 만한 입력이 있는지. 아무것도 안 건드렸으면 묻지 않는다 —
  /// 잘못 들어온 사람에게까지 모달을 띄우면 방해일 뿐이다.
  bool get _hasInput =>
      _species != null ||
      _count > 1 ||
      _prefixCtrl.text.trim().isNotEmpty ||
      _gender != 'UNKNOWN' ||
      _hatchDate != null ||
      _adoptDate != null ||
      _fatherPet != null ||
      _motherPet != null;

  /// 뒤로 — 입력한 게 있으면 확인을 받는다.
  ///
  /// 문구·모양은 StepShell 의 취소 확인과 **같은 것을 쓴다**. 머티리얼 기본
  /// AlertDialog 를 쓰던 때는 모서리·버튼 색이 앱의 다른 확인 모달과 전부
  /// 달라서, 같은 질문을 두 가지 모양으로 하는 셈이었다.
  Future<void> _confirmExit() async {
    if (!_hasInput) {
      context.pop();
      return;
    }
    final ok = await ConfirmModal.show(
      context,
      title: '나가시겠어요?',
      message: '저장되지 않은 정보가 모두 삭제돼요.',
      confirmLabel: '나가기',
      cancelLabel: '계속 작성',
      isDangerous: true,
    );
    if (ok && mounted) context.pop();
  }

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
    final result = await showModalBottomSheet<PetCard>(
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
    final prefix = _effectivePrefix;

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
          fatherPetId: _fatherPet?.petId,
          motherPetId: _motherPet?.petId,
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
            // 제목은 **왼쪽 고정**, '뒤로'는 오른쪽 — StepShell 헤더와 같은 문법이다.
            // 개체 등록 폼에서 넘어오는 화면이라 둘의 머리가 다르면 같은 흐름
            // 중간에 다른 앱이 끼어든 것처럼 보인다.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, AppSpacing.sm, 12, AppSpacing.xs),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('일괄 개체 등록',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.primary,
                                letterSpacing: -0.2)),
                        SizedBox(height: 2),
                        Text('같은 조건으로 한 번에',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.paleInk3)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _confirmExit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: AppColors.paleInk2,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd),
                    ),
                    child: const Text('뒤로',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.paleInk2)),
                  ),
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
                    // ── 필수 항목 ───────────────────────────────────────────
                    const _SectionHeader(label: '필수 항목'),
                    const SizedBox(height: 16),

                    SField(
                      label: '종',
                      child: _TapField(
                        value: _species?.nameKo,
                        placeholder: '종을 선택하세요',
                        icon: Icons.search,
                        onTap: _openSpeciesSheet,
                      ),
                    ),

                    SField(
                      label: '마리수',
                      hint: '최대 50마리',
                      child: _CountStepper(
                        value: _count,
                        onChanged: (v) => setState(() => _count = v),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── 선택 항목 ───────────────────────────────────────────
                    const _SectionHeader(label: '선택 항목', muted: true),
                    const SizedBox(height: 16),

                    SField(
                      label: '이름 접두어',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PaleTextField(
                            controller: _prefixCtrl,
                            placeholder: _species != null
                                ? '비워두면 "${_species!.nameKo}"으로 자동 설정'
                                : '예: 차우, 개구리 등',
                            // 아래 예시가 입력에 따라 움직여야 한다 — 예전엔
                            // onChanged 가 없어서 다 적어도 예시가 그대로였다.
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_count > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                '예: $_effectivePrefix 1, $_effectivePrefix 2 …',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.paleInk3),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SField(
                      label: '성별',
                      child: _GenderPicker(
                        value: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),

                    SField(
                      label: '해칭일',
                      child: _TapField(
                        value: _hatchDate != null ? _fmtDate(_hatchDate!) : null,
                        placeholder: '해칭일 선택',
                        icon: Icons.egg_outlined,
                        onTap: () => _pickDate(isHatch: true),
                        onClear: () => setState(() => _hatchDate = null),
                      ),
                    ),

                    SField(
                      label: '입양일',
                      child: _TapField(
                        value: _adoptDate != null ? _fmtDate(_adoptDate!) : null,
                        placeholder: '입양일 선택',
                        icon: Icons.home_outlined,
                        onTap: () => _pickDate(isHatch: false),
                        onClear: () => setState(() => _adoptDate = null),
                      ),
                    ),

                    SField(
                      label: '부모 개체',
                      hint: '등록되는 전원에게 적용',
                      child: Row(
                        children: [
                          Expanded(
                            child: _TapField(
                              value: _fatherPet?.name,
                              placeholder: '아버지',
                              icon: Icons.male,
                              // 필드를 누르면 시트가 다시 열려 **다른 개체로 바꿀 수 있고**,
                              // X 를 누르면 비워진다. 시트는 취소 시 null 을 팝하므로
                              // 거기서는 해제가 성립하지 않는다 — 비우기는 여기 X 가 유일하다.
                              onTap: () => _openParentSheet(isFather: true),
                              onClear: () => setState(() => _fatherPet = null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TapField(
                              value: _motherPet?.name,
                              placeholder: '어머니',
                              icon: Icons.female,
                              onTap: () => _openParentSheet(isFather: false),
                              onClear: () => setState(() => _motherPet = null),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── 등록 버튼 ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  20, AppSpacing.md, 20, AppSpacing.xxl),
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
              ),
              child: GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    // 각진 버튼 하나만 남아 있었다 — 다른 화면의 제출 버튼은 전부 brMd 다
                    borderRadius: AppRadius.brMd,
                    color: _canSubmit ? AppColors.primary : AppColors.paleLine,
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
            borderRadius: BorderRadius.circular(2),
            color: muted ? AppColors.paleInk3 : AppColors.primary,
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

class _TapField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  /// 값을 비우는 콜백. 주면 값이 있을 때 오른쪽에 X 가 뜬다.
  ///
  /// ⚠️ 위젯(trailing)이 아니라 **콜백**을 받는 이유: 예전엔 호출부가
  /// `GestureDetector(child: Icon(size: 16))` 를 끼워 넣었는데, 맨 `Icon` 은
  /// 16px 밖에 안 되고 기본 `deferToChild` 라 탭이 거의 바깥 필드로 새서
  /// **비우려고 누르면 선택 시트가 열렸다**. 히트 영역을 위젯 안에서 책임진다.
  final VoidCallback? onClear;

  const _TapField({
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          color: AppColors.surface,
          border: Border.all(
            color: hasValue ? AppColors.primary.withValues(alpha: 0.25) : AppColors.paleLine,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: hasValue ? AppColors.primary : AppColors.paleInk3),
            const SizedBox(width: 8),
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
            if (hasValue && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.paleInk3,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              )
            else
              const AppIcon(AppIcons.chevronRight,
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
        borderRadius: AppRadius.brMd,
        color: AppColors.surface,
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
                  borderRadius: AppRadius.brMd,
                  color: on ? ink.withValues(alpha: 0.12) : AppColors.surface,
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
