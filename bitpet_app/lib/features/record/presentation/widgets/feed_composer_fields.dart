import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_input_styles.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../data/food_catalog.dart';
import '../../../../core/theme/app_dimens.dart';

export '../../data/food_catalog.dart' show FeedFormData, FoodType, FeedingSupplement, FoodInputMode;

/// 급여 단일 아이템 컴포저 — FeedItemsEditor 내부 또는 단독 사용
/// onAdd != null → 하단에 "추가하기" 버튼 표시
class FeedComposerFields extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  final bool showMemo;
  final VoidCallback? onAdd;

  /// 거식 체크박스를 이 안에 그릴지.
  /// `FeedItemsEditor` 는 거식을 '입력하다가 추가하는 항목'이 아니라 **체크하면 그걸로 끝**인
  /// 상태로 다루므로 체크박스를 바깥에서 직접 들고 있다 — 그때만 false.
  final bool showRefused;

  const FeedComposerFields({
    super.key,
    required this.form,
    required this.onChanged,
    this.bandColor = AppColors.feedBand,
    this.showMemo = true,
    this.onAdd,
    this.showRefused = true,
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
        if (showRefused) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: RefusedCheckbox(
                active: refused, bandColor: bandColor, onTap: _toggleRefused),
          ),
          const SizedBox(height: 16),
        ],

        // 거식이면 종류·서브입력·영양제는 아예 사라지고 메모만 남는다
        if (!refused) ..._feedFields(),

        // ── 메모 ────────────────────────────────────────────
        if (showMemo) ...[
          if (!refused) const SizedBox(height: 20),
          FeedFieldLabel('메모', optional: true),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => onChanged(form.copyWith(memo: v)),
            maxLines: 2,
            style: AppTextStyles.body,
            decoration: AppInputStyles.textarea(
              hintText: refused ? '거부 상황·컨디션 등 (선택)' : '특이사항 (선택)',
            ),
          ),
        ],

        // ── 추가하기 버튼 ────────────────────────────────────
        // 거식은 '담아서 추가하는' 항목이 아니라 체크 자체가 기록이다 — 버튼을 두지 않는다
        if (onAdd != null && !refused) ...[
          const SizedBox(height: 20),
          _AddButton(enabled: form.isValid, bandColor: bandColor, onTap: onAdd!),
        ],
      ],
    );
  }

  List<Widget> _feedFields() {
    return [
        // ── 급여 종류 ─────────────────────────────────────────
        FeedFieldLabel('급여 종류'),
        const SizedBox(height: 8),
        DropdownButtonFormField<FoodType>(
          value: form.foodType,
          // 손으로 그린 밑줄·힌트였다 — 같은 시트의 다른 입력칸과 테두리
          // 굵기·색이 미묘하게 달라 한 폼으로 안 읽혔다.
          decoration: AppInputStyles.textarea(hintText: '종류 선택'),
          items: FoodType.all.map((ft) => DropdownMenuItem(
            value: ft,
            child: Text(ft.label, style: AppTextStyles.bodyBold),
          )).toList(),
          onChanged: _selectType,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.ink3,
        ),

        // ── 서브 입력 ───────────────────────────────────────
        if (form.foodType != null) ...[
          const SizedBox(height: 16),
          FeedSubInput(form: form, onChanged: onChanged, bandColor: bandColor),
        ],

        // ── 영양제 ──────────────────────────────────────────
        const SizedBox(height: 16),
        FeedFieldLabel('영양제', optional: true),
        const SizedBox(height: 8),
        FeedSupplementChips(
          selected: form.supplement,
          onSelect: (s) => onChanged(form.copyWith(supplement: s)),
        ),
    ];
  }
}

// ── 영양제 칩 ──────────────────────────────────────────────────────────────────
/// 단일 선택. 고른 걸 다시 누르면 해제된다 (`FeedingSupplement?`).
class FeedSupplementChips extends StatelessWidget {
  final FeedingSupplement? selected;
  final ValueChanged<FeedingSupplement?> onSelect;
  const FeedSupplementChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  // 손으로 그린 칩이었다 — 옆의 사이즈·마릿수 칩(공용 [AppChip])과 색·여백이
  // 미묘하게 달라 같은 줄에서 두 종류로 보였다. 같은 위젯을 쓴다.
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: FeedingSupplement.values.map((s) {
      final sel = selected == s;
      return AppChip(
        label: s.label,
        selected: sel,
        onTap: () => onSelect(sel ? null : s),
        selectedColor: AppColors.brandTint,
        selectedTextColor: AppColors.brandTintInk,
      );
    }).toList(),
  );
}

