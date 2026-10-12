// 캘린더에서 고른 날의 기록 카드.
//
// 예전에는 날짜를 누르면 바텀시트가 올라왔다. 칸을 눌러 → 시트를 열고 → 닫는
// **두 번의 조작**을 거쳐야 그 날 내용을 봤다. 지금은 캘린더 바로 아래에 펼친다.
//
// 캘린더 카드와 같은 흰 카드를 쓰면 두 덩어리가 한 장처럼 이어져 경계가 사라진다.
// 그래서 **선택 타일과 같은 테두리**(1.5px brandAction)로 끊어 낸다 — "위 칸에서
// 나온 카드"라는 연결이 테두리로 읽힌다.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

class SelectedDayCard extends StatelessWidget {
  /// 'YYYY-MM-DD'
  final String date;

  /// '2건' · '2회' 처럼 화면마다 세는 단위가 다르다
  final String countLabel;

  /// 이 날짜로 기록 추가
  final VoidCallback onAdd;

  /// 기록 행들. 각 행은 테두리 없는 **맨 몸**이어야 한다 (카드 안의 카드 금지).
  final List<Widget> rows;

  final String emptyLabel;

  const SelectedDayCard({
    super.key,
    required this.date,
    required this.countLabel,
    required this.onAdd,
    required this.rows,
    this.emptyLabel = '이 날의 기록이 없어요',
  });

  @override
  Widget build(BuildContext context) {
    final d = DateTime.parse(date);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brLg,
        border: Border.fromBorderSide(
            BorderSide(color: AppColors.brandAction, width: 1.5)),
        boxShadow: AppShadows.elev1,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('${d.month}. ${d.day} (${_weekKo[d.weekday % 7]})',
                  style: AppTextStyles.mono(15, FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(countLabel,
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.brandTintInk)),
              ),
              const Spacer(),
              // 주 버튼이 아니다 — 이 날짜로 에디터를 여는 바로가기다
              GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text('＋ 추가',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandAction)),
                ),
              ),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
              child: Text(emptyLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3)),
            )
          else
            // 행은 카드로 쪼개지 않고 얇은 선으로만 나눈다 (선은 칸막이지 테두리가 아니다)
            for (var i = 0; i < rows.length; i++)
              Container(
                decoration: i == 0
                    ? null
                    : const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.bgAlt)),
                      ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: rows[i],
              ),
        ],
      ),
    );
  }
}
