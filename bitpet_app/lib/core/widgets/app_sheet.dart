import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 바텀시트 공통 골격.
///
/// 앱에 시트가 26개 있는데 전부 제각각으로 짜여 있었다. 핸들바만 해도 같은
/// `width: 40, height: 4` 가 10곳에 복사돼 있고, 어떤 시트는 제목이 위에 어떤 시트는
/// 아래에, 날짜 칸은 중간에 끼어 있기도 했다. **시트마다 순서가 다르면 사용자는
/// 매번 처음 보는 화면처럼 읽어야 한다.**
///
/// 그래서 슬롯 7개의 **순서를 고정**한다. 안 쓰는 슬롯은 비우면 되지만 순서는 못 바꾼다.
///
/// | # | 슬롯 | 비고 |
/// |---|---|---|
/// | 1 | 핸들 | 항상. 끌어내릴 수 있다는 유일한 표시 |
/// | 2 | 제목(+ 보조 한 줄) | |
/// | 3 | [petSelector] | **항상 맨 위.** "무엇에 대한 기록인지"가 먼저다 |
/// | 4 | [child] | 시트마다 다른 본문 |
/// | 5 | [dateField] | **항상 마지막.** 대개 오늘이라 안 건드린다 |
/// | 6 | 주 버튼 | **전폭 하나.** 두 개를 나란히 두지 말 것 |
/// | 7 | 키보드 회피 | `viewInsets` 만큼 띄우고 본문을 스크롤로 만든다 |
///
/// ⛔ 주 버튼 옆에 '취소'를 두지 말 것 — 시트는 끌어내리거나 바깥을 눌러 닫는다.
/// 버튼이 둘이면 둘 다 안 읽힌다.
///
/// ## 바탕은 [AppColors.canvas] — **시트도 하나의 화면이다**
///
/// 바탕이 연회색이고 내용이 흰 카드다. 화면 쪽과 **같은 규칙**이어야 한다.
///
/// 한때 흰색([AppColors.surface])이었다. 그러면 안에 놓는 박스를 회색으로
/// 깔게 되는데(`ConfirmAccordion` 이 그랬다), 바로 뒤에서 열리는 화면은 회색
/// 바탕 + 흰 카드라 **시트를 올릴 때마다 면 관계가 뒤집힌다.** 사용자가 보는
/// 증상은 "배경색이 계속 안 맞는다"였다.
///
/// ⚠️ 토큰 이름에 속지 말 것 — `surface`·`card`·`bg` 는 **전부 같은 흰색 별칭**이다.
/// '시트니까 surface' 는 맞게 쓴 것처럼 보이지만 아무 판단도 하지 않은 것과 같다.
///
/// ⛔ 다시 흰색으로 뒤집지 말 것. 흰 바탕이 필요해 보이면 그건 **본문을 흰 카드로
/// 감싸야 하는 신호**다 (시트 자체가 아니라).
class AppSheet extends StatelessWidget {
  final String title;

  /// 제목 아래 한 줄. 설명이 아니라 **맥락**에 쓴다 (개체 이름, 날짜 범위 등).
  final String? subtitle;

  /// 슬롯 3 — 개체 선택. 개체와 무관한 시트(설정·약관)는 null.
  final Widget? petSelector;

  /// 슬롯 4 — 본문.
  final Widget child;

  /// 슬롯 5 — 날짜/시각 선택. 날짜가 없는 시트는 null.
  final Widget? dateField;

  /// 슬롯 6 — 주 버튼 라벨. null 이면 버튼 없이 본문만 있는 시트가 된다
  /// (목록에서 하나 고르면 바로 닫히는 선택형 시트가 그렇다).
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  /// 진행 중이면 버튼을 스피너로 바꾸고 다시 못 누르게 한다.
  final bool busy;

  /// 되돌릴 수 없는 동작(소유권 이전·삭제)이면 주 버튼을 경고색으로 칠한다.
  /// 색만 바뀌고 자리·크기는 그대로다 — 버튼을 하나 더 두거나 옮기지 않는다.
  final bool isDangerous;