// ── 급여 종류 칩 그리드 ────────────────────────────────────────────────────────
/// 드롭다운의 대체품이지만 **아무 데서나 쓰면 안 된다.**
///
/// 칩 10개는 세 줄을 먹는다. 바텀시트 본문에 그대로 놓으면 지금 드롭다운일 때보다
/// 시트가 더 길어진다 — 화면을 새로 쓰는 자리(모달)에서만 값을 한다.
/// 시트 안에서는 [FeedComposerFields] 의 드롭다운이 여전히 맞다.
class FeedTypeChips extends StatelessWidget {
  final FoodType? selected;
  final ValueChanged<FoodType> onSelect;
  final Color bandColor;
  const FeedTypeChips({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.bandColor,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    // 선택색은 **먹이 카테고리색(복숭아 `feedBand`)이 아니라 브랜드 틴트**다.
    // 카테고리색은 "이 기록이 급여다"를 말하는 띠 색이고, 칩의 선택색은
    // "내가 지금 이걸 골랐다"를 말한다 — 축이 다르다. 게다가 `feedBand` 는
    // #EEECE6 베이지라 흰 칩과 거의 구분이 안 가서 고른 티가 안 났다.
    children: FoodType.all.map((ft) => GestureDetector(
      onTap: () => onSelect(ft),
      child: AppChip(
          label: ft.label,
          selected: selected == ft,
          selectedColor: AppColors.brandTint,
          selectedTextColor: AppColors.brandTintInk),
    )).toList(),
  );
}

// ── 거식 체크박스 ──────────────────────────────────────────────────────────────
/// 폼 최상단. 체크하면 아래 입력이 전부 사라지고 그대로 거식으로 기록된다.
///
/// 원래는 "먹이를 거부함 · 메모만 기록" 부연설명을 옆에 달아 **가로 한 줄을 통째로**
/// 쓰는 박스였다. 거식은 어쩌다 한 번 쓰는 항목인데 매번 제일 크고 넓은 자리를
/// 차지하니 폼이 복잡해 보이기만 했다. 글자 폭에 맞춘 작은 칩으로 줄인다.
class RefusedCheckbox extends StatelessWidget {
  final bool active;
  final Color bandColor;
  final VoidCallback onTap;
  const RefusedCheckbox({
    super.key,
    required this.active,
    required this.bandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      // ⚠️ 켜진 모양을 다른 칩과 **같게 두지 않는다.** 거식은 '골랐다'가 아니라
      // "안 먹었다"는 사실이고, 브랜드 틴트로 칠하면 잘한 선택처럼 읽힌다.
      // 빨간 테두리+글씨로 '주의 상태'로만 표시한다(채움 없음).
      decoration: BoxDecoration(
        color: active ? AppColors.bg : AppColors.surface,
        border: Border.all(
            color: active ? AppColors.error : AppColors.line,
            width: active ? 1.5 : 1),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_box : Icons.check_box_outline_blank,
              size: AppIconSize.sm,
              color: active ? AppColors.error : AppColors.ink3),
          const SizedBox(width: AppSpacing.sm),
          Text('거식',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: active ? AppColors.error : AppColors.ink2,
              )),
        ],
      ),
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
  // 손으로 그린 버튼이었다(타입색 채움 + 12px 글자). 주 동작의 생김새를
  // 화면마다 다르게 두지 않는다 — 테마 버튼 그대로, 높이는 시트의 52px.
  // 폭이 유한한 자리(Column 의 stretch 자식)라 테마의 무한 minWidth 가
  // 문제되지 않는다.
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.add, size: AppIconSize.md),
      label: const Text('추가하기'),
    ),
  );
}

// ── 레이블 ─────────────────────────────────────────────────────────────────────
class FeedFieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const FeedFieldLabel(this.text, {this.optional = false});

  @override
  // 'OPTIONAL' 9px mono 였다 — 본문 최소(12px)에 한참 못 미치고 한글 화면에
  // 영문 라벨만 섞여 튀었다. 아코디언의 '선택' 과 같은 표기로 맞춘다.
  Widget build(BuildContext context) => Row(children: [
    Text(text,
        style: AppTextStyles.label.copyWith(color: AppColors.ink2)),
    if (optional) ...[
      const SizedBox(width: AppSpacing.sm),
      Text('선택', style: AppTextStyles.label),
    ],
  ]);
}

