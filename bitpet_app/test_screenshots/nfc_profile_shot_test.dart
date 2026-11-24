import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/nfc/data/models/tag_models.dart';
import 'package:bitpet_app/features/nfc/presentation/nfc_pet_profile_view.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'harness.dart';

const _pet = PetCard(
  petId: 1,
  name: '루나',
  serialNo: 'K7M2QX',
  gender: 'FEMALE',
  speciesName: '레오파드 게코',
  speciesCategory: 'R',
  speciesSubcategory: 'GECKO',
  morphs: [Morph(id: 1, speciesId: 1, nameKo: '마크 스노우'), Morph(id: 2, speciesId: 1, nameKo: '트렘퍼 알비노')],
  privateYn: 'N',
);

void main() {
  testWidgets('이름표 — 남의 개체 (프로필 열림)', (t) async {
    await shot(t, 'nfc_profile_owner', NfcPetProfileView(
      profile: NfcPetProfile(
        pet: _pet.copyWithHatch(),
        latestWeightG: 62.4,
        owner: const PetOwner(userId: 7, nickname: '게코하우스'),
        parents: const [
          PetCard(petId: 2, name: '솔', gender: 'MALE', relationType: 'FATHER',
              speciesName: '레오파드 게코', speciesSubcategory: 'GECKO',
              owner: PetOwner(userId: 7, nickname: '게코하우스')),
          PetCard(petId: 3, name: '모래', gender: 'FEMALE', relationType: 'MOTHER',
              speciesName: '레오파드 게코', speciesSubcategory: 'GECKO',
              owner: PetOwner(userId: 9, nickname: '레오농장')),
        ],
      ),
    ));
  });

  testWidgets('이름표 — 남의 개체 (사육자 비공개)', (t) async {
    await shot(t, 'nfc_profile_hidden', NfcPetProfileView(
      profile: NfcPetProfile(
        // 부모 없음 · 해칭일 부정확(월) · 이별한 개체
        pet: PetCard(
          petId: 1, name: '루나', serialNo: 'K7M2QX', gender: 'FEMALE',
          speciesName: '레오파드 게코', speciesCategory: 'R', speciesSubcategory: 'GECKO',
          privateYn: 'Y', hatchingDate: DateTime(2023, 3, 1),
          hatchingDatePrecision: 'MONTH', hatchingDateApproximate: true,
          deceasedAt: DateTime(2026, 10, 2),
        ),
        owner: const PetOwner(nickname: '비공개'),
      ),
    ));
  });
}

extension on PetCard {
  PetCard copyWithHatch() => PetCard(
        petId: petId, name: name, serialNo: serialNo, gender: gender,
        speciesName: speciesName, speciesCategory: speciesCategory,
        speciesSubcategory: speciesSubcategory, morphs: morphs,
        privateYn: privateYn, hatchingDate: DateTime(2025, 6, 14),
      );
}
