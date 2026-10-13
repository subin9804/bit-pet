import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import '../theme/app_colors.dart';

// ════════════════════════════════════════════════════════════════
// 성별 아이콘 — 굵은 선, 45도 기울어진 ♂ / ♀ (수컷 하늘색 / 암컷 분홍)
//
// 머티리얼 `Icons.male`/`Icons.female` 을 걷어낸 자리다. 그 둘은 선이 얇고
// **기울기가 서로 달랐다** — ♂ 는 45도 화살표인데 ♀ 는 수직 십자라, 나란히 놓으면
// 한 쌍으로 안 읽히고 ♀ 쪽만 아래로 처져 보인다. 여기선 둘 다 45도로 맞춰
// 서로 **점대칭**이 되게 그린다 (수컷 ↗ / 암컷 ↙).
//
// ℹ️ **선 색만** 성별로 갈라 칠한다 — 수컷 하늘색(`sexMaleInk`) / 암컷
//   분홍(`sexFemaleInk`) / 미상 `ink3`. 색은 거들기만 하고 구분은 여전히
//   **모양**이 한다(↗ / ↙), 그래서 색맹인 사용자에게도 두 아이콘이 다르다.
//   ⛔ 배경(면)은 칠하지 말 것. 카드마다 원색 블록이 박히면 저채도 화면과
//     부딪힌다 — 가늘고 짧은 선이면 같은 색도 면이 될 때보다 훨씬 조용하다.
//   ⛔ 호출처에서 `color` 로 덮어쓰지 말 것. 성별색이 기본이 된 뒤로 `color` 는
//     '성별을 말하지 않는 자리'(비활성·요약 글줄)에만 쓰는 예외 손잡이다.
//
// ℹ️ 좌표는 24×24 기준으로 적고 `size` 에 맞춰 스케일한다. 선 굵기도 같이
//   스케일되므로 작은 크기에서도 굵기 비율이 유지된다.
// ════════════════════════════════════════════════════════════════

enum PetSex { male, female, unknown }

PetSex petSexFrom(String? raw) => switch (raw?.toUpperCase()) {
      'MALE' => PetSex.male,
      'FEMALE' => PetSex.female,
      _ => PetSex.unknown,
    };

class SexIcon extends StatelessWidget {
  final PetSex sex;
  final double size;
  final Color? color;

  const SexIcon(this.sex, {super.key, this.size = 18, this.color});

  /// 서버가 주는 `'MALE'`/`'FEMALE'` 문자열을 그대로 받는 편의 생성자.
  SexIcon.fromCode(String? code, {Key? key, double size = 18, Color? color})
      : this(petSexFrom(code), key: key, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SexPainter(
          sex: sex,
          // 미상은 '아직 안 정했다'는 보조 정보라 색 없이 한 단 내린다.
          color: color ??
              switch (sex) {
                PetSex.male => AppColors.sexMaleInk,
                PetSex.female => AppColors.sexFemaleInk,
                PetSex.unknown => AppColors.ink3,
              },
        ),
      ),
    );
  }
}

class _SexPainter extends CustomPainter {
  final PetSex sex;
  final Color color;

  const _SexPainter({required this.sex, required this.color});

  // 24×24 기준 설계값
  static const _vb = 24.0;
  static const _r = 5.5; // 원 반지름
  static const _stroke = 2.8; // 굵은 선
  static const _diag = math.sqrt1_2; // cos45 = sin45

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _vb;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    Offset at(double x, double y) => Offset(x * k, y * k);

    switch (sex) {
      case PetSex.unknown:
        // 꼬리가 없는 것이 곧 '미상'이다. 물음표를 넣으면 '오류'로 읽힌다.
        canvas.drawCircle(at(12, 12), _r * k, p);

      case PetSex.male:
        // 원은 좌하, 화살표는 우상(↗).
        const cx = 9.4, cy = 14.6;
        canvas.drawCircle(at(cx, cy), _r * k, p);
        // 꼬리는 원의 테두리에서 시작한다 — 중심에서 그으면 원 안에 선이 비친다.
        final tail = at(cx + _r * _diag, cy - _r * _diag);
        final tip = at(20.2, 3.8);
        canvas.drawLine(tail, tip, p);
        // 화살촉: 꼭지점에서 아래로, 왼쪽으로 (두 변이 45도 꼬리와 각각 45도)
        canvas.drawLine(tip, at(20.2, 9.0), p);
        canvas.drawLine(tip, at(15.0, 3.8), p);

      case PetSex.female:
        // 수컷의 점대칭 — 원은 우상, 십자는 좌하(↙).
        const cx = 14.6, cy = 9.4;
        canvas.drawCircle(at(cx, cy), _r * k, p);
        final tail = at(cx - _r * _diag, cy + _r * _diag);
        const endX = 4.0, endY = 20.0;
        canvas.drawLine(tail, at(endX, endY), p);
        // 교차 막대는 꼬리에 **수직**(즉 ↘ 방향)이라 45도 축이 유지된다.
        const bx = 7.0, by = 17.0; // 꼬리 아래쪽 2/3 지점
        const half = 3.4;
        canvas.drawLine(
          at(bx - half * _diag, by - half * _diag),
          at(bx + half * _diag, by + half * _diag),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_SexPainter old) =>
      old.sex != sex || old.color != color;
}
