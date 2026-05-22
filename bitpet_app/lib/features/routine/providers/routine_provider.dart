import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';

// ---------------------------------------------------------------------------
// User's routine list (all routines for the logged-in user)
// ---------------------------------------------------------------------------
final routineListProvider = StateNotifierProvider<RoutineListNotifier, AsyncValue<List<Routine>>>((ref) {
  return RoutineListNotifier(ref.watch(routineRepositoryProvider));
});

class RoutineListNotifier extends StateNotifier<AsyncValue<List<Routine>>> {
  final RoutineRepository _repo;
  RoutineListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getRoutines());
  }
}

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

// ---------------------------------------------------------------------------
// Today's routines with completion status (home screen)
// ---------------------------------------------------------------------------
final todayRoutinesProvider =
    StateNotifierProvider<TodayRoutinesNotifier, AsyncValue<List<TodayRoutine>>>((ref) {
  return TodayRoutinesNotifier(ref.watch(routineRepositoryProvider));
});

class TodayRoutinesNotifier extends StateNotifier<AsyncValue<List<TodayRoutine>>> {
  final RoutineRepository _repo;
  TodayRoutinesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getTodayRoutines());
  }

  void updatePetStatus(int routineId, int petId, bool isCompleted) {
    state.whenData((list) {
      state = AsyncValue.data(list.map((r) {
        if (r.id != routineId) return r;
        return r.copyWithPetStatus(petId, isCompleted);
      }).toList());
    });
  }

  void markAllCompleted(int routineId) {
    state.whenData((list) {
      state = AsyncValue.data(list.map((r) {
        if (r.id != routineId) return r;
        final updated = r.petStatuses.map((s) => TodayPetStatus(
              petId: s.petId,
              petName: s.petName,
              speciesName: s.speciesName,
              colorCode: s.colorCode,
              imageUrl: s.imageUrl,
              isCompleted: true,
              logId: s.logId,
            )).toList();
        return TodayRoutine(
          id: r.id,
          title: r.title,
          routineType: r.routineType,
          alarmTime: r.alarmTime,
          isAlarmEnabled: r.isAlarmEnabled,
          totalPetCount: r.totalPetCount,
          completedPetCount: r.totalPetCount,
          petStatuses: updated,
        );
      }).toList());
    });
  }
}

// ---------------------------------------------------------------------------
// Single routine today status (for accordion detail)
// ---------------------------------------------------------------------------
final routineTodayStatusProvider =
    FutureProvider.family<TodayRoutine?, int>((ref, routineId) async {
  try {
    return await ref.watch(routineRepositoryProvider).getTodayStatus(routineId);
  } catch (_) {
    return null;
  }
});
