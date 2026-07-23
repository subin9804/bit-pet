import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/mock/mock_config.dart';
import '../data/feed_repository.dart';
import '../data/models/feed_models.dart';

// kMockMode = true → Mock, false → 실서버
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  if (kMockMode) return MockFeedRepository();
  return DioFeedRepository(ref.watch(dioProvider));
});

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

  // 즉시 삭제 — UI에서 먼저 제거(낙관적)하되, 서버 실패 시 원상 복구
  Future<void> delete(String sessionId) async {
    final prev = state;
    state.whenData((list) {
      state = AsyncValue.data(list.where((s) => s.id != sessionId).toList());
    });
    try {
      await _repo.deleteSession(petId, sessionId);
    } catch (e) {
      state = prev; // 롤백
      rethrow;
    }
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
