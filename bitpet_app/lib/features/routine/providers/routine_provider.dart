import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';

// ---------------------------------------------------------------------------
// User's routine list (all routines for the logged-in user)
// ---------------------------------------------------------------------------
final routineListProvider = FutureProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).getRoutines();
});

// ---------------------------------------------------------------------------
// Single routine detail
// ---------------------------------------------------------------------------
final routineDetailProvider =
    FutureProvider.family<Routine, int>((ref, routineId) {
  return ref.watch(routineRepositoryProvider).getRoutine(routineId);
});

// ---------------------------------------------------------------------------
// Routines for a specific pet (with subscription status) — SCR-08
// ---------------------------------------------------------------------------
final routinesForPetProvider =
    FutureProvider.family<List<RoutineWithSubscription>, int>((ref, petId) {
  return ref.watch(routineRepositoryProvider).getRoutinesForPet(petId);
});

// ---------------------------------------------------------------------------
// Routine logs for a routine
// ---------------------------------------------------------------------------
final routineLogsProvider =
    FutureProvider.family<List<RoutineLog>, int>((ref, routineId) {
  return ref.watch(routineRepositoryProvider).getLogs(routineId);
});
