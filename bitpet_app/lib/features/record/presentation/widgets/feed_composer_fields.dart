import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_input_styles.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../data/food_catalog.dart';

export '../../data/food_catalog.dart' show FeedFormData, FoodType, FeedingSupplement, FoodInputMode;

/// 급여 단일 아이템 컴포저 — FeedItemsEditor 내부 또는 단독 사용
/// onAdd != null → 하단에 "추가하기" 버튼 표시
class FeedComposerFields extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  final bool showMemo;
  final VoidCallback? onAdd;

  const FeedComposerFields({
    super.key,
    required this.form,
    required this.onChanged,
    this.bandColor = AppColors.feedBand,
    this.showMemo = true,
    this.onAdd,
  });

  void _selectType(FoodType? ft) {
    if (ft == null) return;
    onChanged(FeedFormData(
      foodType: ft,
      supplement: form.supplement,
      memo: form.memo,
    ));
  }

  /// 거식 전환 — 켜면 먹이 정보를 통째로 버리고 메모만 남긴다.
  /// (서버도 거식 행에는 food_type 을 저장하지 않으므로 남겨둘 이유가 없다)
  void _toggleRefused() {
    onChanged(form.isRefused
        ? FeedFormData(memo: form.memo)
        : FeedFormData(isRefused: true, memo: form.memo));
  }

  @override
  Widget build(BuildContext context) {
    final refused = form.isRefused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 거식 ────────────────────────────────────────────
        _RefusedToggle(active: refused, bandColor: bandColor, onTap: _toggleRefused),
        const SizedBox(height: 14),

        // 거식이면 종류·서브입력·영양제는 아예 사라지고 메모만 남는다
        if (!refused) ..._feedFields(),

        // ── 메모 ────────────────────────────────────────────
        if (showMemo) ...[
          if (!refused) const SizedBox(height: 14),
          _Label('메모', optional: true),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => onChanged(form.copyWith(memo: v)),
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppColors.primary),
            decoration: AppInputStyles.textarea(
              hintText: refused ? '거부 상황·컨디션 등 (선택)' : '특이사항 (선택)',
            ),
          ),
        ],

        // ── 추가하기 버튼 ────────────────────────────────────
        if (onAdd != null) ...[
          const SizedBox(height: 16),
          _AddButton(enabled: form.isValid, bandColor: bandColor, onTap: onAdd!),
        ],
      ],
    );
  }

  List<Widget> _feedFields() {
    return [
        // ── 피딩 종류 ─────────────────────────────────────────
        _Label('피딩 종류'),
        const SizedBox(height: 8),
        DropdownButtonFormField<FoodType>(
          value: form.foodType,
          decoration: InputDecoration(
            hintText: '종류 선택',
            hintStyle: TextStyle(fontSize: 14, color: AppColors.paleInk3, fontWeight: FontWeight.w500),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.paleLine),
            ),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.paleLine),
            ),
            focusedBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: bandColor, width: 1.5),
            ),
          ),
          items: FoodType.all.map((ft) => DropdownMenuItem(
            value: ft,
            child: Text(ft.label, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary,
            )),
          )).toList(),
          onChanged: _selectType,
          dropdownColor: AppColors.paleBg,
          iconEnabledColor: AppColors.paleInk2,
        ),

        // ── 서브 입력 ───────────────────────────────────────
        if (form.foodType != null) ...[
          const SizedBox(height: 14),
          _SubInput(form: form, onChanged: onChanged, bandColor: bandColor),
        ],

        // ── 영양제 ──────────────────────────────────────────
        const SizedBox(height: 14),
        _Label('영양제', optional: true),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          children: FeedingSupplement.values.map((s) {
            final sel = form.supplement == s;
            return GestureDetector(
              onTap: () => onChanged(form.copyWith(
                supplement: sel ? null : s,
              )),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.petLilac : AppColors.card,
                  border: Border.all(color: sel ? Colors.transparent : AppColors.paleLine),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(s.label,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: sel ? AppColors.primary : AppColors.paleInk2,
                    )),
              ),
            );
          }).toList(),
        ),
    ];
  }
}

// ── 거식 토글 ──────────────────────────────────────────────────────────────────
/// 폼 최상단. 켜면 아래 입력이 전부 사라지고 메모만 남는다.
class _RefusedToggle extends StatelessWidget {
  final bool active;
  final Color bandColor;
  final VoidCallback onTap;
  const _RefusedToggle({required this.active, required this.bandColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: active ? bandColor : AppColors.card,
        border: Border.all(color: active ? Colors.transparent : AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(children: [
        Icon(active ? Icons.check_box : Icons.check_box_outline_blank,
            size: 17, color: active ? AppColors.primary : AppColors.paleInk3),
        const SizedBox(width: 8),
        Text('거식',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? AppColors.primary : AppColors.paleInk2,
            )),
        const SizedBox(width: 8),
        Expanded(
          child: Text('먹이를 거부함 · 메모만 기록',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: active ? AppColors.primary.withValues(alpha: 0.7) : AppColors.paleInk3,
              )),
        ),
      ]),
    ),
  );
}

