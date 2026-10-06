import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
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

  /// 서버가 알려준 남은 등록 가능 수. **null = 모른다**(아직 못 받았거나 실패).
  /// 모를 때는 제한을 걸지 않는다 — 여유가 넉넉한 사람이 한 마리도 못 넣는 쪽이 더 나쁘다.
  int? _remainingSlots;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  /// 남은 수를 미리 받아 입력 자체를 막아둔다. 안 그러면 50마리를 적고 저장을 눌러
  /// 중간에 터지는데, 그때는 이미 몇 마리가 만들어진 뒤라 되돌리기도 애매하다.
  Future<void> _loadQuota() async {
    final remaining = await ref.read(petRepositoryProvider).fetchRemainingPetSlots();
    if (!mounted) return;
    setState(() {
      _remainingSlots = remaining;
      // 받아보니 이미 적어둔 수보다 적을 수 있다 (다른 기기에서 등록했거나 초기값 변경)
      if (_count > _countMax) _count = math.max(1, _countMax);
    });
  }

  /// 한 번에 넣을 수 있는 최대 마리수. 1회 상한(99)과 남은 자리 중 **작은 쪽**.
  int get _countMax {
    const perRun = _maxPerRun;
    final remaining = _remainingSlots;
    if (remaining == null) return perRun;
    return math.min(perRun, math.max(0, remaining));
  }

  /// 마리수 칸 밑에 붙는 안내. 남은 자리가 1회 상한보다 적으면 그걸 먼저 말한다 —
  /// "99까지 가능"이라고 써두고 막히면 안내가 거짓말이 된다.
  String get _countHint {
    final remaining = _remainingSlots;
    if (remaining != null && remaining <= 0) {
      return '등록 가능한 자리가 없어요 (최대 $_maxOwnedPets마리)';
    }
    if (remaining != null && remaining < _maxPerRun) {
      return '남은 자리 $remaining마리 (1인당 최대 $_maxOwnedPets마리)';
    }
    return '1회에 최대 $_maxPerRun마리까지 등록할 수 있어요';
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _species != null && _count >= 1 && _count <= _countMax && !_submitting;

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
        // 상한 초과처럼 사용자가 고칠 수 있는 상황은 서버 문장이 가장 정확하다.
        // 'DioException [bad response]...' 를 띄우던 자리다.
        final reason = serverMessageOf(e) ?? '오류가 발생했어요';
        // 몇 마리까지 들어갔는지를 먼저 말한다 — 일괄 등록은 중간에 멈출 수 있고,
        // 그걸 안 알려주면 목록을 열어 세어 봐야 안다.
        ToastMessage.show(
          context,
          successCount > 0 ? '$successCount마리까지 등록됐어요 — $reason' : reason,
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
                      hint: _countHint,
                      child: _CountStepper(
                        value: _count,
                        max: _countMax,
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

/// 1회 등록 상한. 100을 두 자리로 자른 게 아니라, **한 번에 만들면 되돌리기가
/// 힘든 양**의 선이다 — 잘못 적어 저장하면 하나씩 지워야 한다.
const int _maxPerRun = 99;

/// 1인당 소유 상한. 안내 문구에만 쓴다 — 실제 판정은 서버가 하고,
/// 남은 자리는 `/pets/quota` 가 계산해서 내려준다.
const int _maxOwnedPets = 100;

/// − / 숫자 / ＋. 가운데는 **직접 입력도 되는 칸**이다.
///
/// 버튼만 두면 30마리를 넣으려고 29번 눌러야 한다. 반대로 입력칸만 두면 한두 마리
/// 조정이 번거로워서 둘 다 남긴다. 키보드는 숫자만 뜨고(`TextInputType.number`),
/// 숫자 아닌 글자는 포매터가 애초에 받지 않는다 — 막은 뒤에 경고하는 것보다
/// 들어오지 않는 쪽이 설명할 게 없다.
class _CountStepper extends StatefulWidget {
  final int value;
  final int max;
  final void Function(int) onChanged;

  const _CountStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_CountStepper> createState() => _CountStepperState();
}

class _CountStepperState extends State<_CountStepper> {
  late final TextEditingController _ctrl =
      TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // 포커스가 빠질 때 비어 있으면 1로 되돌린다. 입력 중에 되돌리면
    // 지우자마자 1이 끼어들어 숫자를 바꿀 수가 없다.
    _focus.addListener(() {
      if (!_focus.hasFocus && _ctrl.text.trim().isEmpty) {
        _setText('${widget.value}');
      }
    });
  }

  @override
  void didUpdateWidget(_CountStepper old) {
    super.didUpdateWidget(old);
    // 버튼으로 바뀐 값·바깥에서 깎인 값(남은 자리)을 칸에 반영한다.
    // 입력 중인 숫자와 같으면 건드리지 않는다 — 커서가 튀어 버린다.
    if (int.tryParse(_ctrl.text) != widget.value) {
      _setText('${widget.value}');
    }
  }

  void _setText(String v) {
    _ctrl.text = v;
    _ctrl.selection = TextSelection.collapsed(offset: v.length);
  }

  void _onTyped(String raw) {
    if (raw.isEmpty) return;              // 지우는 중 — 아직 판정하지 않는다
    final n = int.tryParse(raw);
    if (n == null) return;
    // num.clamp 는 int 를 넣어도 num 을 돌려준다 — toInt() 없이는 컴파일이 안 된다
    final clamped = n.clamp(1, math.max(1, widget.max)).toInt();
    if (clamped != n) _setText('$clamped');   // 상한을 넘겨 적으면 바로 깎아 보여준다
    widget.onChanged(clamped);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDec = widget.value > 1;
    final canInc = widget.value < widget.max;
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        color: AppColors.surface,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        children: [
          _StepButton(
            label: '−',
            fontSize: 22,
            enabled: canDec,
            onTap: () => widget.onChanged(widget.value - 1),
            borderSide: const Border(right: BorderSide(color: AppColors.paleLine)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // 자릿수만큼만 차지하게 폭을 묶어 '마리'가 숫자에 붙어 보이게 한다
                SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: _onTyped,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),   // 두 자리면 99까지다
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
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
          _StepButton(
            label: '＋',
            fontSize: 18,
            enabled: canInc,
            onTap: () => widget.onChanged(widget.value + 1),
            borderSide: const Border(left: BorderSide(color: AppColors.paleLine)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool enabled;
  final Border borderSide;
  final VoidCallback onTap;

  const _StepButton({
    required this.label,
    required this.fontSize,
    required this.enabled,
    required this.borderSide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: borderSide),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.primary : AppColors.paleLine,
          ),
        ),
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
