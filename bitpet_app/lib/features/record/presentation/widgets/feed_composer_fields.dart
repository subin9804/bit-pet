import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/feed_models.dart';

const _kFeedOptions = [
  '귀뚜라미', '슈퍼웜', '밀웜', '버터웜', '핑키마우스', '직접 입력',
];

/// 급여 폼 상태 — 드래프트(컴포저) + 쌓인 아이템 + 메모
class FeedFormData {
  final String draftFood;
  final int draftAmount;
  final List<FeedItem> items;
  final String memo;

  const FeedFormData({
    this.draftFood = '귀뚜라미',
    this.draftAmount = 5,
    this.items = const [],
    this.memo = '',
  });

  FeedFormData copyWith({
    String? draftFood,
    int? draftAmount,
    List<FeedItem>? items,
    String? memo,
  }) =>
      FeedFormData(
        draftFood: draftFood ?? this.draftFood,
        draftAmount: draftAmount ?? this.draftAmount,
        items: items ?? this.items,
        memo: memo ?? this.memo,
      );

  int get totalAmt => items.fold(0, (s, i) => s + i.amt);
  bool get hasItems => items.isNotEmpty;
}

/// 급여 추가 컴포저 — 06d·06e에서 공통으로 재사용.
/// [form]  현재 폼 상태 (immutable)
/// [onChanged] 상태 변경 콜백
/// [bandColor] 프리셋·목록추가버튼에 사용되는 피딩 색
class FeedComposerFields extends StatelessWidget {
  final FeedFormData form;
  final ValueChanged<FeedFormData> onChanged;
  final Color bandColor;

  const FeedComposerFields({
    super.key,
    required this.form,
    required this.onChanged,
    this.bandColor = AppColors.feedBand,
  });

  void _setDraft(String? food, int? amount) => onChanged(form.copyWith(
        draftFood: food,
        draftAmount: amount,
      ));

  void _addItem() {
    if (form.draftAmount < 1) return;
    onChanged(form.copyWith(
      items: [
        ...form.items,
        FeedItem(food: form.draftFood, amt: form.draftAmount),
      ],
    ));
  }

  void _removeItem(int idx) {
    final next = [...form.items]..removeAt(idx);
    onChanged(form.copyWith(items: next));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 급여 추가 컴포저 카드 ──────────────────────────
        _FormRow(
          label: '급여 추가',
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 급여 종류 드롭다운
                DropdownButtonFormField<String>(
                  value: form.draftFood,
                  onChanged: (v) => _setDraft(v, null),
                  items: _kFeedOptions.map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  )).toList(),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.paleLine)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.paleLine)),
                    filled: true,
                    fillColor: AppColors.paleBg,
                  ),
                ),
                const SizedBox(height: 8),

                // 급여량 스테퍼: − [숫자] + 44×44
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.paleBg,
                    border: Border.all(color: AppColors.paleLine),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _StepperBtn.right(
                          label: '−',
                          onTap: () => _setDraft(
                              null, (form.draftAmount - 1).clamp(1, 99))),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SizedBox(
                              width: 56,
                              child: TextField(
                                key: ValueKey(form.draftAmount),
                                controller: TextEditingController(
                                    text: '${form.draftAmount}'),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.mono(
                                    20, FontWeight.w700),
                                decoration: const InputDecoration.collapsed(
                                    hintText: '0'),
                                onChanged: (v) {
                                  final n = int.tryParse(v);
                                  if (n != null && n > 0) {
                                    _setDraft(null, n);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('마리',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.paleInk2,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _StepperBtn.left(
                          label: '＋',
                          onTap: () =>
                              _setDraft(null, form.draftAmount + 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 프리셋 칩: 1·3·5·7·10
                Wrap(
                  spacing: 6,
                  children: [1, 3, 5, 7, 10].map((n) {
                    final active = form.draftAmount == n;
                    return GestureDetector(
                      onTap: () => _setDraft(null, n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: active ? bandColor : AppColors.paleBg,
                          border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : AppColors.paleLine),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$n마리',
                            style: AppTextStyles.mono(11, FontWeight.w700)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // 목록에 추가 버튼
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: bandColor,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('목록에 추가',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 추가한 급여 리스트 ──────────────────────────────
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('추가한 급여',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.2)),
            Text(
              '${form.items.length}종 · 총 ${form.totalAmt}마리',
              style: AppTextStyles.mono(11, FontWeight.w700,
                  color: AppColors.paleInk2),
            ),
          ],
        ),
        const SizedBox(height: 8),

        form.hasItems
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.paleLine),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Column(
                  children: form.items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: idx < form.items.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                    color: AppColors.paleLineSoft))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.feedDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.food,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('×${item.amt}',
                              style: AppTextStyles.monoBody),
                          Text(' 마리',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.paleInk2,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeItem(idx),
                            child: Container(
                              width: 26, height: 26,
                              alignment: Alignment.center,
                              child: const Icon(Icons.close,
                                  size: 15, color: AppColors.paleInk3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.paleLine,
                      width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('위에서 급여를 골라 추가해 주세요',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.paleInk3)),
              ),

        // ── 메모 (optional) ──────────────────────────────────
        const SizedBox(height: 16),
        _FormRow(
          label: '메모',
          optional: true,
          child: TextField(
            controller: TextEditingController(text: form.memo),
            onChanged: (v) => onChanged(form.copyWith(memo: v)),
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppColors.primary),
            decoration: InputDecoration(
              hintText: '예: 1마리 남김 · 식욕 좋음',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.paleLine)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.paleLine)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 레이블 + optional 태그 래퍼 ────────────────────────────────
class _FormRow extends StatelessWidget {
  final String label;
  final bool optional;
  final Widget child;

  const _FormRow({
    required this.label,
    this.optional = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.2)),
            if (optional) ...[
              const SizedBox(width: 6),
              Text('OPTIONAL',
                  style: AppTextStyles.mono(9, FontWeight.w700,
                      color: AppColors.paleInk3)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── 스테퍼 좌우 버튼 (44×44) ──────────────────────────────────
// borderRight/borderLeft 방향을 지정
enum _StepperSide { left, right }

class _StepperBtn extends StatelessWidget {
  final String label;
  final _StepperSide side;
  final VoidCallback onTap;

  const _StepperBtn.right({
    required this.label,
    required this.onTap,
  }) : side = _StepperSide.right;

  const _StepperBtn.left({
    required this.label,
    required this.onTap,
  }) : side = _StepperSide.left;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: side == _StepperSide.right
              ? const Border(
                  right: BorderSide(color: AppColors.paleLine))
              : const Border(
                  left: BorderSide(color: AppColors.paleLine)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
    );
  }
}
