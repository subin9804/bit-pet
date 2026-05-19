import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_models.dart';
import '../data/post_repository.dart';

// 선택된 카테고리 필터
final categoryFilterProvider = StateProvider<String?>((ref) => null);

final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  return FeedNotifier(ref.watch(postRepositoryProvider), category);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final PostRepository _repo;
  final String? _category;
  String? _cursor;

  FeedNotifier(this._repo, this._category)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({bool refresh = true}) async {
    if (refresh) {
      _cursor = null;
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(
        () => _repo.getFeed(categoryCode: _category, cursor: _cursor));
  }
}

final postDetailProvider = FutureProvider.family<Post, int>((ref, id) {
  return ref.watch(postRepositoryProvider).getPost(id);
});

final commentsProvider =
    FutureProvider.family<List<PostComment>, int>((ref, postId) {
  return ref.watch(postRepositoryProvider).getComments(postId);
});
