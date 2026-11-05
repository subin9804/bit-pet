import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/record_models.dart';
import '../../providers/record_provider.dart';

/// 메모 분류 알약 — 그림 + 이름(병원·탈피·배변…). 메모 카테고리 색을 입는다.
///
/// 홈 날짜 시트·개체 상세 캘린더·메모 기록 상세가 같이 쓴다 — 분류를 고른 보람이
/// 어느 목록에서든 똑같이 보여야 한다 (2026-11-05 사용자 지적).
/// [label] 을 안 주면 분류 목록(`memoTagsProvider`)에서 찾고, 못 찾으면 코드 그대로.
class MemoTagPill extends ConsumerWidget {
  final String code;
  final String? label;

  const MemoTagPill({super.key, required this.code, this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = label ??
        (ref.watch(memoTagsProvider).valueOrNull ?? const <MemoTag>[])
            .where((t) => t.code == code)
            .map((t) => t.labelKo)
            .firstOrNull ??
        code;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.catMemo,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon(AppIcons.memoTag(code), size: 12, color: AppColors.catMemoInk),
        const SizedBox(width: 3),
        Text(name,
            style: AppTextStyles.mono(11, FontWeight.w700,
                color: AppColors.catMemoInk)),
      ]),
    );
  }
}

/// 글 앞에 분류 알약을 붙인 줄. 분류가 없으면 [child] 그대로다.
class MemoTagLine extends StatelessWidget {
  final List<String> tags;
  final Widget child;

  const MemoTagLine({super.key, required this.tags, required this.child});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return child;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final t in tags) ...[
        MemoTagPill(code: t),
        const SizedBox(width: AppSpacing.xs),
      ],
      Expanded(child: child),
    ]);
  }
}
