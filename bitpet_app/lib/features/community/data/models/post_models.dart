// 커뮤니티 모델 — 서버(io.bitpet.community) 응답 계약 기준
//
// 서버 카테고리: FREE / QNA / INFO / ADOPTION (id 는 서버가 부여)
// 게시글 목록은 Spring Page 로 내려오며, pinned(공지) 항목이 항상 상단에 온다.

class PostCategory {
  final int id;
  final String code; // FREE / QNA / INFO / ADOPTION
  final String nameKo;
  final int displayOrder;

  const PostCategory({
    required this.id,
    required this.code,
    required this.nameKo,
    required this.displayOrder,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) => PostCategory(
        id: json['id'] as int,
        code: json['code'] as String,
        nameKo: json['nameKo'] as String? ?? json['code'] as String,
        displayOrder: json['displayOrder'] as int? ?? 0,
      );
}

class Post {
  final int id;
  final int userId;
  final String authorName;
  final String? authorImageUrl;
  final int categoryId;
  final String title;
  final String content; // 목록 응답엔 없음 → 빈 문자열
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isPinned;
  final String? thumbnailUrl;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorImageUrl,
    required this.categoryId,
    required this.title,
    this.content = '',
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    this.isPinned = false,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        userId: json['userId'] as int,
        authorName: json['authorName'] as String? ?? '알 수 없음',
        authorImageUrl: json['authorImageUrl'] as String?,
        categoryId: json['categoryId'] as int,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        viewCount: json['viewCount'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        isLiked: json['likedByMe'] as bool? ?? false,
        isPinned: json['pinned'] as bool? ?? false,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Post copyWith({
    bool? isLiked,
    int? likeCount,
  }) =>
      Post(
        id: id,
        userId: userId,
        authorName: authorName,
        authorImageUrl: authorImageUrl,
        categoryId: categoryId,
        title: title,
        content: content,
        viewCount: viewCount,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        isLiked: isLiked ?? this.isLiked,
        isPinned: isPinned,
        thumbnailUrl: thumbnailUrl,
        createdAt: createdAt,
      );
}

class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String authorName;
  final String? authorImageUrl;
  final bool isPostAuthor; // 게시글 작성자가 단 댓글 → '작성자' 뱃지
  final int? parentCommentId;
  final String content;
  final List<PostComment> replies;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.authorImageUrl,
    this.isPostAuthor = false,
    this.parentCommentId,
    required this.content,
    this.replies = const [],
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as int,
        postId: json['postId'] as int,
        userId: json['userId'] as int,
        authorName: json['authorName'] as String? ?? '알 수 없음',
        authorImageUrl: json['authorImageUrl'] as String?,
        isPostAuthor: json['postAuthor'] as bool? ?? false,
        parentCommentId: json['parentCommentId'] as int?,
        content: json['content'] as String,
        replies: (json['replies'] as List<dynamic>?)
                ?.map((e) => PostComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CreatePostRequest {
  final int categoryId;
  final String title;
  final String content;

  const CreatePostRequest({
    required this.categoryId,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'title': title,
        'content': content,
      };
}

class UpdatePostRequest {
  final int categoryId;
  final String title;
  final String content;

  const UpdatePostRequest({
    required this.categoryId,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'title': title,
        'content': content,
      };
}

/// 좋아요 토글 결과 (서버 LikeToggleResponse)
class LikeResult {
  final bool liked;
  final int likeCount;
  const LikeResult({required this.liked, required this.likeCount});
}

/// 게시글 한 페이지 (Spring Page)
class PostPage {
  final List<Post> items;
  final bool last;
  final int page;
  const PostPage({required this.items, required this.last, required this.page});
}
