import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/core/widgets/step_shell.dart';
import 'package:bitpet_app/features/home/presentation/widgets/home_banner.dart';
import 'harness.dart';

Widget _page(List<Widget> children) => Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: children),
      ),
    );

void main() {
  testWidgets('공용 위젯 — 단계 요약 카드 · 홈 배너', (t) async {
    await shot(t, 'widgets_summary_banner', _page([
      StepSummary(goEdit: (_) {}, groups: const [
        StepSummaryGroup(label: '기본 정보', step: 0, rows: [
          StepSummaryRow(k: '이름', v: '루나'),
          StepSummaryRow(k: '종', v: '레오파드 게코'),
          StepSummaryRow(k: '성별', v: '암컷'),
        ]),
        StepSummaryGroup(label: '모프', step: 1, rows: [
          StepSummaryRow(k: '모프', v: '마크 스노우, 트렘퍼 알비노'),
        ]),
      ]),
      const SizedBox(height: 24),
      const HomeBanner(items: [
        HomeBannerItem(title: 'tailog 정식 오픈', body: '이름표를 붙이고 기록을 시작해 보세요', badge: '공지'),
      ]),
      const SizedBox(height: 24),
      // 링크가 있는 배너 여러 장 — 오른쪽 꺾쇠 + 아래 점
      HomeBanner(onTap: (_) {}, items: const [
        HomeBannerItem(title: '커뮤니티가 열렸어요', body: '내 개체를 자랑해 보세요', badge: '이벤트', route: '/community'),
        HomeBannerItem(title: '이름표 주문하기', url: 'https://smartstore.naver.com/tailog_factory'),
      ]),
    ]));
  });
}