// ── 추가하기 버튼 ──────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final bool enabled;
  final Color bandColor;
  final VoidCallback onTap;
  const _AddButton({required this.enabled, required this.bandColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? bandColor : AppColors.paleBgAlt,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 15, color: enabled ? AppColors.primary : AppColors.paleInk3),
          const SizedBox(width: 6),
          Text('추가하기',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: enabled ? AppColors.primary : AppColors.paleInk3,
            )),
        ],
      ),
    ),
  );
}

// ── 레이블 ─────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final bool optional;
  const _Label(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2)),
    if (optional) ...[
      const SizedBox(width: 6),
      Text('OPTIONAL', style: AppTextStyles.mono(9, FontWeight.w700, color: AppColors.paleInk3)),
    ],
  ]);
}

// ── 서브 입력 ──────────────────────────────────────────────────────────────────
class _SubInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const _SubInput({required this.form, required this.onChanged, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    final ft = form.foodType!;
    return switch (ft.inputMode) {
      FoodInputMode.sizeCount   => _SizeCountInput(form: form, onChanged: onChanged, bandColor: bandColor),
      FoodInputMode.mlOrVolume  => _MlOrVolumeInput(form: form, onChanged: onChanged, bandColor: bandColor),
      FoodInputMode.volume      => _VolumeInput(form: form, onChanged: onChanged, bandColor: bandColor),
      FoodInputMode.custom      => _CustomTextInput(form: form, onChanged: onChanged, bandColor: bandColor),
    };
  }
}

// ── 사이즈 + 마릿수 ────────────────────────────────────────────────────────────
class _SizeCountInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const _SizeCountInput({required this.form, required this.onChanged, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    final sizes = form.foodType!.sizeOptions ?? [];
    final count = form.count ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('사이즈', optional: true),
        const SizedBox(height: 8),
        Wrap(spacing: 7, children: sizes.map((s) {
          final sel = form.sizeLabel == s;
          return GestureDetector(
            onTap: () => onChanged(form.copyWith(sizeLabel: sel ? null : s)),
            child: AppChip(
                label: s,
                selected: sel,
                selectedColor: bandColor,
                selectedTextColor: AppColors.primary),
          );
        }).toList()),
        const SizedBox(height: 12),
        _Label('마릿수', optional: true),
        const SizedBox(height: 8),
        _CountStepper(
          count: count,
          bandColor: bandColor,
          onChanged: (v) => onChanged(form.copyWith(count: v == 0 ? null : v)),
        ),
      ],
    );
  }
}

// ── ml 또는 용량 레이블 ─────────────────────────────────────────────────────────
class _MlOrVolumeInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const _MlOrVolumeInput({required this.form, required this.onChanged, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _ModeToggle(label: 'ml 직접입력', active: form.useMl, color: bandColor,
              onTap: () => onChanged(form.copyWith(useMl: true, sizeLabel: null, mlAmount: null))),
          const SizedBox(width: 8),
          _ModeToggle(label: '용량 선택', active: !form.useMl, color: bandColor,
              onTap: () => onChanged(form.copyWith(useMl: false, mlAmount: null, sizeLabel: null))),
        ]),
        const SizedBox(height: 10),
        if (form.useMl)
          _MlInput(ml: form.mlAmount, onChanged: (v) => onChanged(form.copyWith(mlAmount: v)))
        else
          _VolumeChips(
            options: form.foodType!.volumeOptions ?? [],
            selected: form.sizeLabel,
            color: bandColor,
            onSelect: (v) => onChanged(form.copyWith(sizeLabel: form.sizeLabel == v ? null : v)),
          ),
      ],
    );
  }
}

// ── 용량 레이블만 ──────────────────────────────────────────────────────────────
class _VolumeInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const _VolumeInput({required this.form, required this.onChanged, required this.bandColor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('용량', optional: true),
      const SizedBox(height: 8),
      Row(children: [
        _ModeToggle(label: '용량 선택', active: !form.useCustomAmount, color: bandColor,
            onTap: () => onChanged(form.copyWith(useCustomAmount: false, sizeLabel: null))),
        const SizedBox(width: 8),
        _ModeToggle(label: '직접입력', active: form.useCustomAmount, color: bandColor,
            onTap: () => onChanged(form.copyWith(useCustomAmount: true, sizeLabel: null))),
      ]),
      const SizedBox(height: 10),
      if (form.useCustomAmount)
        _AmountTextInput(
          // 칩↔직접입력을 오갈 때 이전 글자가 남지 않도록 모드를 키에 넣는다
          key: ValueKey('amt-${form.foodType!.code}'),
          initial: form.sizeLabel,
          hintText: '예: 반 스푼, 3알',
          onChanged: (v) => onChanged(form.copyWith(sizeLabel: v.isEmpty ? null : v)),
        )
      else
        _VolumeChips(
          options: form.foodType!.volumeOptions ?? [],
          selected: form.sizeLabel,
          color: bandColor,
          onSelect: (v) => onChanged(form.copyWith(sizeLabel: form.sizeLabel == v ? null : v)),
        ),
    ],
  );
}

