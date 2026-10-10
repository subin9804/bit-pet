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
        color: AppColors.surface,
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
          Flexible(
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
