import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_models.dart';
import '../data/post_repository.dart';

// 선택된 카테고리 필터
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// 검색어
final postSearchProvider = StateProvider<String>((ref) => '');

final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  return FeedNotifier(ref.watch(postRepositoryProvider), category);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final PostRepository _repo;
  final String? _category;

  FeedNotifier(this._repo, this._category)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({bool refresh = true}) async {
    if (refresh) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(
        () => _repo.getFeed(categoryCode: _category));
  }
}

final postDetailProvider = StateNotifierProvider.family<PostDetailNotifier,
    AsyncValue<Post?>, int>((ref, id) {
  return PostDetailNotifier(ref.watch(postRepositoryProvider), id);
});

class PostDetailNotifier extends StateNotifier<AsyncValue<Post?>> {
  final PostRepository _repo;
  final int _id;

  PostDetailNotifier(this._repo, this._id)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = await AsyncValue.guard(() => _repo.getPost(_id));
  }

  Future<void> toggleLike() async {
    final post = state.valueOrNull;
    if (post == null) return;
    final wasLiked = post.isLiked;
    // 낙관적 업데이트
    state = AsyncValue.data(post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    ));
    try {
      await _repo.toggleLike(_id, wasLiked);
    } catch (_) {
      // 롤백
      state = AsyncValue.data(post);
    }
  }

  Future<void> toggleBookmark() async {
    final post = state.valueOrNull;
    if (post == null) return;
    final was = post.isBookmarked;
    state = AsyncValue.data(post.copyWith(isBookmarked: !was));
    try {
      await _repo.toggleBookmark(_id, was);
    } catch (_) {
      state = AsyncValue.data(post);
    }
  }
}

final commentsProvider =
    FutureProvider.family<List<PostComment>, int>((ref, postId) {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

// 글쓰기/수정 상태
class ComposeState {
  final String cat;
  final String title;
  final String body;
  final List<String> tags;
  final bool anonymous;
  final bool allowComments;
  final bool notify;
  final bool isSubmitting;

  const ComposeState({
    this.cat = 'free',
    this.title = '',
    this.body = '',
    this.tags = const [],
    this.anonymous = false,
    this.allowComments = true,
    this.notify = true,
    this.isSubmitting = false,
  });

  ComposeState copyWith({
    String? cat,
    String? title,
    String? body,
    List<String>? tags,
    bool? anonymous,
    bool? allowComments,
    bool? notify,
    bool? isSubmitting,
  }) =>
      ComposeState(
        cat: cat ?? this.cat,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        anonymous: anonymous ?? this.anonymous,
        allowComments: allowComments ?? this.allowComments,
        notify: notify ?? this.notify,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  bool get canSubmit =>
      cat.isNotEmpty && title.trim().isNotEmpty && body.trim().isNotEmpty;
}

final composeProvider =
    StateNotifierProvider.autoDispose<ComposeNotifier, ComposeState>(
  (ref) => ComposeNotifier(ref.watch(postRepositoryProvider)),
);

class ComposeNotifier extends StateNotifier<ComposeState> {
  final PostRepository _repo;
  ComposeNotifier(this._repo) : super(const ComposeState());

  void prefill(Post post) {
    state = ComposeState(
      cat: post.categoryCode.toLowerCase(),
      title: post.title,
      body: post.content,
      tags: List.from(post.tags),
    );
  }

  void setCat(String cat) => state = state.copyWith(cat: cat);
  void setTitle(String v) => state = state.copyWith(title: v);
  void setBody(String v) => state = state.copyWith(body: v);
  void addTag(String tag) {
    if (state.tags.length >= 5 || state.tags.contains(tag)) return;
    state = state.copyWith(tags: [...state.tags, tag]);
  }

  void removeTag(String tag) =>
      state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());

  void toggleAnonymous() =>
      state = state.copyWith(anonymous: !state.anonymous);
  void toggleAllowComments() =>
      state = state.copyWith(allowComments: !state.allowComments);
  void toggleNotify() => state = state.copyWith(notify: !state.notify);

  Future<Post?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      return await _repo.createPost(CreatePostRequest(
        categoryCode: state.cat.toUpperCase(),
        title: state.title,
        content: state.body,
        tags: state.tags,
        anonymous: state.anonymous,
        allowComments: state.allowComments,
      ));
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

  Future<Post?> update(int postId) async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      return await _repo.updatePost(
        postId,
        UpdatePostRequest(
          categoryCode: state.cat.toUpperCase(),
          title: state.title,
          content: state.body,
          tags: state.tags,
        ),
      );
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }
}
