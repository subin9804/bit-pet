import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 빈 화면의 성격. 색이 달라야 하는 건 꾸미기 위해서가 아니라
/// **"아직 없다"와 "잘못됐다"가 다른 상황이기 때문**이다.
enum EmptyTone {
  /// 아직 아무것도 없다 — 정상이고, 보통 여기서 뭔가 만들게 된다.
  brand,

  /// 불러오지 못했다 / 검색 결과가 없다 — 사용자가 만들 것이 없는 자리.
  /// 연녹 원을 쓰면 "비었지만 좋은 일"처럼 읽혀서 무채색으로 둔다.
  neutral,
}

/// 비어 있는 목록 자리.
///
/// 예전엔 **64px 회색 아이콘** 하나였다. 아이콘이 화면에서 가장 크고 가장
/// 흐린 요소라, 비었다는 사실보다 "뭔가 꺼져 있다"로 먼저 읽혔다.
/// 지금은 연녹 원 안에 작은 아이콘을 넣는다 — 원이 형태를 만들어 주므로
/// 아이콘을 키우지 않아도 자리가 채워진다.
///
/// ⛔ 동작을 두 개 두지 말 것. 비어 있는 화면에서 고르게 만들면 둘 다 안 누른다.
class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final EmptyTone tone;

  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
    this.tone = EmptyTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    final brand = tone == EmptyTone.brand;

    return Center(
      child: SingleChildScrollView(
        // 작은 화면에서 키보드가 올라오거나 글자 배율이 크면 내용이 원 높이만큼
        // 넘친다. 비어 있는 화면이 오버플로로 노랑·검정 줄을 띄우는 건 사고다.
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: brand ? AppColors.brandTintSoft : AppColors.bg2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: brand ? AppColors.brandIcon : AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(message,
                  style: AppTextStyles.subheading,
                  textAlign: TextAlign.center),
              if (subMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subMessage!,
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
