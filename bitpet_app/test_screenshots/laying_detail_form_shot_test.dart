import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/mock/mock_repositories.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/providers/pet_provider.dart';
import 'package:bitpet_app/features/record/data/models/record_models.dart';
import 'package:bitpet_app/features/record/data/record_repository.dart';
import 'package:bitpet_app/features/record/presentation/record_detail_screen.dart';
import 'package:bitpet_app/features/record/providers/record_provider.dart';
import 'harness.dart';

/// 개체 상세 → 산란 기록 → '+ 기록' 폼. FAB 산란 폼과 같은 모양이어야 한다.
void main() {
  final pet = Pet.fromJson({
    'id': 1, 'name': '루나', 'gender': 'FEMALE', 'speciesName': '크레스티드 게코',
  });
  final now = DateTime.now();
  MatingRecord m(int id, String male, int daysAgo, {bool? ok}) => MatingRecord(
      id: id, femalePetId: 1, malePetName: male,
      triedAt: now.subtract(Duration(days: daysAgo)), isSuccessful: ok,
      createdAt: now);

  testWidgets('산란 추가 폼', (t) async {
    await shot(
      t,
      'laying_detail_form',
      const RecordDetailScreen(petId: 1, recordType: 'laying'),
      overrides: [
        recordRepositoryProvider.overrideWithValue(MockRecordRepository()),
        petDetailProvider(1).overrideWith((ref) async => pet),
        matingListProvider(1).overrideWith((ref) async =>
            [m(1, '레오', 10, ok: true), m(2, '모찌', 30)]),
      ],
      before: (t) async {
        await t.tap(find.text('기록').first);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      },
    );
  });
}