// ── 직접입력 (이름 + 사이즈 + 마릿수) ──────────────────────────────────────────
/// 카탈로그에 없는 먹이. 이름만 직접 적을 뿐 사이즈·마릿수는 다른 먹이와 똑같이 받는다.
class _CustomTextInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const _CustomTextInput({required this.form, required this.onChanged, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    final sizes = form.foodType!.sizeOptions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('먹이 이름'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: form.customText,
          onChanged: (v) => onChanged(form.copyWith(customText: v)),
          autofocus: form.customText == null,
          maxLength: 50,
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '이름 직접 입력',
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: UnderlineInputBorder(borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: AppColors.paleLine)),
            enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: AppColors.paleLine)),
          ),
        ),
        const SizedBox(height: 12),
        _Label('사이즈', optional: true),
        const SizedBox(height: 8),
        Wrap(spacing: 7, children: sizes.map((s) {
          final sel = form.sizeLabel == s;
          return GestureDetector(
            onTap: () => onChanged(form.copyWith(sizeLabel: sel ? null : s)),
            child: AppChip(
                label: s,
                selected: sel,
                selectedColor: bandColor,
                selectedTextColor: AppColors.primary),
          );
        }).toList()),
        const SizedBox(height: 12),
        _Label('마릿수', optional: true),
        const SizedBox(height: 8),
        _CountStepper(
          count: form.count ?? 0,
          bandColor: bandColor,
          onChanged: (v) => onChanged(form.copyWith(count: v == 0 ? null : v)),
        ),
      ],
    );
  }
}

// ── 급여량 자유 입력 ───────────────────────────────────────────────────────────
class _AmountTextInput extends StatelessWidget {
  final String? initial;
  final String hintText;
  final ValueChanged<String> onChanged;
  const _AmountTextInput({super.key, required this.initial, required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initial,
    onChanged: onChanged,
    maxLength: kAmountTextMaxLength,
    style: const TextStyle(fontSize: 14, color: AppColors.primary),
    decoration: InputDecoration(
      hintText: hintText,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: UnderlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.paleLine)),
      enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.paleLine)),
    ),
  );
}

// ── 마릿수 스테퍼 ──────────────────────────────────────────────────────────────
class _CountStepper extends StatelessWidget {
  final int count;
  final Color bandColor;
  final ValueChanged<int> onChanged;
  const _CountStepper({required this.count, required this.bandColor, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.paleBg,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(children: [
          AppStepperButton('−',
              style: AppStepperStyle.plain,
              onTap: () { if (count > 0) onChanged(count - 1); }),
          Expanded(child: Center(child: Text('$count', style: AppTextStyles.mono(22, FontWeight.w700)))),
          AppStepperButton('＋',
              style: AppStepperStyle.plain,
              onTap: () => onChanged(count + 1)),
        ]),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, children: [1, 3, 5, 10].map((n) {
        final sel = count == n;
        return GestureDetector(
          onTap: () => onChanged(n),
          child: AppChip(
              label: '$n마리',
              selected: sel,
              selectedColor: bandColor,
              selectedTextColor: AppColors.primary),
        );
      }).toList()),
    ],
  );
}

// ── ml 직접입력 ────────────────────────────────────────────────────────────────
class _MlInput extends StatelessWidget {
  final double? ml;
  final ValueChanged<double?> onChanged;
  const _MlInput({required this.ml, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    style: const TextStyle(fontSize: 14, color: AppColors.primary),
    decoration: InputDecoration(
      hintText: '용량 (ml)',
      suffixText: 'ml',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: UnderlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.paleLine)),
      enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.paleLine)),
    ),
    onChanged: (v) => onChanged(double.tryParse(v)),
  );
}

// ── 용량 칩 목록 ───────────────────────────────────────────────────────────────
class _VolumeChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelect;
  const _VolumeChips({required this.options, required this.selected, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    children: options.map((o) => GestureDetector(
      onTap: () => onSelect(o),
      child: AppChip(
          label: o,
          selected: selected == o,
          selectedColor: color,
          selectedTextColor: AppColors.primary),
    )).toList(),
  );
}

// ── 모드 토글 버튼 ─────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _ModeToggle({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color : AppColors.card,
        border: Border.all(color: active ? Colors.transparent : AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: active ? AppColors.primary : AppColors.paleInk2,
      )),
    ),
  );
}