// ── 서브 입력 ──────────────────────────────────────────────────────────────────
class FeedSubInput extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;
  const FeedSubInput({
    super.key,
    required this.form,
    required this.onChanged,
    required this.bandColor,
  });

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
        FeedFieldLabel('사이즈', optional: true),
        const SizedBox(height: 8),
        Wrap(spacing: 7, children: sizes.map((s) {
          final sel = form.sizeLabel == s;
          return GestureDetector(
            onTap: () => onChanged(form.copyWith(sizeLabel: sel ? null : s)),
            child: AppChip(
                label: s,
                selected: sel,
                selectedColor: AppColors.brandTint,
                selectedTextColor: AppColors.brandTintInk),
          );
        }).toList()),
        const SizedBox(height: 12),
        FeedFieldLabel('마릿수', optional: true),
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
          _ModeToggle(label: 'ml 직접입력', active: form.useMl,
              onTap: () => onChanged(form.copyWith(useMl: true, sizeLabel: null, mlAmount: null))),
          const SizedBox(width: 8),
          _ModeToggle(label: '용량 선택', active: !form.useMl,
              onTap: () => onChanged(form.copyWith(useMl: false, mlAmount: null, sizeLabel: null))),
        ]),
        const SizedBox(height: 8),
        if (form.useMl)
          _MlInput(ml: form.mlAmount, onChanged: (v) => onChanged(form.copyWith(mlAmount: v)))
        else
          _VolumeChips(
            options: form.foodType!.volumeOptions ?? [],
            selected: form.sizeLabel,
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
      FeedFieldLabel('용량', optional: true),
      const SizedBox(height: 8),
      Row(children: [
        _ModeToggle(label: '용량 선택', active: !form.useCustomAmount,
            onTap: () => onChanged(form.copyWith(useCustomAmount: false, sizeLabel: null))),
        const SizedBox(width: 8),
        _ModeToggle(label: '직접입력', active: form.useCustomAmount,
            onTap: () => onChanged(form.copyWith(useCustomAmount: true, sizeLabel: null))),
      ]),
      const SizedBox(height: 8),
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
        FeedFieldLabel('먹이 이름'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: form.customText,
          onChanged: (v) => onChanged(form.copyWith(customText: v)),
          // 자동 포커스를 주지 않는다. '직접입력' 칩을 누른 순간 키보드가 올라오면
          // 화면이 절반으로 접히면서 방금 고른 칩도, 아래 사이즈·마릿수도 밀려나
          // 시점이 통째로 바뀐다. 칩을 고르는 것과 이름을 적는 것은 별개의 동작이라
          // 사용자가 입력란을 직접 누를 때 키보드가 올라오는 편이 덜 어지럽다.
          maxLength: 50,
          style: AppTextStyles.body,
          decoration: AppInputStyles.textarea(hintText: '이름 직접 입력')
              .copyWith(counterText: ''),
        ),
        const SizedBox(height: 12),
        FeedFieldLabel('사이즈', optional: true),
        const SizedBox(height: 8),
        Wrap(spacing: 7, children: sizes.map((s) {
          final sel = form.sizeLabel == s;
          return GestureDetector(
            onTap: () => onChanged(form.copyWith(sizeLabel: sel ? null : s)),
            child: AppChip(
                label: s,
                selected: sel,
                selectedColor: AppColors.brandTint,
                selectedTextColor: AppColors.brandTintInk),
          );
        }).toList()),
        const SizedBox(height: 12),
        FeedFieldLabel('마릿수', optional: true),
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
    style: AppTextStyles.body,
    decoration: AppInputStyles.textarea(hintText: hintText)
        .copyWith(counterText: ''),
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
          color: AppColors.canvas,
          border: Border.all(color: AppColors.line),
          borderRadius: AppRadius.brMd,
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
              selectedColor: AppColors.brandTint,
              selectedTextColor: AppColors.brandTintInk),
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
    style: AppTextStyles.body,
    decoration: AppInputStyles.textarea(hintText: '용량 (ml)')
        .copyWith(suffixText: 'ml'),
    onChanged: (v) => onChanged(double.tryParse(v)),
  );
}

// ── 용량 칩 목록 ───────────────────────────────────────────────────────────────
class _VolumeChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _VolumeChips(
      {required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    children: options.map((o) => GestureDetector(
      onTap: () => onSelect(o),
      child: AppChip(
          label: o,
          selected: selected == o,
          selectedColor: AppColors.brandTint,
          selectedTextColor: AppColors.brandTintInk),
    )).toList(),
  );
}

// ── 모드 토글 버튼 ─────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: active ? AppColors.brandTint : AppColors.surface,
        border: Border.all(
            color: active ? AppColors.brandAction : AppColors.line),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w700,
        color: active ? AppColors.brandTintInk : AppColors.ink2,
      )),
    ),
  );
}

