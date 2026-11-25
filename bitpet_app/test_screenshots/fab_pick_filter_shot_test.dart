import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';
import 'package:bitpet_app/features/record/presentation/fab_record_sheet.dart';
import 'fakes.dart';
import 'harness.dart';

/// FAB 개체 선택 — 종 칩을 눌러 개체가 줄어도 시트 높이가 그대로인지 (2026-11-25).
/// 기존 fab_sheet 컷은 시트 높이를 620 으로 고정해 둬서 이 증상이 안 보인다 — 여기선 내용이 정하게 둔다.
Pet _pet(int id, String name, int speciesId, String species) => Pet(
      id: id, serialNo: 'K7M2Q$id', speciesId: speciesId, speciesName: species,
      speciesCategory: 'R', speciesSubcategory: 'GECKO', name: name, gender: 'FEMALE',
      isOwner: true, hatchingDate: DateTime(2025, 3, 10),
    );

final _pets = [
  for (var i = 1; i <= 8; i++) _pet(i, '게코$i', 1, '레오파드 게코'),
  _pet(9, '크레', 2, '크레스티드 게코'),
];

const _sheet = Scaffold(
  backgroundColor: Color(0x66000000),
  body: Align(
    alignment: Alignment.bottomCenter,
    child: Material(
      color: AppColors.card,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: FabRecordSheet(),
    ),
  ),
);

void main() {
  final overrides = [...loggedIn(), petRepositoryProvider.overrideWithValue(FakePetRepo(_pets))];

  Future<void> open(WidgetTester t) async {
    await t.tap(find.text('급여'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('전체', (t) async {
    await shot(t, 'fab_pick_all', _sheet, overrides: overrides, before: open);
  });

  testWidgets('칩으로 1마리만', (t) async {
    await shot(t, 'fab_pick_filtered', _sheet, overrides: overrides, before: (t) async {
      await open(t);
      await t.tap(find.textContaining('크레스티드').first);
      await t.pump(const Duration(milliseconds: 300));
    });
  });
}
