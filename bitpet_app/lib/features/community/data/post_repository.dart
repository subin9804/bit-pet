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

  Future<List<Post>> getFeed({String? categoryCode, String? cursor}) async {
    final res = await _dio.get('/diary/feed', queryParameters: {
      if (categoryCode != null) 'category': categoryCode,
      if (cursor != null) 'cursor': cursor,
      'limit': 20,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<Post> getPost(int id) async {
    final res = await _dio.get('/diary/$id');
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
    final res = await _dio.post('/diary', data: request.toJson());
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

  Future<void> deletePost(int id) async {
    await _dio.delete('/diary/$id');
  }

  Future<void> toggleLike(int id, bool currentlyLiked) async {
    if (currentlyLiked) {
      await _dio.delete('/diary/$id/like');
    } else {
      await _dio.post('/diary/$id/like');
    }
  }

  Future<List<PostComment>> getComments(int postId) async {
    final res = await _dio.get('/diary/$postId/comments');
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
    final res = await _dio.post('/diary/$postId/comments', data: {
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
