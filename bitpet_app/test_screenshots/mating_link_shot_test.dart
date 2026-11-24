import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_colors.dart';
import 'package:bitpet_app/features/record/data/models/record_models.dart';
import 'package:bitpet_app/features/record/presentation/widgets/mating_link_picker.dart';
import 'package:bitpet_app/features/record/providers/record_provider.dart';
import 'harness.dart';

MatingRecord _m(int id, String? male, DateTime at, {bool? ok, String? ext}) => MatingRecord(
      id: id, femalePetId: 1, malePetName: male, externalPartnerText: ext,
      triedAt: at, isSuccessful: ok, createdAt: at,
    );

// 메이팅이 많은 암컷 — 목록이 상자 안에서 스크롤돼야 한다
final _matings = [
  _m(1, '레오', DateTime(2026, 11, 2), ok: true),
  _m(2, '레오', DateTime(2026, 10, 20)),
  _m(3, null, DateTime(2026, 10, 3), ext: '분양샵 수컷 K7'),
  _m(4, '모찌', DateTime(2026, 9, 14), ok: false),
  _m(5, '모찌', DateTime(2026, 8, 30), ok: true),
  _m(6, '레오', DateTime(2025, 6, 2), ok: true),
];

void main() {
  testWidgets('산란 — 메이팅 기록 연결 목록', (t) async {
    await shot(
      t,
      'mating_link_picker',
      Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MatingLinkPicker(
              petId: 1,
              laidAt: DateTime(2026, 11, 20),
              chosen: false,
              selectedId: null,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
      overrides: [matingListProvider(1).overrideWith((ref) async => _matings)],
    );
  });
}
