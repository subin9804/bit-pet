// 기념일(해칭일·입양일) 표시 조각 — 개체 상세 캘린더 탭과 홈 대시보드 캘린더가
// **같은 것을 쓴다**. 두 화면에 따로 그리면 색·아이콘·문구가 금세 갈라진다.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/anniversary.dart';

/// 기념일은 기록 카테고리와 같은 자리에 찍히므로, 기록의 흙빛 계열과
/// 확실히 갈라지는 금색 하나로 통일한다. 종류는 색이 아니라 아이콘으로 구분.
const anniversaryColor = AppColors.warning;

IconData anniversaryIcon(AnniversaryKind kind) =>
    kind == AnniversaryKind.hatching
        ? Icons.cake_outlined
        : Icons.home_outlined;

/// 캘린더 셀 안에 찍히는 작은 표시
class AnniversaryMark extends StatelessWidget {
  final AnniversaryKind kind;
  final double size;

  const AnniversaryMark({super.key, required this.kind, this.size = 11});

  @override
  Widget build(BuildContext context) =>
      Icon(anniversaryIcon(kind), size: size, color: anniversaryColor);
}

/// 날짜를 골랐을 때 기록 목록 위에 붙는 한 줄
///
/// [onTap] 을 주면 **그 개체로 넘어가는 줄**이 된다 (홈 대시보드). 개체 상세의
/// 캘린더 탭에서는 이미 그 개체 안이라 주지 않는다 — 자기 자신으로 가는 줄은
/// 눌러도 아무 일이 없는 것처럼 보인다.
class AnniversaryRow extends StatelessWidget {
  final Anniversary anniversary;
  final VoidCallback? onTap;

  const AnniversaryRow({super.key, required this.anniversary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: anniversaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnniversaryMark(kind: anniversary.kind, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(anniversary.kindLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: anniversaryColor)),
              Text(anniversary.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      // 줄 자체에 여백이 없어서(호출처가 Padding 으로 감싼다) 물결이 글자에
      // 딱 붙는다 — 좌우로만 조금 넓혀 탭 영역을 보이게 한다.
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: row,
      ),
    );
  }
}