  /// 본문이 길어 스크롤이 필요한 시트. 높이를 화면의 이 비율까지 키운다.
  final double maxHeightFactor;

  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.petSelector,
    this.dateField,
    this.primaryLabel,
    this.onPrimary,
    this.busy = false,
    this.isDangerous = false,
    this.maxHeightFactor = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brSheet,
      ),
      // 슬롯 7 — 키보드가 올라온 만큼 시트 전체를 띄운다. 본문이 스크롤이라
      // 밀려 올라간 상태에서도 아래 칸에 닿을 수 있다.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 슬롯 1 · 2 ─────────────────────────────────────────
          const _Handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),

          // ── 슬롯 3 · 4 · 5 ─────────────────────────────────────
          //
          // ⚠️ **스크롤 막대를 항상 띄운다** (`thumbVisibility: true`).
          // 기본값(모바일)은 '끌 때만 잠깐 보임'이라, 내용이 시트 높이를 넘겨
          // 잘려 있어도 **더 있다는 단서가 하나도 없었다** — 밑에 남은 항목이
          // 그냥 누락된 것처럼 보인다(2026-10-15 사용자 지적: "스크롤이
          // 비가시적이라 그냥 정보가 누락되어보여"). 넘치지 않으면 막대는
          // 애초에 그려지지 않으므로 짧은 시트는 전과 똑같다.
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (petSelector != null) ...[
                    petSelector!,
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  child,
                  if (dateField != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    dateField!,
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
              ),
            ),
          ),

          // ── 슬롯 6 ────────────────────────────────────────────
          if (primaryLabel != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                media.padding.bottom + AppSpacing.lg,
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: busy ? null : onPrimary,
                  style: isDangerous
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.bg,
                        )
                      : null,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bg),
                        )
                      : Text(primaryLabel!),
                ),
              ),
            )
          else
            SizedBox(height: media.padding.bottom + AppSpacing.sm),
        ],
      ),
    );
  }
}

/// 끌어내릴 수 있다는 표시. 10곳에 복사돼 있던 것을 여기 하나로 모았다.
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.border,
          borderRadius: AppRadius.brPill,
        ),
      ),
    );
  }
}

/// 시트 본문을 감싸는 **흰 카드**. [AppSheet] 바탕이 연회색이라, 읽거나 누르는
/// 내용은 이 카드 안에 들어가야 화면 쪽 카드와 같은 면 관계가 된다.
///
/// 카드가 필요 없는 본문도 있다 — 이미 스스로 카드를 그리는 것
/// (`ConfirmAccordion`, 개체 카드 목록)과, 면이 아예 없어야 하는 것
/// (사진 뷰어처럼 어두운 배경을 꽉 채우는 본문)이 그렇다.
/// ⛔ 카드를 겹쳐 두 겹으로 만들지 말 것.
class SheetCard extends StatelessWidget {
  final Widget child;

  /// 목록처럼 행이 제 패딩을 들고 있는 본문은 카드의 안쪽 여백을 줄인다
  /// (`ListTile` 은 세로 여백이 이미 있어서 겹치면 행이 멀찍이 떨어진다).
  final EdgeInsets padding;

  const SheetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  /// 행이 제 여백을 들고 있는 목록용 — 좌우만 주고 위아래는 거의 두지 않는다.
  const SheetCard.list({super.key, required this.child})
      : padding = const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card,
      padding: padding,
      child: child,
    );
  }
}

/// 시트를 띄우는 단일 진입점.
///
/// `showModalBottomSheet` 를 직접 부르면 호출부마다 `isScrollControlled`·`shape`·
/// `barrierColor` 를 따로 적게 되고, 하나라도 빠지면 그 시트만 키보드에 가리거나
/// 모서리가 각지게 나온다. 시트를 띄울 땐 **반드시 이 함수**를 쓸 것.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    // 키보드·긴 본문을 위해 높이를 시트가 직접 정하게 둔다.
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    // 하단 인셋은 AppSheet 가 직접 다룬다 (useSafeArea 를 켜면 이중으로 띄워진다).
    useSafeArea: false,
  );
}
