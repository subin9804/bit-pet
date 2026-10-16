import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';
import 'pedigree_parent_card.dart';

/// 개체 상세 '가계도' 탭 — 조부모 · 부모 · 이 개체(+동배) · 자식 네 세대.
///
/// 등록 안 된 개체는 자리표시 없이 생략하고, 조부모가 한 마리도 없으면 그 줄을 통째로 뺀다.
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
        // ── 조부모 — 한 마리도 없으면 줄째 생략 ──
        if (g.hasGrandparents) ...[
          const _GenLabel('조부모'),
          _Halves(
            left: _Stack([ff, fm]),
            right: _Stack([mf, mm]),
          ),
          const _Connector(),
        ],

        // ── 부모 ──
        const _GenLabel('부모'),
        _Halves(
          left: _Stack([father]),
          right: _Stack([mother]),
        ),
        const _Connector(),

        // ── 이 개체 + 동배 (같은 세대라 선으로 잇지 않는다) ──
        _Self(pet: g.pet),
        if (g.siblings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _GenLabel('동배 ${g.siblings.length}'),
          _CardGrid(g.siblings),
        ],

        // ── 자식 ──
        if (g.children.isNotEmpty) ...[
          const _Connector(),
          _GenLabel('자식 ${g.children.length}'),
          _CardGrid(g.children),
        ],
      ],
    );
  }
}

/// 수가 정해져 있지 않은 줄(동배·자식) — 반폭 2열로 흘려 놓는다.
/// 성별 아이콘은 relationType 이 아니라 개체 자신의 gender 로 그린다(`asParent: false`).
class _CardGrid extends StatelessWidget {
  final List<PetCard> cards;
  const _CardGrid(this.cards);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cards
              .map((k) => SizedBox(
                    width: w,
                    child: PedigreeParentCard(card: k, asParent: false),
                  ))
              .toList(),
        );
      });
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

/// 한쪽 혈통의 카드 묶음. 등록이 안 된 개체는 자리표시 없이 **그냥 빠진다**
/// (2026-10-17 사용자 요청). 반쪽이 통째로 비어도 그 반폭은 비워 둔다 —
/// 남은 카드가 가운데로 쏠리면 왼쪽=아비 쪽 / 오른쪽=어미 쪽 규칙이 무너진다.
class _Stack extends StatelessWidget {
  final List<PetCard?> cards;
  const _Stack(this.cards);

  @override
  Widget build(BuildContext context) {
    final present = cards.whereType<PetCard>().toList();
    return Column(
      children: [
        for (var i = 0; i < present.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          PedigreeParentCard(card: present[i]),
        ],
      ],
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
