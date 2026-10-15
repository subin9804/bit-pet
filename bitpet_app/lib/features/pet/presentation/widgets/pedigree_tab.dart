import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';
import 'pedigree_parent_card.dart';

/// 개체 상세 '가계도' 탭 — 조부모 · 부모 · 이 개체 · 자식 네 세대.
///
/// 부모가 등록된 개체에서만 탭이 생긴다(`PetDetailScreen`). 그 위 세대는 보여주지 않는다 —
/// 서버도 한 세대 위(조부모)까지만 내린다.
///
/// 세로로 내려 그린다. 가로 트리는 조부모 4칸이 한 줄에 서야 해서 폰 폭에서는 카드가
/// 80px 남짓으로 줄어 이름이 안 읽힌다. 대신 **아비 쪽은 왼쪽, 어미 쪽은 오른쪽** 반폭에
/// 고정해서 위아래 줄이 같은 혈통끼리 맞물리게 한다.
///
/// 카드는 개체 정보 칸의 부모 카드(`PedigreeParentCard`)를 그대로 쓴다 — 남의 개체면
/// 소유자 줄이 붙고, 누르면 사육자/공개/비공개에 따라 갈 곳이 갈리는 규칙이 같아야 한다.
class PedigreeTab extends ConsumerWidget {
  final int petId;
  const PedigreeTab({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(genealogyProvider(petId)).valueOrNull;
    if (g == null) return const SizedBox(height: 120);

    final father = g.father;
    final mother = g.mother;
    final (ff, fm) = g.grandparentsOf(father);
    final (mf, mm) = g.grandparentsOf(mother);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 조부모 ──
        const _GenLabel('조부모'),
        _Halves(
          left: Column(children: [
            _Slot(ff, hint: '아비의 아비'),
            const SizedBox(height: AppSpacing.sm),
            _Slot(fm, hint: '아비의 어미'),
          ]),
          right: Column(children: [
            _Slot(mf, hint: '어미의 아비'),
            const SizedBox(height: AppSpacing.sm),
            _Slot(mm, hint: '어미의 어미'),
          ]),
        ),
        const _Connector(),

        // ── 부모 ──
        const _GenLabel('부모'),
        _Halves(
          left: _Slot(father, hint: '아비'),
          right: _Slot(mother, hint: '어미'),
        ),
        const _Connector(),

        // ── 이 개체 ──
        _Self(pet: g.pet),

        // ── 자식 ──
        if (g.children.isNotEmpty) ...[
          const _Connector(),
          _GenLabel('자식 ${g.children.length}'),
          // 자식은 수가 정해져 있지 않아 반폭 2열로 흘려 놓는다
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: g.children
                  .map((k) => SizedBox(
                        width: w,
                        child: PedigreeParentCard(card: k, asParent: false),
                      ))
                  .toList(),
            );
          }),
        ],
      ],
    );
  }
}

class _GenLabel extends StatelessWidget {
  final String text;
  const _GenLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: AppTextStyles.paleGridLabel),
      );
}

/// 아비 쪽(왼쪽) / 어미 쪽(오른쪽) 반폭.
class _Halves extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _Halves({required this.left, required this.right});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: right),
          ],
        ),
      );
}

/// 카드 한 칸. 등록이 안 된 자리는 빈칸 대신 흐린 자리표시로 둔다 —
/// 칸이 사라지면 왼쪽·오른쪽이 어느 혈통인지가 무너진다.
class _Slot extends StatelessWidget {
  final PetCard? card;
  final String hint;
  const _Slot(this.card, {required this.hint});

  @override
  Widget build(BuildContext context) {
    final c = card;
    if (c != null) return PedigreeParentCard(card: c);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 62),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        color: AppColors.bgAlt,
      ),
      child: Text('$hint 미등록',
          style: AppTextStyles.caption.copyWith(color: AppColors.paleInk3)),
    );
  }
}

/// 가운데 — 지금 보고 있는 개체. 누를 곳이 없으니 카드가 아니라 강조 띠로 그린다.
class _Self extends StatelessWidget {
  final Pet pet;
  const _Self({required this.pet});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          color: AppColors.brandTintSoft,
          border: Border.all(color: AppColors.brandTint),
        ),
        child: Text(
          pet.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink),
        ),
      );
}

/// 세대 사이 짧은 세로선.
class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 1.5,
          height: AppSpacing.lg,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          color: AppColors.line,
        ),
      );
}
