import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_repository.dart';
import '../data/models/feed_models.dart';

// Repository provider — MockFeedRepository를 기본값으로, DioFeedRepository로 교체 가능
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => MockFeedRepository(),
);

// 급여 세션 StateNotifier
class FeedSessionsNotifier
    extends StateNotifier<AsyncValue<List<FeedSession>>> {
  final FeedRepository _repo;
  final int petId;

  FeedSessionsNotifier(this._repo, this.petId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getSessions(petId));
  }

  Future<void> add(FeedSession session) async {
    final added = await _repo.addSession(petId, session);
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  Future<void> update(FeedSession session) async {
    final updated = await _repo.updateSession(petId, session);
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((s) => s.id == updated.id ? updated : s).toList(),
      );
    });
  }

  // hard delete — 바로 삭제 (낙관적 X, UI가 즉시 반영)
  Future<void> delete(String sessionId) async {
    state.whenData((list) {
      state = AsyncValue.data(list.where((s) => s.id != sessionId).toList());
    });
    await _repo.deleteSession(petId, sessionId);
  }
}

final feedSessionsProvider = StateNotifierProvider.family<
    FeedSessionsNotifier, AsyncValue<List<FeedSession>>, int>(
  (ref, petId) =>
      FeedSessionsNotifier(ref.watch(feedRepositoryProvider), petId),
);

// 정렬된 세션 (최신순)
final sortedFeedSessionsProvider =
    Provider.family<AsyncValue<List<FeedSession>>, int>((ref, petId) {
  return ref.watch(feedSessionsProvider(petId)).whenData((list) {
    final sorted = [...list]
      ..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        return cmp != 0 ? cmp : b.time.compareTo(a.time);
      });
    return sorted;
  });
});
