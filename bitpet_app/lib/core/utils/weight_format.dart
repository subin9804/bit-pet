/// 체중(g) 표시 — 반올림하지 않고 입력한 값 그대로 보여준다.
///
/// 서버 `weight_dtl.weight_g` 가 소수 2자리(NUMERIC(8,2))라 [maxDecimals] 기본값도 2.
/// 끝의 0과 소수점은 떼어낸다: 52.00 → "52", 52.50 → "52.5", 52.25 → "52.25".
/// `toStringAsFixed(0)` 으로 찍으면 52.5g 이 "53g" 으로 보인다 — 파충류는 1g 차이도 의미가 크다.
String formatWeight(double g, {int maxDecimals = 2}) {
  var s = g.toStringAsFixed(maxDecimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s == '-0' ? '0' : s;
}

/// 증감 표시용 — 양수에 '+' 를 붙인다. 부동소수 오차(0.1999…)는 [maxDecimals] 에서 정리된다.
String formatWeightDelta(double delta, {int maxDecimals = 2}) {
  final s = formatWeight(delta, maxDecimals: maxDecimals);
  return delta > 0 && s != '0' ? '+$s' : s;
}
