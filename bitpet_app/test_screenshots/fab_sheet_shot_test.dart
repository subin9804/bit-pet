import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';
import 'package:bitpet_app/features/record/presentation/fab_record_sheet.dart';
import 'fakes.dart';
import 'harness.dart';

Pet _pet(int id, String name, String gender) => Pet(
      id: id, serialNo: 'K7M2Q$id', speciesId: 1, speciesName: '레오파드 게코',
      speciesCategory: 'R', speciesSubcategory: 'GECKO', name: name, gender: gender,
      isOwner: true, hatchingDate: DateTime(2025, 3 + id, 10),
    );

final _pets = [_pet(1, '루나', 'FEMALE'), _pet(2, '모찌', 'MALE'), _pet(3, '콩이', 'UNKNOWN')];

// 바텀시트 모양 그대로 — 화면 아래 흰 시트
const _sheet = Scaffold(
  backgroundColor: Color(0x66000000),
  body: Align(
    alignment: Alignment.bottomCenter,
    child: Material(
      color: AppColors.card,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(height: 620, child: FabRecordSheet()),
    ),
  ),
);

void main() {
  final overrides = [...loggedIn(), petRepositoryProvider.overrideWithValue(FakePetRepo(_pets))];

  testWidgets('FAB 시트 — 종류 선택', (t) async {
    await shot(t, 'fab_choose_type', _sheet, overrides: overrides);
  });

  testWidgets('FAB 시트 — 개체 선택', (t) async {
    await shot(t, 'fab_choose_pet', _sheet, overrides: overrides, before: (t) async {
      await t.tap(find.text('급여'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });
  });
}
