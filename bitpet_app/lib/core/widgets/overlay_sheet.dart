import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 라우트가 아니라 **화면 위 오버레이**로 띄우는 시트의 껍데기 —
/// 어두운 바탕 + 아래에서 올라오기 + **끌어내려 닫기**.
///
/// 기록 상세·급여 상세의 편집 시트가 이걸 쓴다. 편집 상태를 부모 화면이 들고 있어서
/// `showModalBottomSheet` 로 옮기면 입력할 때마다 부모 setState 가 시트에 닿지 않는다.
/// 그래서 오버레이로 띄웠는데, 라우트 시트가 공짜로 주던 **끌어내려 닫기가 빠져서**
/// 핸들을 잡아 내려도 안 닫혔다 (2026-11-26 사용자 지적). 여기서 직접 준다.
///
/// 본문 스크롤이 넘칠 때는 본문을 끌면 스크롤이 먼저다(라우트 시트와 같음).
/// 핸들·제목·버튼 줄을 끌거나, 본문이 짧으면 어디를 끌어도 닫힌다.
class OverlaySheet extends StatefulWidget {
  /// 닫는 애니메이션이 끝난 뒤 불린다 — 부모가 시트를 트리에서 뺀다.
  final VoidCallback onClose;
  final Widget child;

  const OverlaySheet({super.key, required this.onClose, required this.child});

  @override
  State<OverlaySheet> createState() => _OverlaySheetState();
}

class _OverlaySheetState extends State<OverlaySheet>
    with SingleTickerProviderStateMixin {
  static const _kDuration = Duration(milliseconds: 260);
  static const _kDismissVelocity = 700.0;

  /// 내려간 비율이 이만큼을 넘으면 손을 떼도 닫는다.
  static const _kDismissFraction = 0.25;

  /// 1 = 다 올라옴, 0 = 화면 밖.
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: _kDuration)
        ..animateTo(1, curve: Curves.easeOutCubic);
  final _sheetKey = GlobalKey();
  bool _closing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _ctrl.animateBack(0, curve: Curves.easeInCubic);
    if (mounted) widget.onClose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_closing) return;
    final h = _sheetKey.currentContext?.size?.height ?? 0;
    if (h <= 0) return;
    _ctrl.value -= (d.primaryDelta ?? 0) / h;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_closing) return;
    final v = d.primaryVelocity ?? 0;
    if (v > _kDismissVelocity || _ctrl.value < 1 - _kDismissFraction) {
      _close();
    } else {
      _ctrl.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            child: FadeTransition(
              opacity: _ctrl,
              child: const ColoredBox(color: AppColors.scrim),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => FractionalTranslation(
              translation: Offset(0, 1 - _ctrl.value),
              child: child,
            ),
            child: GestureDetector(
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: KeyedSubtree(key: _sheetKey, child: widget.child),
            ),
          ),
        ),
      ]),
    );
  }
}
