// '내 개체 → 알' 탭 — 내가 돌보는 개체 전체의 클러치 목록.
//
// 개체 목록과 **같은 화면의 다른 탭**이다(AppBar 아래 밑줄 탭). 클러치는 개체에
// 매달린 기록이지만 "지금 품고 있는 알"은 개체를 하나씩 열어보는 성질이 아니라
// 한 줄로 훑는 성질이라, 개체 상세 안에만 두면 매일 확인할 수가 없다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/models/record_models.dart';
import '../../providers/record_provider.dart';
import '../fab_record_sheet.dart';

class EggTab extends ConsumerWidget {
  const EggTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myLayingsProvider);

    return async.when(
      loading: () => const _EggSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: AppSpacing.screenPad,
          child: Text('알 목록을 불러오지 못했어요.\n$e',
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ),
      ),
      data: (layings) {
        if (layings.isEmpty) {
          return Column(
            children: [
              _SummaryBar(layings: layings),
              Expanded(
                child: EmptyState(
                  message: '품고 있는 알이 없어요',
                  subMessage: '산란을 기록하면 알 개수만큼 칸이 생기고,\n'
                      '부화하면 그대로 개체로 등록할 수 있어요.',
                  actionLabel: '산란 등록',
                  onAction: () => _openLayingSheet(context),
                ),
              ),
            ],
          );
        }

        // 부화를 마친 클러치(남은 알이 없는 것)는 아래로 내린다 — 매일 보는 것은
        // 아직 품고 있는 쪽이다. 그 안에서는 서버 순서(산란일 최신순)를 지킨다.
        final ongoing = layings.where((l) => l.pendingCount > 0).toList();
        final done = layings.where((l) => l.pendingCount == 0).toList();

        // 카드와 구분 캡션을 한 줄짜리 목록으로 미리 펼친다 — itemBuilder 안에서
        // 인덱스를 계산하면 캡션 한 줄 때문에 뒤쪽이 통째로 어긋난다.
        final items = <Object>[
          ...ongoing,
          if (done.isNotEmpty) const _DoneDivider(),
          ...done,
        ];

        return Column(
          children: [
            _SummaryBar(layings: layings),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.refresh(myLayingsProvider.future),
                color: AppColors.brandAction,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0,
                      AppSpacing.xl, AppSpacing.x40),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.cardGap),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    if (item is LayingRecord) {
                      return _ClutchCard(laying: item);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('부화를 마친 클러치',
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _openLayingSheet(BuildContext context) {
  // 산란 입력 폼은 이미 있다(FAB 와 같은 것) — 여기서 다시 짜지 않는다.
  // 어느 개체인지는 시트의 개체 선택 단계가 묻고, 서버도 암컷만 받는다.
  showAppSheet<void>(
    context: context,
    builder: (_) => const FabRecordSheet(initialTypeId: 'lay'),
  );
}

/// 면 없는 캡션 한 줄 + 산란 등록. 연녹 밴드는 개체 상세 전용이라 쓰지 않는다.
class _SummaryBar extends StatelessWidget {
  final List<LayingRecord> layings;
  const _SummaryBar({required this.layings});

  @override
  Widget build(BuildContext context) {
    final pending =
        layings.fold<int>(0, (sum, l) => sum + l.pendingCount);
    // '가장 이른 산란' = 품고 있는 알 중 제일 오래된 것. 부화가 가까운 쪽이다.
    final oldest = layings
        .where((l) => l.pendingCount > 0)
        .fold<int?>(null, (max, l) =>
            max == null || l.daysSinceLaid > max ? l.daysSinceLaid : max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: pending == 0
                ? Text('부화를 기다리는 알이 없어요', style: AppTextStyles.caption)
                : Text.rich(
                    TextSpan(
                      style: AppTextStyles.caption,
                      children: [
                        const TextSpan(text: '부화 대기 '),
                        TextSpan(
                            text: '$pending',
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const TextSpan(text: '알'),
                        if (oldest != null) ...[
                          const TextSpan(text: ' · 가장 이른 산란 '),
                          TextSpan(
                              text: 'D+$oldest',
                              style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                        ],
                      ],
                    ),
                  ),
          ),
          TextButton(
            onPressed: () => _openLayingSheet(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandAction,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              textStyle:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Text('＋ 산란 등록'),
          ),
        ],
      ),
    );
  }
}

class _ClutchCard extends StatelessWidget {
  final LayingRecord laying;
  const _ClutchCard({required this.laying});

  @override
  Widget build(BuildContext context) {
    final latestNote = laying.notes.isEmpty ? null : laying.notes.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () => context.push('/layings/${laying.id}'),
        child: Container(
          decoration: AppDecor.card,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.petClay,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(AppIcons.laying,
                        size: 14, color: AppColors.petClayInk),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(laying.petName ?? '개체',
                            style: AppTextStyles.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          [
                            if (laying.speciesName != null) laying.speciesName!,
                            '${_md(laying.laidAt)} 산란',
                          ].join(' · '),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.ink3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('D+${laying.daysSinceLaid}',
                          style: AppTextStyles.subheading),
                      Text('${laying.totalCount}알',
                          style: AppTextStyles.label),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),
              _ProgressBar(laying: laying),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs + 2,
                runSpacing: AppSpacing.xs,
                children: [
                  if (laying.hatchedCount > 0)
                    _CountChip(
                        label: '부화 ${laying.hatchedCount}',
                        bg: AppColors.brandTint,
                        fg: AppColors.brandTintInk),
                  if (laying.pendingCount > 0)
                    _CountChip(
                        label: '대기 ${laying.pendingCount}',
                        bg: AppColors.bgAlt,
                        fg: AppColors.ink2),
                  if (laying.failedCount > 0)
                    _CountChip(
                        label: '무정 ${laying.failedCount}',
                        bg: AppColors.petCoral,
                        fg: AppColors.petCoralInk),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Container(
                padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.bgAlt)),
                ),
                child: latestNote == null
                    ? Text('메모가 없어요',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.ink3))
                    : Text(
                        '${_md(latestNote.notedAt)} · ${latestNote.content}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 알 결과를 비율로 보여주는 4px 바. 대기는 빈 칸(회색 홈)으로 남는다 —
/// 아직 아무 일도 일어나지 않은 몫이라 색을 주면 결과처럼 읽힌다.
class _ProgressBar extends StatelessWidget {
  final LayingRecord laying;
  const _ProgressBar({required this.laying});

  @override
  Widget build(BuildContext context) {
    final total = laying.totalCount == 0 ? 1 : laying.totalCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 6,
        color: AppColors.bgAlt,
        child: Row(
          children: [
            Expanded(
              flex: laying.hatchedCount,
              child: const ColoredBox(color: AppColors.brandAction),
            ),
            Expanded(
              flex: laying.failedCount,
              child: const ColoredBox(color: AppColors.error),
            ),
            Expanded(
              flex: total - laying.hatchedCount - laying.failedCount,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _CountChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: fg)),
    );
  }
}

class _EggSkeleton extends StatelessWidget {
  const _EggSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(width: double.infinity, height: 148, borderRadius: AppRadius.lg),
            const SizedBox(height: AppSpacing.cardGap),
          ],
        ],
      ),
    );
  }
}

String _md(DateTime d) => '${d.month}. ${d.day}';

/// 목록 중간의 '부화를 마친 클러치' 캡션 자리를 가리키는 표식.
class _DoneDivider {
  const _DoneDivider();
}
