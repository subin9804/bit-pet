import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pet_models.dart';
import '../data/pet_repository.dart';

final petListProvider =
    StateNotifierProvider<PetListNotifier, AsyncValue<List<Pet>>>((ref) {
  return PetListNotifier(ref.watch(petRepositoryProvider));
});

class PetListNotifier extends StateNotifier<AsyncValue<List<Pet>>> {
  final PetRepository _repo;
  PetListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  /// 폐사(이별) 개체는 항상 목록 마지막으로 (stable sort)
  static List<Pet> _sorted(List<Pet> list) {
    final alive    = list.where((p) => !p.isDeceased);
    final deceased = list.where((p) => p.isDeceased);
    return [...alive, ...deceased];
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _sorted(await _repo.getMyPets()));
  }

  Future<Pet> add(CreatePetRequest request) async {
    final pet = await _repo.createPet(request);
    state.whenData((list) {
      state = AsyncValue.data(_sorted([...list, pet]));
    });
    return pet;
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final pet = await _repo.updatePet(id, data);
    state.whenData((list) {
      state = AsyncValue.data(list.map((p) => p.id == id ? pet : p).toList());
    });
  }

  /// 이별하기 — 폐사 처리 후 목록 재정렬
  Future<void> markDeceased(int id) async {
    final pet = await _repo.markDeceased(id);
    state.whenData((list) {
      state = AsyncValue.data(
          _sorted(list.map((p) => p.id == id ? pet : p).toList()));
    });
  }

  /// 이별 취소
  Future<void> revertDeceased(int id) async {
    final pet = await _repo.revertDeceased(id);
    state.whenData((list) {
      state = AsyncValue.data(
          _sorted(list.map((p) => p.id == id ? pet : p).toList()));
    });
  }

  Future<void> remove(int id) async {
    await _repo.deletePet(id);
    state.whenData((list) {
      state = AsyncValue.data(list.where((p) => p.id != id).toList());
    });
  }
}

final petDetailProvider =
    FutureProvider.family<Pet, int>((ref, id) {
  return ref.watch(petRepositoryProvider).getPet(id);
});

// 전체 종 목록 (SpeciesBottomSheet 초기 로드 및 검색용)
final speciesListProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(petRepositoryProvider).getSpecies();
});

// subcategory 코드(G/L/C/S/T/F/N)별 종 목록
final speciesBySubcategoryProvider =
    FutureProvider.family<List<Species>, String>((ref, subcategory) {
  return ref.watch(petRepositoryProvider).getSpecies(subcategory: subcategory);
});

// 종별 모프 목록 (개체 등록/수정 시 모프 선택용)
final morphsBySpeciesProvider =
    FutureProvider.family<List<Morph>, int>((ref, speciesId) {
  return ref.watch(petRepositoryProvider).getMorphs(speciesId);
});

// 현재 선택된 개체 ID (홈 화면에서 필터용)
final selectedPetIdProvider = StateProvider<int?>((ref) => null);
