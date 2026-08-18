import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/upload/image_upload.dart';
import '../data/models/post_models.dart';
import '../data/post_repository.dart';

// 선택된 카테고리 필터 (null = 전체). 서버 categoryId(Long) 기준.
final categoryFilterProvider = StateProvider<int?>((ref) => null);

// 검색어 (현재 로드된 목록에 대한 클라이언트 필터)
final postSearchProvider = StateProvider<String>((ref) => '');

// 카테고리 전체 목록 (게시글 라벨/색상 해석용 — 숨긴 카테고리도 포함)
final categoriesProvider = FutureProvider<List<PostCategory>>((ref) {
  return ref.watch(postRepositoryProvider).getCategories();
});

// MVP에서 화면에 노출하지 않을 카테고리 코드 (추후 확장 시 사용)
const kHiddenCategoryCodes = {'INFO', 'ADOPTION'};

// 탭/글쓰기에서 실제로 선택 가능한 카테고리 (INFO·분양 제외)
final visibleCategoriesProvider = Provider<List<PostCategory>>((ref) {
  final all = ref.watch(categoriesProvider).valueOrNull ?? const <PostCategory>[];
  return all.where((c) => !kHiddenCategoryCodes.contains(c.code)).toList();
});

// ── 피드 (무한 스크롤) ────────────────────────────────────────────────
class FeedState {
  final List<Post> posts;
  final bool loading; // 최초 로드
  final bool loadingMore; // 다음 페이지 로드
  final bool hasMore;
  final Object? error;

  const FeedState({
    this.posts = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

final feedProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final categoryId = ref.watch(categoryFilterProvider);
  return FeedNotifier(ref.watch(postRepositoryProvider), categoryId);
});

class FeedNotifier extends StateNotifier<FeedState> {
  final PostRepository _repo;
  final int? _categoryId;
  int _page = 0;

  FeedNotifier(this._repo, this._categoryId) : super(const FeedState()) {
    refresh();
  }

  Future<void> refresh() async {
    _page = 0;
    state = const FeedState(loading: true);
    try {
      final p = await _repo.getFeed(categoryId: _categoryId, page: 0);
      state = FeedState(posts: p.items, loading: false, hasMore: !p.last);
    } catch (e) {
      state = FeedState(loading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = _page + 1;
      final p = await _repo.getFeed(categoryId: _categoryId, page: next);
      _page = next;
      state = state.copyWith(
        posts: [...state.posts, ...p.items],
        loadingMore: false,
        hasMore: !p.last,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

// ── 상세 ──────────────────────────────────────────────────────────────
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
      final result = await _repo.toggleLike(_id);
      state = AsyncValue.data(post.copyWith(
        isLiked: result.liked,
        likeCount: result.likeCount,
      ));
    } catch (_) {
      state = AsyncValue.data(post); // 롤백
    }
  }
}

final commentsProvider =
    FutureProvider.family<List<PostComment>, int>((ref, postId) {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

// ── 글쓰기/수정 상태 ──────────────────────────────────────────────────
class ComposeState {
  final int? categoryId;
  final String title;
  final String body;
  final List<PickedImage> images; // 첨부 이미지 (최대 5장)
  final bool isSubmitting;

  const ComposeState({
    this.categoryId,
    this.title = '',
    this.body = '',
    this.images = const [],
    this.isSubmitting = false,
  });

  ComposeState copyWith({
    int? categoryId,
    String? title,
    String? body,
    List<PickedImage>? images,
    bool? isSubmitting,
  }) =>
      ComposeState(
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        body: body ?? this.body,
        images: images ?? this.images,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  bool get canSubmit =>
      categoryId != null && title.trim().isNotEmpty && body.trim().isNotEmpty;
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
      categoryId: post.categoryId,
      title: post.title,
      body: post.content,
    );
  }

  void setCategory(int categoryId) =>
      state = state.copyWith(categoryId: categoryId);
  void setTitle(String v) => state = state.copyWith(title: v);
  void setBody(String v) => state = state.copyWith(body: v);

  void addImage(PickedImage image) {
    if (state.images.length >= 5) return;
    state = state.copyWith(images: [...state.images, image]);
  }

  void removeImage(int index) {
    final next = [...state.images]..removeAt(index);
    state = state.copyWith(images: next);
  }

  Future<Post?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      final post = await _repo.createPost(CreatePostRequest(
        categoryId: state.categoryId!,
        title: state.title,
        content: state.body,
      ));
      // 게시글 생성 후 첨부 이미지 업로드 (개별 실패는 무시)
      for (var i = 0; i < state.images.length; i++) {
        try {
          await _repo.uploadPostPhoto(post.id, state.images[i], i);
        } catch (_) {}
      }
      return post;
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
          categoryId: state.categoryId!,
          title: state.title,
          content: state.body,
        ),
      );
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }
}

// ── 마이페이지 > 내 게시글 / 내 댓글 ──────────────────────────────────
//
// autoDispose 로 둔다. 마이페이지에서 들어갔다 나오는 화면이라 목록을 붙들고 있을
// 이유가 없고, 다시 들어올 때 최신 상태로 다시 받는 편이 맞다.

class MyPostsState {
  final List<Post> posts;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const MyPostsState({
    this.posts = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  MyPostsState copyWith({
    List<Post>? posts,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
  }) =>
      MyPostsState(
        posts: posts ?? this.posts,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

final myPostsProvider =
    StateNotifierProvider.autoDispose<MyPostsNotifier, MyPostsState>(
        (ref) => MyPostsNotifier(ref.watch(postRepositoryProvider)));

class MyPostsNotifier extends StateNotifier<MyPostsState> {
  final PostRepository _repo;
  int _page = 0;

  MyPostsNotifier(this._repo) : super(const MyPostsState()) {
    refresh();
  }

  Future<void> refresh() async {
    _page = 0;
    state = const MyPostsState(loading: true);
    try {
      final p = await _repo.getMyPosts(page: 0);
      state = MyPostsState(posts: p.items, loading: false, hasMore: !p.last);
    } catch (e) {
      state = MyPostsState(loading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = _page + 1;
      final p = await _repo.getMyPosts(page: next);
      _page = next;
      state = state.copyWith(
        posts: [...state.posts, ...p.items],
        loadingMore: false,
        hasMore: !p.last,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

class MyCommentsState {
  final List<MyComment> comments;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const MyCommentsState({
    this.comments = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  MyCommentsState copyWith({
    List<MyComment>? comments,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
  }) =>
      MyCommentsState(
        comments: comments ?? this.comments,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

final myCommentsProvider =
    StateNotifierProvider.autoDispose<MyCommentsNotifier, MyCommentsState>(
        (ref) => MyCommentsNotifier(ref.watch(postRepositoryProvider)));

class MyCommentsNotifier extends StateNotifier<MyCommentsState> {
  final PostRepository _repo;
  int _page = 0;

  MyCommentsNotifier(this._repo) : super(const MyCommentsState()) {
    refresh();
  }

  Future<void> refresh() async {
    _page = 0;
    state = const MyCommentsState(loading: true);
    try {
      final p = await _repo.getMyComments(page: 0);
      state =
          MyCommentsState(comments: p.items, loading: false, hasMore: !p.last);
    } catch (e) {
      state = MyCommentsState(loading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = _page + 1;
      final p = await _repo.getMyComments(page: next);
      _page = next;
      state = state.copyWith(
        comments: [...state.comments, ...p.items],
        loadingMore: false,
        hasMore: !p.last,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}
