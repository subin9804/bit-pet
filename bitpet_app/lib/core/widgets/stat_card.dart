import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 숫자 한 개를 보여주는 작은 카드. 개체 상세 헤더 아래 3칸으로 겹쳐 놓는 것이 기본 쓰임.
///
/// 값이 **없을 때 `-` 를 쓴다.** `0` 으로 쓰면 "쟀는데 0" 과 "아직 안 쟀다" 가 같아 보인다.
class StatCard extends StatelessWidget {
  final String label;

  /// 본값. 없으면 null 을 넘긴다 (`-` 로 그린다).
  final String? value;

  /// 값 뒤에 붙는 단위 (`kg`, `일`). 값보다 작게, 흐리게 붙는다.
  final String? unit;

  final VoidCallback? onTap;

  /// [StatCardRow] 안에 들어갈 때 켠다 — 카드 껍데기(흰 면·테두리·그림자)를
  /// 줄이 대신 그리므로 여기서는 내용만 그린다.
  final bool bare;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.onTap,
    this.bare = false,
  });

  StatCard _asBare() => StatCard(
        label: label, value: value, unit: unit, onTap: onTap, bare: true);

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;

    // 라벨이 위, 값이 아래다. 먼저 "무엇"을 읽고 숫자를 읽는 순서라
    // 세 칸을 훑을 때 라벨 줄과 숫자 줄이 각각 가로로 정렬돼 보인다.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.paleGridLabel),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                has ? value! : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.paleValue.copyWith(
                    color: has ? AppColors.ink : AppColors.ink3),
              ),
            ),
            if (has && unit != null) ...[
              const SizedBox(width: 2),
              Text(unit!, style: AppTextStyles.caption),
            ],
          ],
        ),
      ],
    );

    if (bare) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.md),
            child: Center(child: content),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.elev1,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// 통계 카드를 같은 폭으로 늘어놓는 줄. 개체 상세에서는 헤더 위로 겹쳐 쓴다.
///
/// ⚠️ 예전엔 카드 **세 장**이 간격을 두고 떠 있었다. 세 값은 같은 개체의
/// 요약이라 한 덩어리로 읽혀야 하는데, 카드가 나뉘어 있으니 서로 다른 세
/// 가지 것처럼 보였고 연녹 밴드에 걸친 모양도 울퉁불퉁했다. 이제 **흰 카드
/// 한 장** 안에서 얇은 세로선으로만 나눈다 (선은 '칸막이'이지 '테두리'가 아니다).
///
/// ⛔ 4칸 이상을 넣지 말 것 — 폰 폭에서 한 칸이 70px 아래로 떨어지면 숫자가 잘린다.
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;

  const StatCardRow({super.key, required this.cards})
      : assert(cards.length > 0 && cards.length <= 3, '통계 카드는 1~3칸이다');

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          color: AppColors.line,
        ));
      }
      children.add(Expanded(child: cards[i]._asBare()));
    }
    // ⚠️ `stretch` 는 세로 제약을 자식에게 **tight** 로 넘긴다 — 스크롤 안처럼
    // 높이가 무한한 자리에 놓이면 카드가 무한 높이를 받아 레이아웃이 통째로
    // 터진다(`Cannot hit test a render box that has never been laid out`).
    // `IntrinsicHeight` 로 한 번 감싸 **제일 높은 카드에 맞춘 유한한 높이**를
    // 먼저 정하고 나서 늘린다. 3칸뿐이라 추가 측정 비용은 무시할 수 있다.
    return Container(
      decoration: AppDecor.cardRaised,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}
