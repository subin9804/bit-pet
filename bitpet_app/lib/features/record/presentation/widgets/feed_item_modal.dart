// 급여 항목 입력 **바텀시트** — `＋ 급여 추가` 에서 열린다.
//
// 부모가 이미 바텀시트라 `showModalBottomSheet` 을 쓰지 않는다 — 머티리얼 배리어가
// 부모 시트의 드래그 영역과 겹쳐 **부모까지 같이 끌려 내려간다**
// (`routine/presentation/bulk_confirm_sheet.dart` 와 같은 이유).
// 대신 `showGeneralDialog` + 딤을 직접 그리고, 시트의 제스처를 손으로 붙인다:
//   • 아래에서 올라오는 슬라이드 전환
//   • 핸들·제목을 아래로 끌면 닫기(거리 80px 또는 튕김 속도)
//   • 딤 탭하면 닫기
// ⚠️ 이 셋 중 하나라도 빠지면 생긴 건 시트인데 시트처럼 동작하지 않는다.
//
// **이 시트는 상태를 바깥으로 흘리지 않는다.** 고른 값은 `담기` 를 눌러야
// `FeedFormData` 로 pop 되고, 끌어내리기·딤 탭·뒤로가기는 null 이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'feed_composer_fields.dart';

/// 급여 항목 하나를 입력받는다. 담지 않고 닫으면 null.
///
/// [initial] 을 주면 그 값으로 열린다 (담긴 항목을 다시 눌러 고치는 경로).
Future<FeedFormData?> showFeedItemModal(
  BuildContext context, {
  Color bandColor = AppColors.feedBand,
  FeedFormData? initial,
}) {
  return showGeneralDialog<FeedFormData>(
    context: context,
    // 부모가 바텀시트라 루트 내비게이터에 띄운다. 시트의 로컬 내비게이터에 쌓으면
    // 시트가 닫힐 때 이 시트가 남거나 같이 사라지는 게 상황마다 달라진다.
    useRootNavigator: true,
    // 딤은 우리가 그린다(위 머리말). 배리어 탭도 직접 처리한다.
    barrierColor: Colors.transparent,
    barrierDismissible: false,
    barrierLabel: '급여 추가',
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) =>
        _FeedItemModal(bandColor: bandColor, initial: initial),
    // 가운데서 페이드되면 다이얼로그로 읽힌다 — 아래에서 올라와야 시트다.
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
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

  /// 핸들을 끌어내린 거리(px). 손을 떼면 0 으로 돌아가거나 닫힌다.
  double _dragY = 0;

  static const double _kDismissDistance = 80;
  static const double _kDismissVelocity = 700;

  void _onDragUpdate(DragUpdateDetails d) =>
      // 위로는 끌 수 없다 — 올려봐야 더 보여줄 내용이 없다(상한이 이미 0.9).
      setState(() => _dragY = (_dragY + d.delta.dy).clamp(0.0, 600.0));

  void _onDragEnd(DragEndDetails d) {
    if (_dragY > _kDismissDistance ||
        d.velocity.pixelsPerSecond.dy > _kDismissVelocity) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragY = 0);
    }
  }

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
        // ⚠️ 먹이를 고른 뒤에는 탭을 **무시**하고 있었다(실수로 날리는 걸 막으려고).
        // 그런데 앱의 다른 시트는 전부 딤 탭으로 닫히므로, 안 닫히는 이 시트만
        // 고장 난 것처럼 보였다 — '담기' 전까진 어차피 아무것도 저장되지 않는다.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: AppColors.scrimLight),
          ),
        ),

        // ── 모달 카드 ─────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Transform.translate(
              offset: Offset(0, _dragY),
              child: Material(
                color: AppColors.surface,
                borderRadius: AppRadius.brSheet,
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // 앱의 모든 시트와 같은 상한(0.9). 0.78 이었는데 칩이
                      // 세 줄씩 들어가는 시트라 자주 상한에 닿았고, 그때
                      // 다른 시트들보다 **낮은 데서 멈춰** 혼자 짧아 보였다.
                      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 끌어내려 닫는 영역은 핸들+제목까지다. 본문까지 넓히면
                        // 칩 목록 스크롤과 제스처가 서로를 먹는다.
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _onDragUpdate,
                          onVerticalDragEnd: _onDragEnd,
                          child: Column(children: [_grip(), _title()]),
                        ),
                        Flexible(child: _body()),
                        _footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 핸들·제목·본문·주 버튼 — `AppSheet` 의 슬롯 순서와 치수를 그대로 따른다.
  // 이 모달만 36×4 핸들에 16px 제목이라 같은 앱의 시트로 안 보였다.
  Widget _grip() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.border,
          borderRadius: AppRadius.brPill,
        ),
      );

  // 제목은 스크롤 바깥에 둔다 — 아래로 밀어 올려도 "여기가 어디냐"가 남는다.
  Widget _title() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('급여 추가', style: AppTextStyles.heading),
        ),
      );

  Widget _body() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 먹이 종류 ───────────────────────────────────
            // 모달은 화면을 새로 쓰므로 10개가 다 들어간다. 드롭다운이었을 땐
            // 탭 → 오버레이가 화면을 덮음 → 스크롤 → 탭 이었다.
            const FeedFieldLabel('먹이 종류'),
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
    // ⛔ 주 버튼 옆의 '취소'를 걷어냈다 — 앱의 다른 시트에는 없는 버튼이고,
    //    딤을 누르거나 핸들을 내리면 닫힌다(고른 게 있으면 딤 탭은 무시).
    //    손으로 그린 `_ModalButton` 대신 테마 버튼을 쓴다: 전폭 52px.
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: can ? () => Navigator.of(context).pop(_form) : null,
          child: const Text('담기'),
        ),
      ),
    );
  }
}
