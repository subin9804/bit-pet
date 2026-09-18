import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// 공용 토글 스위치. 앱 전체 토글은 이 위젯만 쓴다 (스타일 변경은 여기 한 곳).
///
/// ⚠️ **여기 숫자들은 여백이 아니라 치수다.** 트랙 22 / 썸 18 / 여백 2 가 딱 맞물려
/// 있어서, 4배수 그리드에 맞춘다고 여백을 4로 올리면 썸이 트랙 밖으로 나간다.
class AppToggle extends StatelessWidget {
  final bool value;
  final VoidCallback onToggle;

  const AppToggle({super.key, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: value ? AppColors.toggleOn : AppColors.toggleOff,
          borderRadius: AppRadius.brPill,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
