import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';
import 'package:bitpet_app/features/pet/presentation/pet_list_screen.dart';
import 'fakes.dart';
import 'harness.dart';

Pet _pet(int id, String name, String species, String sub, String gender,
        {bool owner = true, double? w, List<String> morphs = const []}) =>
    Pet(
      id: id, serialNo: 'K7M2Q$id', speciesId: 1, speciesName: species,
      speciesCategory: 'R', speciesSubcategory: sub, name: name, gender: gender,
      latestWeightG: w, isOwner: owner,
      hatchingDate: DateTime(2025, 3 + id, 10),
      morphs: [for (final (i, m) in morphs.indexed) Morph(id: id * 10 + i, speciesId: 1, nameKo: m)],
    );

final _pets = [
  _pet(1, '루나', '레오파드 게코', 'GECKO', 'FEMALE', w: 62.4, morphs: ['마크 스노우']),
  _pet(2, '모찌', '크레스티드 게코', 'GECKO', 'MALE', w: 38.1, morphs: ['할리퀸']),
  _pet(3, '보리', '볼 파이톤', 'SNAKE', 'MALE', w: 1240, owner: false, morphs: ['파스텔']),
  _pet(4, '콩이', '레오파드 게코', 'GECKO', 'UNKNOWN', w: 21.7),
  _pet(5, '꼬북', '러시안 육지거북', 'TURTLE', 'FEMALE', w: 410, owner: false),
  _pet(6, '라떼', '비어디드 드래곤', 'LIZARD', 'MALE', w: 355),
];

void main() {
  testWidgets('개체 목록', (t) async {
    await shot(t, 'pet_list', const PetListScreen(), overrides: [
      ...loggedIn(),
      petRepositoryProvider.overrideWithValue(FakePetRepo(_pets)),
    ]);
  });

  testWidgets('개체 목록 — 선택 모드 (공유받은 개체 잠김)', (t) async {
    await shot(t, 'pet_list_selecting', const PetListScreen(), overrides: [
      ...loggedIn(),
      petRepositoryProvider.overrideWithValue(FakePetRepo(_pets)),
    ], before: (t) async {
      final el = t.element(find.byType(PetListScreen));
      final c = ProviderScope.containerOf(el);
      c.read(petSelectionModeProvider.notifier).state = true;
      c.read(selectedPetIdsProvider.notifier).state = {1, 4};
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });
  });
}
