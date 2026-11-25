import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/features/record/presentation/widgets/feed_composer_fields.dart';
import 'harness.dart';

Widget _composer(FeedFormData form) => Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FeedComposerFields(form: form, onChanged: (_) {}),
        ),
      ),
    );

void main() {
  testWidgets('급여 입력 — 직접입력', (t) async {
    await shot(t, 'feed_composer_custom', _composer(const FeedFormData(
      foodType: FoodType.custom,
      customText: '밀웜 (냉동)',
      sizeLabel: '반 스푼',
    )));
  });

  testWidgets('급여 입력 — 귀뚜라미', (t) async {
    await shot(t, 'feed_composer_cricket', _composer(const FeedFormData(
      foodType: FoodType.cricket,
      sizeLabel: '중',
      count: 5,
    )));
  });

  testWidgets('급여 입력 — 슈퍼푸드', (t) async {
    await shot(t, 'feed_composer_superfood', _composer(const FeedFormData(
      foodType: FoodType.superfood,
    )));
  });
}
