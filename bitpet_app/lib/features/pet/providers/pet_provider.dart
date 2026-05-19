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

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getMyPets());
  }

  Future<void> add(CreatePetRequest request) async {
    final pet = await _repo.createPet(request);
    state.whenData((list) {
      state = AsyncValue.data([...list, pet]);
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

final speciesListProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(petRepositoryProvider).getSpecies();
});

// 현재 선택된 개체 ID (홈 화면에서 필터용)
final selectedPetIdProvider = StateProvider<int?>((ref) => null);
