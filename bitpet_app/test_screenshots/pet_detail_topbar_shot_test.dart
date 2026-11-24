import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/presentation/pet_detail_screen.dart';
import 'package:bitpet_app/features/pet/providers/pet_provider.dart';
import 'harness.dart';

/// 개체 상세 TopBar — 배경 없이 본문 위에 뜨는지 (맨 위 / 스크롤 후).
void main() {
  final petJson = {
    'id': 1, 'name': '루나', 'gender': 'FEMALE', 'speciesName': '크레스티드 게코',
    'hatchingDate': '2025-06-01', 'latestWeightG': 42.5, 'serialNo': 'BP-0001',
  };
  final pet = Pet.fromJson(petJson);
  final overrides = [
    petDetailProvider(1).overrideWith((ref) async => pet),
    genealogyProvider(1).overrideWith((ref) async => Genealogy(pet: pet)),
  ];
  // 테스트 화면엔 상태바가 없다 — 실기기처럼 위 47 을 비운다.
  Widget screen() => Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(padding: const EdgeInsets.only(top: 47)),
          child: const PetDetailScreen(petId: 1),
        ),
      );

  testWidgets('맨 위', (t) async {
    await shot(t, 'pet_detail_topbar_top', screen(), overrides: overrides);
  });
  testWidgets('스크롤 후', (t) async {
    await shot(t, 'pet_detail_topbar_scrolled', screen(), overrides: overrides,
        before: (t) async {
      await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, -260));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });
  });
}
