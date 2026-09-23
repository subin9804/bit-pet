import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/upload/image_upload.dart';
import '../../auth/providers/auth_provider.dart';
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

/// 공지사항 카테고리 코드. id(5)가 아니라 code 로 판정한다 — id 는 DB 마다 갈릴 수 있어
/// 앱에 박아두면 개발 DB 에서만 맞는 화면이 된다. 서버도 같은 기준으로 막는다.
const kNoticeCategoryCode = 'NOTICE';

/// 어린이 게시판. NOTICE 와 같은 이유로 id(6)가 아니라 code 로 판정한다.
const kKidsCategoryCode = 'KIDS';

// 탭에 노출할 카테고리 (INFO·분양 제외). 공지사항은 **모두에게 보인다** — 읽는 건 누구나 한다
final visibleCategoriesProvider = Provider<List<PostCategory>>((ref) {
  final all = ref.watch(categoriesProvider).valueOrNull ?? const <PostCategory>[];
  final me = ref.watch(authStateProvider).valueOrNull;
  // 어린이 게시판은 **아동 본인과 운영자에게만** 보인다.
  // 성인에게는 읽기조차 열지 않는다 — 읽을 수 있으면 그 자체가 아동에게 닿는 통로다.
  // 서버도 KIDS_BOARD_FORBIDDEN 으로 막지만, 탭이 보이는 채로 누를 때마다 에러를 띄우면
  // 있는 게시판을 못 들어가는 것처럼 읽힌다. 아예 없는 것이 맞다.
  final canSeeKids = (me?.isChild ?? false) || (me?.isAdmin ?? false);
  return all
      .where((c) => !kHiddenCategoryCodes.contains(c.code))
      .where((c) => canSeeKids || c.code != kKidsCategoryCode)
      .toList();
});

