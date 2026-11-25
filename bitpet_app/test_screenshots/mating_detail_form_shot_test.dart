import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/mock/mock_repositories.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';
import 'package:bitpet_app/features/pet/providers/pet_provider.dart';
import 'package:bitpet_app/features/record/data/record_repository.dart';
import 'package:bitpet_app/features/record/presentation/record_detail_screen.dart';
import 'package:bitpet_app/features/record/providers/record_provider.dart';
import 'harness.dart';

Pet _pet(int id, String name, String gender) => Pet.fromJson({
      'id': id, 'name': name, 'gender': gender,
      'speciesName': '크레스티드 게코', 'serialNo': 'AB12CD3$id',
    });

final _luna = _pet(1, '루나', 'FEMALE');
final _mine = [_luna, _pet(2, '레오', 'MALE'), _pet(3, '모찌', 'MALE'),
  _pet(4, '보리', 'FEMALE')];

class _PetRepo extends PetRepository {
  _PetRepo() : super(Dio());
  @override
  Future<List<Pet>> getMyPets() async => _mine;
}

/// 개체 상세 → 교배 기록 → '+ 기록' 폼. FAB 메이팅 폼과 같은 모양이어야 한다.
void main() {
  final overrides = [
    recordRepositoryProvider.overrideWithValue(MockRecordRepository()),
    petRepositoryProvider.overrideWithValue(_PetRepo()),
    petDetailProvider(1).overrideWith((ref) async => _luna),
    matingListProvider(1).overrideWith((ref) async => const []),
  ];

  Future<void> open(WidgetTester t) async {
    await t.tap(find.text('기록').first);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('메이팅 추가 폼 — 내 개체', (t) async {
    await shot(t, 'mating_detail_form',
        const RecordDetailScreen(petId: 1, recordType: 'mating'),
        overrides: overrides, before: (t) async {
      await open(t);
      await t.tap(find.text('레오'));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.text('성공'));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 200));
    });
  });

  testWidgets('메이팅 추가 폼 — 외부 개체', (t) async {
    await shot(t, 'mating_detail_form_external',
        const RecordDetailScreen(petId: 1, recordType: 'mating'),
        overrides: overrides, before: (t) async {
      await open(t);
      await t.tap(find.text('외부 개체'));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 200));
    });
  });

  testWidgets('끌어내리는 중', (t) async {
    await shot(t, 'mating_detail_form_drag',
        const RecordDetailScreen(petId: 1, recordType: 'mating'),
        overrides: overrides, before: (t) async {
      await open(t);
      final g = await t.startGesture(t.getCenter(find.text('기록 추가')));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, 20));
        await t.pump(const Duration(milliseconds: 16));
      }
    });
  });

  testWidgets('끌어내려 놓으면 닫힘', (t) async {
    await shot(t, 'mating_detail_form_dismissed',
        const RecordDetailScreen(petId: 1, recordType: 'mating'),
        overrides: overrides, before: (t) async {
      await open(t);
      await t.drag(find.text('기록 추가'), const Offset(0, 300));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('기록 추가'), findsNothing);
    });
  });
}
