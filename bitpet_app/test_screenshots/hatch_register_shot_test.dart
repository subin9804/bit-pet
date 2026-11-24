import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/features/record/data/models/record_models.dart';
import 'package:bitpet_app/features/record/presentation/laying/hatch_register_sheet.dart';
import 'harness.dart';

void main() {
  testWidgets('알 → 개체 등록 시트', (t) async {
    final hatch = HatchRecord(
        id: 11, layingId: 1, eggIndex: 2, status: HatchStatus.HATCHED,
        hatchedAt: DateTime(2026, 11, 20));
    final laying = LayingRecord(
      id: 1, petId: 1, petName: '루나', speciesName: '크레스티드 게코',
      laidAt: DateTime(2026, 9, 10), totalCount: 2,
      hatches: [hatch], createdAt: DateTime(2026, 9, 10),
    );
    await shot(
      t,
      'hatch_register_sheet',
      Scaffold(
        backgroundColor: AppColors.canvas,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: HatchRegisterSheet(laying: laying, queue: [hatch]),
        ),
      ),
    );
  });
}
