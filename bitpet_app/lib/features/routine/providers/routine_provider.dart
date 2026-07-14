import 'dart:async';

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
  DateTime _loadedDate = DateTime.now();
  Timer? _midnightTimer;

  TodayRoutinesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    final now = DateTime.now();
    _loadedDate = DateTime(now.year, now.month, now.day);
    _scheduleMidnightReload();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getTodayRoutines());
  }

  /// 마지막 로드가 오늘이 아니면 다시 불러온다 (앱 백그라운드 복귀 시 호출)
  void reloadIfStale() {
    final now = DateTime.now();
    if (DateTime(now.year, now.month, now.day) != _loadedDate) load();
  }

  /// 자정이 지나면 홈 루틴 카드를 오늘 기준으로 자동 갱신.
  /// 폰이 잠들어 있으면 타이머가 안 울릴 수 있어 reloadIfStale이 보완한다.
  void _scheduleMidnightReload() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 5),
      () {
        if (mounted) load();
      },
    );
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
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
