import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 공용 토글 스위치 — 직사각형, off=#DEDEDE / on=#191919.
/// 앱 전체 토글은 이 위젯만 사용한다 (스타일 변경 시 여기 한 곳만 수정).
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
          borderRadius: BorderRadius.zero,
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
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}
