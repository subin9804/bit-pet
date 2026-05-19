import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';

final routineListProvider =
    FutureProvider.family<List<Routine>, int>((ref, petId) {
  return ref.watch(routineRepositoryProvider).getRoutines(petId);
});
