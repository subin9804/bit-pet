import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/section_header.dart';

/// 마이 탭과 그 하위 화면(알림 설정·앱 정보·자녀 계정)이 함께 쓰는 메뉴 묶음 카드.
///
/// 하위 화면이 캔버스 위에 줄만 늘어놓으면 마이 탭에서 들어갈 때마다 화면 결이 바뀐다.
/// 항목은 흰 카드 한 장에 모으고 사이만 선으로 나눈다.
class MenuCard extends StatelessWidget {
  final List<Widget> children;

  /// 구분선 왼쪽 들여쓰기. 앞에 아이콘이 있는 줄은 52 (아이콘 20 + 간격 16 + 좌패딩 16),
  /// 글자만 있는 줄은 16 으로 글자 시작점에 맞춘다.
  final double dividerIndent;

  const MenuCard({super.key, required this.children, this.dividerIndent = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      decoration: AppDecor.cardRaised,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: AppColors.line,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 메뉴 그룹 제목. 좌우 여백은 카드 안 글자 시작점(16+16)에 맞춘다 — 제목이 항목보다
/// 안쪽에 있으면 어디까지가 그 그룹인지 흐려진다.
class MenuGroupTitle extends StatelessWidget {
  final String title;

  const MenuGroupTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
      child: SectionHeader(title: title),
    );
  }
}