/// 글쓰기 화면에서 고를 수 있는 카테고리. 운영자가 아니면 공지사항이 빠진다.
///
/// 서버가 어차피 403 을 주지만, 고를 수 있게 열어두고 등록 버튼을 누른 뒤에야
/// 거절하면 사용자는 글을 다 쓰고 나서 못 올린다는 걸 알게 된다.
final composableCategoriesProvider = Provider<List<PostCategory>>((ref) {
  final visible = ref.watch(visibleCategoriesProvider);
  final me = ref.watch(authStateProvider).valueOrNull;

  // 아동은 어린이 게시판에만 쓸 수 있다 (서버 CHILD_BOARD_ONLY).
  // 고를 수 있는 곳이 한 군데뿐이니 선택지를 그것만 남긴다.
  if (me?.isChild ?? false) {
    return visible.where((c) => c.code == kKidsCategoryCode).toList();
  }

  // 운영자도 어린이 게시판에는 **쓰지 못한다** — 쓰기를 열면 '글쓴이 전원이 아동'이라는
  // 이 게시판의 안전 전제가 깨진다. 읽기만 열려 있다.
  final withoutKids =
      visible.where((c) => c.code != kKidsCategoryCode).toList();
  final isAdmin = me?.isAdmin ?? false;
  if (isAdmin) return withoutKids;
  return withoutKids.where((c) => c.code != kNoticeCategoryCode).toList();
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

/// 사진 첨부 칸 하나. **이미 서버에 올라간 사진**과 **방금 고른 사진**이 한 줄에 섞인다.
/// 수정 화면에서 기존 사진을 보여주려면 둘을 같은 목록으로 다뤄야 순서·개수(5장)를
/// 한 군데서 셀 수 있다.
class ComposeAttachment {
  final int? photoId; // 서버에 있는 사진
  final String? url; // 그 사진의 presigned view URL
  final PickedImage? picked; // 새로 고른 사진 (아직 안 올라감)

  const ComposeAttachment.existing(int this.photoId, String this.url)
      : picked = null;
  // 이름이 `picked` 가 아닌 건 Dart 에서 생성자와 필드가 같은 이름을 못 쓰기 때문.
  const ComposeAttachment.added(PickedImage this.picked)
      : photoId = null,
        url = null;

  bool get isExisting => photoId != null;
}

/// 첨부 사진 업로드가 일부/전부 실패했을 때. 글 본문은 이미 저장된 뒤라
/// "저장 실패"로 뭉뚱그리면 안 된다 — 사진만 다시 올리면 되는 상태다.
class PhotoUploadFailure implements Exception {
  final int failed;
  const PhotoUploadFailure(this.failed);
  @override
  String toString() => '사진 $failed장을 올리지 못했어요. 다시 시도해 주세요.';
}

const int kMaxPostPhotos = 5;

class ComposeState {
  final int? categoryId;
  final String title;
  final String body;
  final List<ComposeAttachment> attachments; // 첨부 사진 (최대 5장)
  final bool isSubmitting;

  const ComposeState({
    this.categoryId,
    this.title = '',
    this.body = '',
    this.attachments = const [],
    this.isSubmitting = false,
  });

  ComposeState copyWith({
    int? categoryId,
    String? title,
    String? body,
    List<ComposeAttachment>? attachments,
    bool? isSubmitting,
  }) =>
      ComposeState(
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        body: body ?? this.body,
        attachments: attachments ?? this.attachments,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  bool get canSubmit =>
      categoryId != null && title.trim().isNotEmpty && body.trim().isNotEmpty;

  int get remainingSlots => kMaxPostPhotos - attachments.length;
}

final composeProvider =
    StateNotifierProvider.autoDispose<ComposeNotifier, ComposeState>(
  (ref) => ComposeNotifier(ref.watch(postRepositoryProvider)),
);

class ComposeNotifier extends StateNotifier<ComposeState> {
  final PostRepository _repo;
  ComposeNotifier(this._repo) : super(const ComposeState());

  /// 새 글에서 본문 저장까지는 됐는데 사진에서 막힌 경우. 다시 '등록'을 누르면
  /// 글을 또 만들지 않고 **남은 사진만** 이어서 올린다.
  Post? _createdPost;

  /// 수정 화면에서 X 를 누른 기존 사진들. 저장을 눌러야 실제로 지운다 —
  /// 누르자마자 지우면 '취소'로 나가도 사진이 이미 사라져 있다.
  final List<int> _removedPhotoIds = [];

  void prefill(Post post) {
    state = ComposeState(
      categoryId: post.categoryId,
      title: post.title,
      body: post.content,
      attachments: post.photos
          .map((p) => ComposeAttachment.existing(p.id, p.url))
          .toList(),
    );
    _removedPhotoIds.clear();
  }

  void setCategory(int categoryId) =>
      state = state.copyWith(categoryId: categoryId);
  void setTitle(String v) => state = state.copyWith(title: v);
  void setBody(String v) => state = state.copyWith(body: v);

  /// 고른 사진들을 남은 칸만큼만 받는다. 갤러리가 limit 을 무시해도 여기서 잘린다.
  void addImages(List<PickedImage> images) {
    if (images.isEmpty) return;
    final room = state.remainingSlots;
    if (room <= 0) return;
    state = state.copyWith(attachments: [
      ...state.attachments,
      ...images.take(room).map(ComposeAttachment.added),
    ]);
  }

  void removeAttachment(int index) {
    final next = [...state.attachments];
    final removed = next.removeAt(index);
    if (removed.photoId != null) _removedPhotoIds.add(removed.photoId!);
    state = state.copyWith(attachments: next);
  }

  /// 아직 안 올라간 사진들을 순서대로 올린다. 올라간 것은 목록에서 빼서
  /// 재시도할 때 같은 사진이 두 번 올라가지 않게 한다.
  ///
  /// ⛔ 실패를 삼키지 말 것. 예전엔 `catch (_) {}` 라서 두 번째 장부터 조용히
  /// 사라져도 사용자도 우리도 알 방법이 없었다.
  Future<void> _uploadPending(int postId, {required int startOrder}) async {
    var order = startOrder;
    var failed = 0;
    final remaining = <ComposeAttachment>[];

    for (final a in state.attachments) {
      if (a.picked == null) {
        remaining.add(a);
        continue;
      }
      try {
        await _repo.uploadPostPhoto(postId, a.picked!, order++);
      } catch (_) {
        failed++;
        remaining.add(a); // 실패한 것만 남겨 다시 시도할 수 있게
      }
    }

    if (mounted) state = state.copyWith(attachments: remaining);
    if (failed > 0) throw PhotoUploadFailure(failed);
  }

  Future<Post?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      final post = _createdPost ??
          await _repo.createPost(CreatePostRequest(
            categoryId: state.categoryId!,
            title: state.title,
            content: state.body,
          ));
      _createdPost = post;
      await _uploadPending(post.id, startOrder: 0);
      return post;
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

  Future<Post?> update(int postId) async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      final post = await _repo.updatePost(
        postId,
        UpdatePostRequest(
          categoryId: state.categoryId!,
          title: state.title,
          content: state.body,
        ),
      );
      // 지운 사진 먼저 — 5장 제한이 서버에 있어서, 자리를 비우기 전에 올리면
      // 교체(한 장 지우고 한 장 추가)가 막힌다.
      for (final id in [..._removedPhotoIds]) {
        try {
          await _repo.deletePostPhoto(postId, id);
          _removedPhotoIds.remove(id);
        } catch (_) {}
      }
      await _uploadPending(
        postId,
        startOrder: state.attachments.where((a) => a.isExisting).length,
      );
      return post;
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
