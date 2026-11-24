import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/providers/pet_provider.dart';
import 'package:bitpet_app/features/pet/share/presentation/pet_share_screen.dart';
import 'package:bitpet_app/features/pet/share/providers/share_provider.dart';
import 'harness.dart';

/// 이별한 개체의 공유 관리 — 초대 칸 대신 안내.
void main() {
  testWidgets('이별한 개체 공유 관리', (t) async {
    final pet = Pet.fromJson({
      'id': 1, 'name': '루나', 'gender': 'FEMALE', 'speciesName': '크레스티드 게코',
      'deceasedAt': '2026-11-01',
    });
    await shot(t, 'pet_share_deceased', const PetShareScreen(petId: 1),
        pushed: true,
        overrides: [
          petDetailProvider(1).overrideWith((ref) async => pet),
          petKeepersProvider(1).overrideWith((ref) async => []),
          petSentInvitationsProvider(1).overrideWith((ref) async => []),
        ]);
  });
}
