import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/post_models.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(dioProvider));
});

class PostRepository {
  final Dio _dio;
  PostRepository(this._dio);

  // ── 카테고리 ────────────────────────────────────────────────────────
  Future<List<PostCategory>> getCategories() async {
    final res = await _dio.get('/post-categories');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => PostCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // ── 피드 (페이지네이션 / 공지 상단 고정) ─────────────────────────────
  Future<PostPage> getFeed({int? categoryId, int page = 0, int size = 20}) async {
    final res = await _dio.get('/posts', queryParameters: {
      if (categoryId != null) 'categoryId': categoryId,
      'page': page,
      'size': size,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    final data = apiRes.data ?? const <String, dynamic>{};
    final content = (data['content'] as List<dynamic>? ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
    return PostPage(
      items: content,
      last: data['last'] as bool? ?? true,
      page: data['number'] as int? ?? page,
    );
  }

  Future<Post> getPost(int id) async {
    final res = await _dio.get('/posts/$id');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Post.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '게시글을 불러오지 못했습니다.');
    }
    return apiRes.data!;
  }

  Future<Post> createPost(CreatePostRequest request) async {
    final res = await _dio.post('/posts', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Post.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '게시글 작성 실패');
    }
    return apiRes.data!;
  }

  Future<Post> updatePost(int id, UpdatePostRequest request) async {
    final res = await _dio.patch('/posts/$id', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Post.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '게시글 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deletePost(int id) async {
    await _dio.delete('/posts/$id');
  }

  // ── 좋아요 (단일 토글) ───────────────────────────────────────────────
  Future<LikeResult> toggleLike(int id) async {
    final res = await _dio.post('/posts/$id/like');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    final data = apiRes.data ?? const <String, dynamic>{};
    return LikeResult(
      liked: data['liked'] as bool? ?? false,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  // ── 댓글 ────────────────────────────────────────────────────────────
  Future<List<PostComment>> getComments(int postId) async {
    final res = await _dio.get('/posts/$postId/comments');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<PostComment> addComment(int postId, String content,
      {int? parentCommentId}) async {
    final res = await _dio.post('/posts/$postId/comments', data: {
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => PostComment.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '댓글 작성 실패');
    }
    return apiRes.data!;
  }
}
