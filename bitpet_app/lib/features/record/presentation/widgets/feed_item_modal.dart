// 급여 항목 입력 모달 — `＋ 급여 추가` 에서 열린다.
//
// 바텀시트 위에 뜬다. `showDialog(barrierColor: transparent)` 로 띄우고 딤을 직접 그리는
// 방식은 `routine/presentation/bulk_confirm_sheet.dart` 와 같다 — 머티리얼 배리어를 쓰면
// 부모 시트의 드래그 영역과 겹쳐 시트가 같이 끌려 내려간다.
//
// **이 모달은 상태를 바깥으로 흘리지 않는다.** 고른 값은 `담기` 를 눌러야
// `FeedFormData` 로 pop 되고, `취소`·뒤로가기는 null 이다. 부모는 결과만 받는다.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/food_catalog.dart';
import 'feed_composer_fields.dart';

/// 급여 항목 하나를 입력받는다. 담지 않고 닫으면 null.
///
/// [initial] 을 주면 그 값으로 열린다 (담긴 항목을 다시 눌러 고치는 경로).
Future<FeedFormData?> showFeedItemModal(
  BuildContext context, {
  Color bandColor = AppColors.feedBand,
  FeedFormData? initial,
}) {
  return showDialog<FeedFormData>(
    context: context,
    // 부모가 바텀시트라 루트 내비게이터에 띄운다. 시트의 로컬 내비게이터에 쌓으면
    // 시트가 닫힐 때 모달이 남거나 같이 사라지는 게 상황마다 달라진다.
    useRootNavigator: true,
    barrierColor: Colors.transparent,
    builder: (_) => _FeedItemModal(bandColor: bandColor, initial: initial),
  );
}

class _FeedItemModal extends StatefulWidget {
  final Color bandColor;
  final FeedFormData? initial;
  const _FeedItemModal({required this.bandColor, this.initial});

  @override
  State<_FeedItemModal> createState() => _FeedItemModalState();
}

class _FeedItemModalState extends State<_FeedItemModal> {
  late FeedFormData _form = widget.initial ?? const FeedFormData();

  /// 종류를 바꾸면 사이즈·마릿수는 버린다 — 먹이마다 고를 수 있는 값이 다르다
  /// (곤충은 극소·소·중·대, 마우스는 핑키·퍼지…). 남겨두면 없는 사이즈가 선택된 채로 남는다.
  /// 영양제는 종류와 무관하므로 유지한다.
  void _selectType(FoodType ft) {
    if (_form.foodType == ft) return;
    setState(() => _form = FeedFormData(
          foodType: ft,
          supplement: _form.supplement,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        // ── 직접 그리는 딤 ────────────────────────────────────
        // 탭하면 닫힌다. 고른 게 있으면 사고가 되므로 그때는 무시한다.
        Positioned.fill(
          child: GestureDetector(
            onTap: _form.foodType == null ? () => Navigator.of(context).pop() : null,
            child: Container(color: const Color(0x70000000)),
          ),
        ),

        // ── 모달 카드 ─────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Material(
              color: AppColors.card,
              borderRadius: AppRadius.brSheet,
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.78,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _grip(),
                      Flexible(child: _body()),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _grip() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.paleLine,
          borderRadius: AppRadius.brPill,
        ),
      );

  Widget _body() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '급여 추가',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.primary, letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 뭘 줬나 ─────────────────────────────────────
            // 모달은 화면을 새로 쓰므로 10개가 다 들어간다. 드롭다운이었을 땐
            // 탭 → 오버레이가 화면을 덮음 → 스크롤 → 탭 이었다.
            const FeedFieldLabel('뭘 줬나'),
            const SizedBox(height: AppSpacing.sm),
            FeedTypeChips(
              selected: _form.foodType,
              bandColor: widget.bandColor,
              onSelect: _selectType,
            ),

            // ── 얼마나 ──────────────────────────────────────
            // 종류마다 묻는 게 다르다 (사이즈+마릿수 / ml / 용량 / 이름 직접입력).
            // 그 분기는 FeedSubInput 이 이미 들고 있으므로 여기서 다시 짜지 않는다.
            if (_form.foodType != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FeedSubInput(
                form: _form,
                bandColor: widget.bandColor,
                onChanged: (f) => setState(() => _form = f),
              ),
            ],

            // ── 영양제 ──────────────────────────────────────
            const SizedBox(height: AppSpacing.xl),
            const FeedFieldLabel('영양제', optional: true),
            const SizedBox(height: AppSpacing.sm),
            FeedSupplementChips(
              selected: _form.supplement,
              onSelect: (s) => setState(() => _form = _form.copyWith(supplement: s)),
            ),
          ],
        ),
      );

  Widget _footer() {
    final can = _form.isValid;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.paleLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModalButton(
              label: '취소',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _ModalButton(
              label: '담기',
              solid: true,
              bandColor: widget.bandColor,
              onTap: can ? () => Navigator.of(context).pop(_form) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final bool solid;
  final Color? bandColor;
  final VoidCallback? onTap;
  const _ModalButton({
    required this.label,
    this.solid = false,
    this.bandColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: solid
              ? (on ? bandColor : AppColors.paleBgAlt)
              : AppColors.paleBg,
          border: solid ? null : Border.all(color: AppColors.paleLine),
          borderRadius: AppRadius.brMd,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: on ? AppColors.primary : AppColors.paleInk3,
          ),
        ),
      ),
    );
  }
}
